function [] = config_sv_1grp()
% configure and run a single-group coordinate-based meta-analysis

%%% identify files and directories %%%

% set path to meta-analysis code
% the current working directory is assumed to be cbma-code/analysis-configuration
cbmaDir = fullfile('..','..','cbma-code');
addpath(genpath(cbmaDir));

% identify the location of coordinate files
coordfileDir = 'coord_files';

% identify top-level output directory
outputDir = 'output_1grp';



%%% set parameters for individual single-group meta-analyses %%%

% coord files (different for each meta-analysis)
cbma_1grp(1).coordfile = fullfile(coordfileDir,'I_POS.txt');
cbma_1grp(2).coordfile = fullfile(coordfileDir,'I_NEG.txt');

% other parameters (common to all meta-analyses)
n = length(cbma_1grp);
for i = 1:n
    cbma_1grp(i).coordFormat = 'ale';
    cbma_1grp(i).maStat = 'kda10';
    cbma_1grp(i).testStat = 'clusMass';
    cbma_1grp(i).clusterFormingPval = 0.01;
    cbma_1grp(i).nPerms = 200;
    cbma_1grp(i).randSeed = sum(100*clock);
    cbma_1grp(i).gmMap = 'grey.nii'; % this file is accessible b/c of the addpath command above
    
    % set the output filename based on the coordfile name
    [~, cName] = fileparts(cbma_1grp(i).coordfile);
    outTag = sprintf('%s_%s_%s_%d',...
        cName, cbma_1grp(i).maStat, cbma_1grp(i).testStat, cbma_1grp(i).nPerms);
    cbma_1grp(i).outTag = outTag;
    cbma_1grp(i).outDir = fullfile(outputDir,outTag); %#ok<*AGROW>
end

%%% run each meta-analysis
for i = 1:n
    singleSampPermTest(cbma_1grp(i));
end

