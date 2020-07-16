function [maxMass, clustMassMap] = maxClustMass(statmap,thresh,maskNii,tmpDir,createMassMap)
% for a given image and a given cluster-forming threshold, finds the 
% maximum cluster *mass*.
%
% optionally, also returns an image where the voxels within suprathreshold
% clusters hold their cluster mass values (and other voxels are zero).
%
% this is a drop-in substitute for maxClustSize.m, which is a very similar
% function evaluating cluster *extent*. 
% 
% Inputs:
%   statmap: map of test statistic values
%   thresh: cluster-forming threshold value of the test statistic
%   maskNii: nifti structure w/ same geometry as statmap 
%   tmpDir: location for writing temporary files
%   createSizeMap: OPTIONAL logical - if true, return clustMassMap
%
% (creation of clustMassMap is made optional in order to avoid unnecessary
% computations during the random permutation iterations; this output is
% only needed for the unpermuted data)
%
% approach: use fsl's "cluster" to save maps of cluster mean and cluster
% size, then multiply these to obtain a map of cluster mass, then extract 
% the max. 
%
% this function's output matches the cluster mass results produced by
% "randomise" up to rounding. 



% check whether clustMassMap is being created
if nargin==4, createMassMap = false; end

% save out the statmap
statmap_fname = fullfile(tmpDir,'permutedStatmap.nii');
saveStatvol(statmap,maskNii,statmap_fname);

% names of files to be created
outExtent_fname = fullfile(tmpDir,'clusExtent.nii');
outMean_fname = fullfile(tmpDir,'clusMean.nii');
outMass_fname = fullfile(tmpDir,'clusMass.nii');
outMassRange_fname = fullfile(tmpDir,'clusMassRange.txt');

% load_nii.m needs results saved as non-gzipped .nii
outtypeStr = 'FSLOUTPUTTYPE=NIFTI; export FSLOUTPUTTYPE;';

% use fsl program "cluster"
% no need to save out the text report (has no info about mass)
% do save images with each cluster's extent and mean value
%   (subsequently use these to compute cluster mass)
% note: omitting the --connectivity flag (which was used in maxClustSize.m)
%   so that results exactly match the cluster mass output of randomise. 
cmd = sprintf('%s cluster --in=%s --thresh=%1.4f --no_table --osize=%s --omean=%s',...
    outtypeStr,statmap_fname,thresh,outExtent_fname,outMean_fname);
runCmd(cmd);

% multiply mean and extent to obtain mass
% note: using mean as 1st arg and extent as 2nd arg (rather than v.v.)
%   causes results to be saved in float format, not int. 
cmd = sprintf('%s fslmaths %s -mul %s %s',...
    outtypeStr,outMean_fname,outExtent_fname,outMass_fname);
runCmd(cmd);

% get the max cluster mass
% note: both outputs are rounded off to 2 decimal places. this is necessary
% because the values obtained from fslstats and from load_nii have
% different precision, which interferes with comparisons between obtained
% values and the null distribution. 
cmd = sprintf('fslstats %s -R > %s',outMass_fname,outMassRange_fname);
runCmd(cmd);
rangeVals = load(outMassRange_fname);
maxMass = rangeVals(2);
maxMass = round(maxMass*100)/100; % round to 2 decimal places

% if clustMassMap is needed, load it
if createMassMap
    clustMassNii = load_nii(outMass_fname);
    clustMassMap = double(clustMassNii.img);
    clustMassMap = round(clustMassMap*100)./100; % round to 2 decimal places
end

% delete intermediate files
delete(statmap_fname);
delete(outExtent_fname);
delete(outMean_fname);
delete(outMass_fname);
delete(outMassRange_fname);





