# fMRI-coordinate-based-meta-analysis
code from Bartra, McGuire, & Kable, 2013, NeuroImage, http://doi.org/10.1016/j.neuroimage.2013.02.063

Caveat emptor. Use caution and carefully check results and intermediate outputs, especially if
using settings that differ from the original paper. 

Tested in MATLAB 2017a. Dependencies:
1. NIFTI tools by Jimmy Shen (for loading and saving), a copy of which is included the repo. For information see: http://www.mathworks.com/matlabcentral/fileexchange/8797
2. FSL installed on the system. FSL paths are assumed to be set up in .bash_profile or .bashrc.

Instructions for a 1-group meta-analysis (to test if foci have a non-random spatial distribution)
1. Set MATLAB's working directory to: cbma-code/analysis-configuration 
2. Edit and run the file config_sv_1grp.m

Instructions for a 2-group meta-analysis contrast (to test if two sets of foci differ)
1. First run a 1-group meta-analysis for each of the groups
2. Set MATLAB's working directory to: cbma-code/analysis-configuration 
3. Edit and run the file config_sv_2grp.m

Example configuration and coordinate files are included for testing, which reproduce maps in Fig. 3A-B (the 1-group file), and Fig. 3D (the 2-group file). 


