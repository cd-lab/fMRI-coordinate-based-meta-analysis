function [] = writeCoords(studies,outfname)
% rewrites coordinates to a text file
% useful for explicitly logging the coords used in a CBMA and for checking
% conversion from Talairach to MNI if any.

fid = fopen(outfname,'w');

% coords are always in MNI space (converted if necessary on input)
fprintf(fid,'// Reference=MNI\n');

% loop over studies
nStudies = length(studies);
for s = 1:nStudies
    
    fprintf(fid,'// Study %d\n',s);
    fprintf(fid,'// Subjects=%d\n',studies(s).nSubjects);
    
    % loop over foci
    nFoci = length(studies(s).coords);
    for f = 1:nFoci
        
        focus = studies(s).coords{f};
        fprintf(fid,'%1.2f\t%1.2f\t%1.2f\n',focus);
        
    end % loop over foci
    
    % blank line between studies
    fprintf(fid,'\n');

end % loop over studies

fclose(fid);




