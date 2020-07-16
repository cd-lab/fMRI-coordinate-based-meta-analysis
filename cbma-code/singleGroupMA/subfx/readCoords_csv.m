function [studies] = readCoords_csv(coordfile,printOutput)
% loads coordinate foci stored in a numerical csv file
%   -converts tlrc coordinates to MNI
%   -assumes that ALL coords in the csv file are intended to be used
%       together in a given meta-analysis (i.e., all represent comparable
%       effects in the same direction, and are from whole-brain analyses).
%
% Input:
%   coordfile is a string containing the path to a csv file
%   file format:
%       first row is headers; later rows are data
%       one row per focus, 6 cols
%       col1 = publication index (not necessarily sequential)
%           so foci from the same paper can be grouped together
%       col2 = stereotactic space: 1=MNI, 2=Talairach
%           coords in talairach space need to be converted
%       col3 = number of subjects
%       col4 = x coordinate value
%       col5 = y coordinate value
%       col6 = z coordinate value
%
%   printOutput (optional): logical. if true, display results onscreen.


% defaults
if nargin<2, printOutput = false; end % default is not to print output

% load the csv file
% note: csvread requires all numeric data. 
% 1st row is (headers) is skipped
csvData = csvread(coordfile,1,0);

% loop through papers
studyIdxVals = unique(csvData(:,1));
nStudies = length(studyIdxVals);
studies = struct([]);

for s = 1:nStudies
    
    % index all foci corresponding to this paper
    sIdx = (csvData(:,1) == studyIdxVals(s));
    
    % pull this paper's foci
    studyFoci = csvData(sIdx,4:6);
    nFoci = size(studyFoci,1);
    
    % determine whether this study uses MNI or Talairach space
    % coded as 1=MNI, 2=Talairach
    spaceID = unique(csvData(sIdx,2));
    % check that all coords for one study use the same space
    assert(numel(spaceID)==1,'multiple spaces for study %d',studyIdxVals(s));
    
    % talairach-space foci are converted using the Lancaster transform
    %   we use tal2icbm_spm.m
    %   it was downloaded from: http://www.brainmap.org/icbm2tal/
    % note: slightly different transforms are provided for "spm," "fsl,"
    % and "other." we just use spm (the differences are not expected to
    % impact accuracy substantially). 
    if spaceID==2
        % tal2icbm complains about 3x3 matrices. add/remove a dummy.
        if nFoci==3, studyFoci = [studyFoci; [0,0,0]]; end %#ok<AGROW>
        studyFoci = tal2icbm_spm(studyFoci);
        if nFoci==3, studyFoci(end,:) = []; end
    end
    
    % place this study's foci into the coords array
    % each coordinate triple is in its own sub-cell
    studies(s).coords = mat2cell(studyFoci,ones(nFoci,1),3);
    
    % get the number of subjects in the study
    nSubs = unique(csvData(sIdx,3));
    assert(numel(nSubs)==1,'multiple sample size values for study %d',studyIdxVals(s));
    studies(s).nSubjects = nSubs;
    
    if printOutput
        fprintf('\nStudy %d (index = %d), n = %d, %d foci:\n',...
            s,studyIdxVals(s),nSubs,nFoci);
        fprintf('\t%+d\t%+d\t%+d\n',studies(s).coords);
    end
        
end





