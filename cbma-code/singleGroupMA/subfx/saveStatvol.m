function [] = saveStatvol(statvol,refNii,outfname,gz)
% saves out a statistical volume (using savenii.m)
% Inputs:
%   statvol: 3D volume of values to be saved
%   refNii: nifti structure with reference geometry
%   outfname: path for the output nifti file
%   gz: (optional logical) controls whether saved file is then gzipped

% optional argument
if nargin<4, gz = false; end

% fprintf('saving results: %s...',outfname);
outNii = refNii;
outNii.img = statvol;

% fix output datatype
% (set to float; see save_nii help for details)
outNii.hdr.dime.datatype = 16;
outNii.hdr.dime.bitpix = 32;

% settings for the sform matrix, which holds geometry information
outNii.hdr.hist.sform_code = 4; 
    % >0 so the sform matrix will be used by display programs
    % value of 4 causes it to be interpreted as MNI space
    
hdr = outNii.hdr;

%%% following 12 lines are taken from save_nii_hdr.m
%%% this segment ordinarily would not execute if hdr.hist.sform_code~=0
hdr.hist.srow_x(1) = hdr.dime.pixdim(2);
hdr.hist.srow_x(2) = 0;
hdr.hist.srow_x(3) = 0;
hdr.hist.srow_y(1) = 0;
hdr.hist.srow_y(2) = hdr.dime.pixdim(3);
hdr.hist.srow_y(3) = 0;
hdr.hist.srow_z(1) = 0;
hdr.hist.srow_z(2) = 0;
hdr.hist.srow_z(3) = hdr.dime.pixdim(4);
hdr.hist.srow_x(4) = (1-hdr.hist.originator(1))*hdr.dime.pixdim(2);
hdr.hist.srow_y(4) = (1-hdr.hist.originator(2))*hdr.dime.pixdim(3);
hdr.hist.srow_z(4) = (1-hdr.hist.originator(3))*hdr.dime.pixdim(4);
%%%

outNii.hdr = hdr;
    
save_nii(outNii,outfname);

% gzip the results if requested
if gz
    if ispc
        dos(['"C:\Program Files (x86)\GnuWin32\bin\gzip.exe" ',outfname]);
    else
        runCmd(['gzip ',outfname]);
    end
end



