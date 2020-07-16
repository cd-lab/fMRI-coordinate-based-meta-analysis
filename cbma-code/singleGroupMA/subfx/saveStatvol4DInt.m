function [] = saveStatvol4DInt(statvol,refNii,outfname)
% saves multi-volume (4-D) integer data, using a single-volume reference 
% nifti structure. 
%
% the procedure is to save each volume as a separate file and then merge
% these files. (this circumvents difficulties with save_nii)
%
% output is saved as uint8 and gzipped
%
% Inputs:
%   statvol: 3D volume of values to be saved
%   refNii: nifti structure with reference geometry
%   outfname: path for the output nifti file

% check that the input dataset contains multiple volumes
nVol = size(statvol,4);
assert(nVol>1,'4D data not supplied');

% check that the input datatype is uint8
assert(strcmp(class(statvol),'uint8'),'Data not in expected integer format');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up header

outNii = refNii;

% fix output datatype
% (set to float; see save_nii help for details)
outNii.hdr.dime.datatype = 2;
outNii.hdr.dime.bitpix = 8;

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
    
% done setting up header
%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% loop over volumes, saving one at a time
[outPath, outFile, outExt] = fileparts(outfname);
tmpBase = fullfile(outPath,sprintf('%s_tmp',outFile));
for v = 1:nVol
    tmpfname = sprintf('%s_%04d%s',tmpBase,v,outExt);
    outNii.img = statvol(:,:,:,v);
    save_nii(outNii,tmpfname);
end

% merge volumes into a 4D file
% (note: this produces gzipped output)
cmd = sprintf('fslmerge -t %s %s*',outfname,tmpBase);
runCmd(cmd);

% delete the temporary files
delete([tmpBase,'*']);







