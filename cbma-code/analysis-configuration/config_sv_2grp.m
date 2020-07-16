function [] = config_sv_2grp()
% configure and run a two-group coordinate-based meta-analysis contrast

%%% identify files and directories %%%

% set path to meta-analysis code
% the current working directory is assumed to be cbma-code/analysis-configuration
cbmaDir = fullfile('..','..','cbma-code');
addpath(genpath(cbmaDir));

% identify top-level output directory
outputDir = 'output_2grp';
if ~exist(outputDir,'dir'), mkdir(outputDir), end

% directory where inputs will be located (the outputs of 1-group
% meta-analyses)
inputDir = 'output_1grp';



%%% set parameters for individual contrasts %%%

% unique inputs and label for each contrast
cbma_2grp(1).input1 = 'I_POS_kda10_clusMass_200'; % single-group results dir for the first group
cbma_2grp(1).input2 = 'I_NEG_kda10_clusMass_200'; % single-group results dir for the 2nd group
cbma_2grp(1).outTag = 'POS-vs-NEG_kda10'; % label for this contrast

% other parameters (common to all contrasts)
n = length(cbma_2grp);
for i = 1:n
    cbma_2grp(i).inputDir = inputDir;
    cbma_2grp(i).outputDir = outputDir;
    cbma_2grp(i).clusterFormingPval = 0.005;
    cbma_2grp(i).nPerms = 200;  
    cbma_2grp(i).outTag = sprintf('%s_%d', cbma_2grp(i).outTag, cbma_2grp(i).nPerms);
    cbma_2grp(i).setupOnly = true; % if true, set up the randomise script but don't run it from matlab
    %#ok<*AGROW>
end

%%% run each meta-analysis
for i = 1:n
    contrastPermTest(cbma_2grp(i));
end

