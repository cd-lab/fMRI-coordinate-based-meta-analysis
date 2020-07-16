function [maxSize, clustSizeMap] = maxClustSize(statmap,thresh,maskNii,tmpDir,createSizeMap)
% for a given image and a given cluster-forming threshold, finds the 
% maximum cluster size.
%
% optionally, also returns an image where the voxels within suprathreshold
% clusters hold their cluster size values (and other voxels are zero).
%
% Inputs:
%   statmap: map of test statistic values
%   thresh: cluster-formign threshold value of the test statistic
%   maskNii: nifti structure w/ same geometry as statmap 
%   tmpDir: location for writing temporary files
%   createSizeMap: OPTIONAL logical - if true, return clustSizeMap
%
% (creation of clustSizeMap is made optional in order to avoid unnecessary
% computations during the random permutation iterations; this output is
% only needed for the unpermuted data)

% check whether clustSizeMap is being created
if nargin==4, createSizeMap = false; end
clustSizeCmd = ''; % empty by default
if createSizeMap
    clustSize_fname = fullfile(tmpDir,'clustSizeMap.nii');
    clustSizeCmd = ['--osize=',clustSize_fname]; % flag to add to cluster command
end

% save out the statmap
statmap_fname = fullfile(tmpDir,'permutedStatmap.nii');
saveStatvol(statmap,maskNii,statmap_fname);

% load_nii.m needs results saved as non-gzipped .nii
outtypeStr = 'FSLOUTPUTTYPE=NIFTI; export FSLOUTPUTTYPE;';

% save out a cluster report using the fsl program "cluster"
rpt_fname = fullfile(tmpDir,'clusReport.txt');
cmd = sprintf('%s cluster --in=%s --thresh=%1.4f --connectivity=6 %s > %s',...
    outtypeStr,statmap_fname,thresh,clustSizeCmd,rpt_fname);
runCmd(cmd);

% from the text report, read in the highest cluster size
fid = fopen(rpt_fname);
row1 = fgetl(fid); % line 1 contains column headers
row2 = fgetl(fid); % line 2 contains info about largest cluster
if ~ischar(row2) && row2==(-1) % if there are no clusters (row2 holds end-of-file indicator)
    maxSize = 0;
else % provided there is at least one cluster
    clusDetails = str2num(row2); % size is the 2nd element
    maxSize = clusDetails(2);
end
fclose(fid);

% delete the intermediate files
delete(statmap_fname);
delete(rpt_fname);

% if clustSizeMap was created, load it and then delete intermediate file
if createSizeMap
    clustSizeNii = load_nii(clustSize_fname);
    clustSizeMap = clustSizeNii.img;
    delete(clustSize_fname);
end

