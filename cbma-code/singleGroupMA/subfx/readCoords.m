function [studies] = readCoords(coordfile)
% read an ALE-formatted file listing coordinates of activation peaks
%
% Input:
%   coordfile is the path to the input text file


studies = struct([]);
fid = fopen(coordfile);
fdata = textscan(fid,'%s','Delimiter','\n\r','MultipleDelimsAsOne',1);
% fdata{1} is a cell array with an entry for each line in the text file
refSpace = ''; % will be set to either 'Talairach' or 'MNI'
studyNum = 0;
coordNum = 0;
readingCoords = false;
nLines = length(fdata{1});

% loop over lines of the file
for fl = 1:nLines
    
    % first line of the file should indicate the reference space
    % e.g. "// Reference=MNI"
    if ~readingCoords && ~isempty(strfind(fdata{1}{fl},'Reference='))
        strBegin = strfind(fdata{1}{fl},'Reference=');
        rs = fdata{1}{fl}(strBegin+10:end);
        if ~isempty(refSpace) && ~strcmp(rs,refSpace)
            error('Conflicting reference spaces found in coordfile %s',coordfile);
        end
        refSpace = rs;
    end
    
    % each new study begins with the number of subjects
    % (and coords start on the next line)
    if ~readingCoords && ~isempty(strfind(fdata{1}{fl},'Subjects='))
        studyNum = studyNum+1;
        coordNum = 0;
        strBegin = strfind(fdata{1}{fl},'Subjects=');
        % the number itself begins 9 characters in
        studies(studyNum).nSubjects = str2double(fdata{1}{fl}(strBegin+9:end));
        readingCoords = true;
        
    elseif readingCoords
        if isempty(strtrim(fdata{1}{fl})) || strcmp(fdata{1}{fl}(1:2),'//')
            % blank line (or double slash) marks the end of a study
            % (strtrim lets lines w/ only whitespace count as blank)
            readingCoords = false;
        else
            % this cell contains coordinates
            coordNum = coordNum+1;
            cVals = str2num(fdata{1}{fl}); %#ok<ST2NM>
            % if coords are in talairach space, convert to MNI
            % using a function downloaded from www.brainmap.org/icbm2tal
            % (note: brainmap provides different transformations for
            % different software packages, but these distinctions are not
            % implemented here -- we use one transform and assume all
            % "versions" of MNI are comparable for practical purposes)
            if strcmp(refSpace,'Talairach')
                cVals = tal2icbm_spm(cVals);
            else
                % if refSpace is not Talairach, it should be MNI
                % in this case, coords are unchanged
                assert(strcmp(refSpace,'MNI'),...
                    'Reference space not specified as Talairach or MNI in coordfile %s',...
                    coordfile);
            end
            studies(studyNum).coords{coordNum,1} = cVals;
        end
    end
    
end
fclose(fid);


