function [] = singleSampPermTest(cbma_config)
% For a single sample of studies, tests whether foci are significantly 
% clustered. The null hypothesis is that foci are distributed randomly. 
% Performs a permutation test to control familywise error rate.
% 
% Input:
%   cmba_config is a one-element struct array with fields:
%       .coordfile (string)
%       .coordFormat (string: 'ale' or 'csv')
%       .maStat (string, e.g. 'kda10' or 'ale' - see createStatCube.m for other options)
%       .testStat (string: 'clusMass', 'clusExtent', or 'voxel')
%       .clusterFormingPval (numeric, e.g. 0.01)
%       .nPerms (numeric, e.g. 5000)
%       .randSeed (numeric)
%       .gmMap (string, e.g. 'grey.nii')
%       .outTag = (string)
%       .outDir = (string)
%
% General approach to permutation testing is similar to that in MKDA (Wager
% et al. 2007) and ALE (Eickhoff et al. 2012). We generate random data in
% which the same number of foci are distributed randomly. Random images 
% are generated using gray-matter stratification. 
%
% DEPENDENCIES
% 1. nifti tools by Jimmy Shen (for loading and saving), see:
%   http://www.mathworks.com/matlabcentral/fileexchange/8797
% 2. FSL

fprintf('started: %s\n',datestr(now));

%%% unpack the config structure %%%

coordfile = cbma_config.coordfile;
coordFormat = cbma_config.coordFormat;
maStat = cbma_config.maStat;
testStat = cbma_config.testStat;
clusterFormingPval = cbma_config.clusterFormingPval;
nPerms = cbma_config.nPerms - 1; % unpermutated data comprise one iteration
randSeed = cbma_config.randSeed;
gmMap = cbma_config.gmMap;
outTag = cbma_config.outTag;
outDir = cbma_config.outDir;

%%% interpret parameters %%%

% clustering is only implemented for KDA-like (binary) values of maStat
if ~contains(maStat,'kda') && ~strcmp(testStat,'voxel')
    input(sprintf(' *** changing testStat to ''voxel'' because maStat is ''%s'' (press ENTER) ***', maStat))
    testStat = 'voxel';
    % reset the output filename
    [~, cName] = fileparts(coordfile);
    outTag = sprintf('%s_%s_%s_%d', cName, maStat, testStat, cbma_config.nPerms);
    pathStr = fileparts(outDir);
    outDir = fullfile(pathStr, outTag);
end

% size of the cube of values to be updated for each focus
% (should be larger than the radius w/in which values actually change)
switch maStat
    case 'kda10', cubeRad = 15;
    otherwise, cubeRad = 30; % update a larger cube if using an ale-like gaussian 
end

% grey-matter-probability template, which functions as a mask
maskfname = gmMap;

% cluster metric
switch testStat
    case 'clusExtent', testStatFx = @maxClustSize;
    case 'clusMass', testStatFx = @maxClustMass;
    case 'voxel', testStatFx = @maxVoxel;
    otherwise, error('unrecognized cluster metric');
end

% print the name of the coordinate file
fprintf('coordinate file: %s\n',coordfile);

% set up output directory
nulldist_fname = fullfile(outDir,sprintf('%s_nullDist.mat',outTag)); % permutation results
prevPerms = []; % may load permutation results from a previous run
tmpDir = fullfile(outDir,'tmpfiles');
fprintf('output dir: %s\n',outDir);
if exist(outDir,'dir')
    
    % if permutation results already exist, reuse them
    if exist(nulldist_fname,'file')
        d = load(nulldist_fname);
        prevPerms = d.nullMax;
        prevPerms = prevPerms(~isnan(prevPerms));
        input(sprintf(' *** loading %d values from a previous permutation run (press ENTER) ***',...
            length(prevPerms)));
    end
    
    input(' *** existing outputs will be overwritten (use ctrl-c to escape) ***');
    rmdir(outDir,'s');
    
end
mkdir(outDir);
mkdir(tmpDir);
% include a copy of the template as an underlay for viewing results
runCmd(['cp $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz ',outDir]);


%%% load files %%%

% different subfunctions to load the 2 possible coordfile formats
switch coordFormat
    case 'ale', studies = readCoords(coordfile);
    case 'csv', studies = readCoords_csv(coordfile);
end
nStudies = length(studies);
fprintf('input contains %d studies.\n',nStudies);

% load the nifti mask
% modeled activation maps will conform to the geometry of the mask
% final results will be restricted to regions with mask values >0
fprintf('Mask file: %s\n',maskfname);
fprintf('loading mask...');
maskNii = load_nii(maskfname);
fprintf('done.\n');
% the nii structure is composed as follows:
%   hdr -		struct with NIFTI header fields.
%  	filetype -	Analyze format .hdr/.img (0); 
%  			NIFTI .hdr/.img (1);
%  			NIFTI .nii (2)
%  	fileprefix - 	NIFTI filename without extension.
%  	machine - 	machine string variable.
%  	img - 		3D (or 4D) matrix of NIFTI data.
%  	original -	the original header before any affine transform.

% create volumes holding each voxel's x, y, and z coordinates
% (stored in coordvol.x, .y, and .z)
coordvol = createCoordvol(maskNii);
coordvol.cubeRad = cubeRad; % store cubeRad here so it's passed to subfunctions

% create a cube of MA stat values for each study
% this will be saved in studies.statCube
% each study's modeled activation (MA) map will be created by centering
% this cube of values at every coordinate focus
[studies, coordvol] = createStatCube(studies,coordvol,maStat);

% identify quantiles for gray-matter stratified spatial randomization
[maskXYZ, studies, quantileImg] = gmStrata(studies,maskNii,coordvol);


%%% Perform random permutations %%%

% set random seed
RandStream.setGlobalStream(RandStream('mt19937ar','Seed',randSeed));         

% preliminary step:  find the uncorrected cluster-forming threshold
if strcmp(testStat,'voxel')
    clusFormThresh = NaN; % if not clustering, use a placeholder value
else
    fprintf('calculating cluster-forming threshold...\n');
    clusFormThresh = uncorrThresh(studies,coordvol,quantileImg,clusterFormingPval);
end

% permutations
fprintf('permuting to establish a null distribution for the image-wise max test statistic.\n');
fprintf('running %d random iterations: ',nPerms);
nullMax = nan(nPerms,1);
% reuse up to nPerms-1 previously computed permutations
% (always compute at least one)
nPrevPerms = min(length(prevPerms),nPerms-1);
nullMax(1:nPrevPerms) = prevPerms(1:nPrevPerms);
save(nulldist_fname,'nullMax'); % to ensure that previously computed permutations (if any) are not lost

for iter = (nPrevPerms+1):nPerms
    
    % print progress
    if mod(iter,200)==1, fprintf('\n  '); end
    if mod(iter,10)==1, fprintf('%d ',iter); end
    
    % generate randomized coordinates for each input study. 
    studies_rand = randomizeCoords(studies,maskXYZ);
    
    % using the random coordinate list, generate a map of meta-analysis 
    % statistic values. (this is encapsulated so that the same routine is 
    % used for the real coordinates, below)
    maStatMap_null = calc_maStat(studies_rand,coordvol,maskNii);   
    
    % obtain the maximum cluster size (in number of voxels)
    maxTestStat = testStatFx(maStatMap_null,clusFormThresh,maskNii,tmpDir);
    
    % add a value to the null distribution
    nullMax(iter) = maxTestStat;
    
    % save null distribution occasionally (every 100th iteration)
    % full null distribution is also saved below
    if mod(iter,100)==0
        save(nulldist_fname,'nullMax');
    end
    
end % loop over permutation iterations
fprintf('\npermutations complete.\n');

% test stats for real data
fprintf('calculating non-permuted meta-analysis statistic values...\n');
[maStatMap, allIMs] = calc_maStat(studies,coordvol,maskNii);

% clusterize the real data
[maxTestStat, testStatMap] = testStatFx(maStatMap,clusFormThresh,maskNii,tmpDir,true);

% add the real maximum cluster size as final entry in null distribution
nullMax = [nullMax; maxTestStat]; 

% save out the null distribution
save(nulldist_fname,'nullMax');

% convert to p values
% p is the proportion of 'nullMax' values that are >= the observed value
% results will be saved out in 1 - p format
%   (i.e., prop of nullMax values that are < the observed value)
fprintf('calculating p values...\n');
pVol = arrayfun(@(x) mean(nullMax<x),testStatMap);

% save a bunch of images:
fprintf('saving results...\n');
% image of gray matter quantiles
outfname = fullfile(outDir,sprintf('%s_gmQuantiles.nii',outTag));
saveStatvol(quantileImg,maskNii,outfname,true);
% example of the null MA statmap (last random permutation computed)
outfname = fullfile(outDir,sprintf('%s_exampRandStatmap.nii',outTag));
saveStatvol(maStatMap_null,maskNii,outfname,true);
% random seed value
randseed_fname = fullfile(outDir,sprintf('%s_randSeed.mat',outTag));
save(randseed_fname,'randSeed');
% real (unpermuted) MA statistic values
maStatvol_fname = fullfile(outDir,sprintf('%s_maStat.nii',outTag));
saveStatvol(maStatMap,maskNii,maStatvol_fname,true);
% real test statistic (e.g., cluster mass values)
testStatVol_fname = fullfile(outDir,sprintf('%s_testStat.nii',outTag));
saveStatvol(testStatMap,maskNii,testStatVol_fname,true);
% p-value map (formatted as 1-p)
pvol_fname = fullfile(outDir,sprintf('%s_corrp.nii',outTag));
saveStatvol(pVol,maskNii,pvol_fname,true);
% thresholded MA statistic values (using fslmaths on saved files)
% retain the MA stat where FWE corrected p < 0.05 (i.e., 1-p > 0.95)
% this is a one-tailed test, appropriate for clustering density
% these thresholded images will be the basis for figures
threshVol_fname = fullfile(outDir,sprintf('%s_maStat_thresh.nii',outTag));
cmd = sprintf('/usr/local/fsl/bin/fslmaths %s -sub 0.95 -bin -mul %s %s',...
    pvol_fname,maStatvol_fname,threshVol_fname);
runCmd(cmd);
% full set of invidual-study indicator maps
allIMs_vol_fname = fullfile(outDir,sprintf('%s_allIMs.nii',outTag));
saveStatvol4DInt(allIMs,maskNii,allIMs_vol_fname);
% write out the coordinate list
coords_rewritten = fullfile(outDir,sprintf('%s_coords.txt',outTag));
writeCoords(studies,coords_rewritten);

% log parameter settings
logfname = fullfile(outDir,sprintf('%s_log.txt',outTag));
fid = fopen(logfname,'w');
fprintf(fid,'Results directory created using %s\n',mfilename);
fprintf(fid,'%s\n\n',datestr(now));
fprintf(fid,'Parameters:\n');
fprintf(fid,'Coordinate data file: %s\n',coordfile);
fprintf(fid,'Number of studies: %d\n',nStudies);
fprintf(fid,'Meta-analytic statistic (maStat): %s\n',maStat);
if ~strcmp(testStat,'voxel')
    fprintf(fid,'Cluster-forming uncorrected p-value: %1.4f\n',clusterFormingPval);
    fprintf(fid,'Corresponding cluster-forming maStat value: %1.2f\n',clusFormThresh);
end
fprintf(fid,'Test statistic: %s\n',testStat);
fprintf(fid,'Number of random permutations: %d\n',nPerms);
fprintf(fid,'Critical test statistic value (corrected p<0.05): %1.2f\n',prctile(nullMax,95));

fclose(fid);

fprintf('finished: %s\n\n',datestr(now));











