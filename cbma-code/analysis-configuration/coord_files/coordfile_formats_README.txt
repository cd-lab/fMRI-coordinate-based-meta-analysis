Information about the format for coordinate files.
Two formats are possible: 'ale' and 'csv'. The 'ale' format corresponds 
to the files used as input to the GingerALE meta-analysis package. 

In either case, all coordinates in given file are used in a single 
meta-analysis. Different categories (e.g., different types of contrasts
or different directions of effects) should be sorted into different 
coordinate files beforehand. Likewise, for whole-brain meta-analyses, 
foci from non-whole-brain analyses should be filtered out ahead of time.

Details of 'ale' format:
-> Matches the example given here: 
    http://www.brainmap.org/ale/foci2.txt
-> First line is "Reference=MNI" or "Reference=Talairach"
-> There is one entry per paper.
-> Each entry begins with meta-info about the study, prefixed with "// "
-> The last line of meta-info has sample size, e.g. "// Subjects=17"
-> Each subsequent line in the entry holds 3 numbers, the x/y/z coords 
    for one focus point.

Details of 'csv' format:
-> First row has column headers; each subsequent row holds one focus point
    (and only numeric data). 
-> 6 columns, as follows:
	col1 = paper index (not necessarily sequential)
        so foci from the same paper can be grouped together
	col2 = stereotactic space: 1=MNI, 2=Talairach
        coords in talairach space are automatically converted
	col3 = number of subjects
	col4 = x coordinate value
	col5 = y coordinate value
	col6 = z coordinate value
-> Note: 'csv' format (but not 'ale' format) accommodates different
    stereotactic spaces (MNI/Talairach) for different studies. 

