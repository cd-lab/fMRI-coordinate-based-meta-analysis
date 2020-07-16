function [] = contrastPermTest(cbma_config)
% Tests whether two sets of activation foci have a significantly different
% spatial distribution. The null hypothesis is that the assignment of foci
% maps to the two sets is arbitrary (i.e. that labels are exchangeable).
%
% The method is to perform a conventional whole-brain, independent-samples
% permutation test with FSL's 'randomise'. The inputs are sets of per-study
% "indicator maps" produced during single-sample meta-analyses on each of
% the two sets of studies individually. 
% 
% Input:
%   cmba_config is a one-element struct array with fields:
%       .input1 (string; existing 1-sample results directory name for group1)
%       .input2 (string; same for group 2)
%       .clusterFormingPval (numeric, e.g. 0.01)
%       .nPerms (numeric, e.g. 5000)
%       .inputDir (string; top-level location of inputs)
%       .outputDir (string; top-level location for outputs)
%       .outTag (string; name of output directory to be created)
%       .setupOnly (boolean; don't run the randomise script from matlab;
%           e.g. to run it separately for better progress tracking)
%
% DEPENDENCIES: 
% 1. FSL

fprintf('started: %s\n',datestr(now));

%%% unpack the config structure %%%

inputName = {cbma_config.input1, cbma_config.input2};
clusterFormingPval = cbma_config.clusterFormingPval;
nPerms = cbma_config.nPerms;
inputDir = cbma_config.inputDir;
outTag = cbma_config.outTag;
outDir = fullfile(cbma_config.outputDir, outTag);
setupOnly = cbma_config.setupOnly;

%%% interpret parameters %%%

% set up output directory
fprintf('output dir: %s\n',outDir);
if exist(outDir,'dir')    
    input(' *** existing outputs will be overwritten (use ctrl-c to escape) ***');
    rmdir(outDir,'s');
end
mkdir(outDir);
% include a copy of the template as an underlay for viewing results
runCmd(['cp $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz ',outDir]);

% identify the full paths to input files and number of studies in each
inFile = cell(1, 2);
n = cell(1, 2);
for i = 1:2
    inFile{i} = fullfile(inputDir, inputName{i}, [inputName{i}, '_allIMs.nii.gz']);
    assert(exist(inFile{i}, 'file')>0, 'Single-group meta-analysis outputs not found: %s', inFile{i});
    [~, n{i}] = runCmd(['fslnvols ', inFile{i}]);
    n{i} = str2double(n{i});
    fprintf('input %d:\n', i);
    fprintf('  %s\n', inFile{i});
    fprintf('  n = %d studies\n', n{i});
end

% create a design matrix text file
fprintf('creating design and contrast matrices...');
designMat = [[ones(n{1},1); zeros(n{2},1)], [zeros(n{1},1); ones(n{2},1)]];
designFile = fullfile(outDir, 'design'); % no extension
dlmwrite([designFile, '.txt'], designMat, ' ');
runCmd(sprintf('Text2Vest %s.txt %s.mat', designFile, designFile));
delete([designFile, '.txt']); 

% create a contrast matrix text file
contrastMat = [1, -1; -1, 1];
contrastFile = fullfile(outDir, 'design'); % no extension
dlmwrite([contrastFile, '.txt'], contrastMat, ' ');
runCmd(sprintf('Text2Vest %s.txt %s.con', contrastFile, contrastFile));
delete([contrastFile, '.txt']); 
fprintf('done.\n');

% merge the input data files
mergedFile = fullfile(outDir, 'mergedIMs.nii.gz');
fprintf('Merging input data...')
runCmd(sprintf('fslmerge -t %s %s %s', mergedFile, inFile{1}, inFile{2}));
fprintf('done.\n'); 

% copy the anatomical underlay and mask into the output directory
fprintf('copying anatomical templates...');
maskName = fullfile(outDir, 'mask.nii.gz');
runCmd(['cp $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil1.nii.gz ', maskName]);
runCmd(['cp $FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz ', outDir]);
fprintf('done.\n'); 

% determine the cluster-forming t threshold
df = n{1} + n{2} - 2;
tThresh = tinv(1 - clusterFormingPval, df);

% save the randomise command to a script
% cmd1 runs randomise and cmd2 applies a 2-tailed threshold to the results
fprintf('Preparing randomise script...');
cmd1 = sprintf('randomise -i mergedIMs -o %s -m mask -d design.mat -t design.con -n %d -v 5 -R -x -C %1.3f -N',...
    outTag, nPerms, tThresh);
cmd2 = sprintf('fslmaths %s_clusterm_corrp_tstat1 -max %s_clusterm_corrp_tstat2 -sub 0.975 -bin -mul %s_tstat1 %s_tstat1_thresh',...
    outTag, outTag, outTag, outTag); 
cmdFile = fullfile(outDir, 'cmd.sh');
fid = fopen(cmdFile,'w');
fprintf(fid, '#!/bin/bash\n\n');
fprintf(fid, '# Run the permutation analysis\n');
fprintf(fid, '%s\n\n', cmd1);
fprintf(fid, '# Apply a 2-tailed threshold to the output\n');
fprintf(fid, '%s\n', cmd2);
fclose(fid);
fprintf('done.\n');

if setupOnly
    % print info about the script to be run but don't run it
    fprintf('\nSetup done.\n');
    fprintf('To complete the analysis, run cmd.sh in the following directory:\n');
    fprintf('%s\n\n', fullfile(pwd, outDir));
else
    % run the randomise script
    fprintf('Running randomise with %d permutations per contrast...', nPerms);
    runCmd(sprintf('cd %s ; sh cmd.sh', outDir)); 
    fprintf('done.\n'); 
end








