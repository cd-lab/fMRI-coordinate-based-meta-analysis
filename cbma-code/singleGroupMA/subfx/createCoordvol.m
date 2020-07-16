function [coordvol] = createCoordvol(maskNii)
% for a 3D mask volume, create volumes where each voxel contains its x, y,
% and z coordinate. this simplifies later distance calculations.
% Input: 
%   maskNii is a nii structure created by: maskNii = load_nii(maskfname);
% Output:
%   coordvol is a struct with .x, .y, .z each containing a 3D volume
%   holding coordinate values.

% get image dimensions
sI = size(maskNii.img,1);
sJ = size(maskNii.img,2);
sK = size(maskNii.img,3);

% we'll create volumes filled with x, y, and z coordinates
fprintf('creating coordinate volumes...');
coordvol.x = zeros(size(maskNii.img));
coordvol.y = zeros(size(maskNii.img));
coordvol.z = zeros(size(maskNii.img));
origin = maskNii.hdr.hist.originator(1:3);
scaling = maskNii.hdr.dime.pixdim(2:4);
% x coordinate
for i = 1:sI
    xcoord = (i - origin(1))*scaling(1);
    coordvol.x(i,:,:) = xcoord;
end
% y coordinate
for j = 1:sJ
    ycoord = (j - origin(2))*scaling(2);
    coordvol.y(:,j,:) = ycoord;
end
% z coordinate
for k = 1:sK
    zcoord = (k - origin(3))*scaling(3);
    coordvol.z(:,:,k) = zcoord;
end
fprintf('done.\n');


%%% note on determining coordinates
% if a nifti file (nii) is loaded into matlab using load_nii.m, the image 
% matrix (nii.img) is reoriented. The header fields nii.hdr.hist.srow* 
% hold the nifti file's ORIGINAL sform matrix, which does NOT accurately
% characterize the data stored in the .img field. 
%
% After the reorientation step, the image is characterized by a
% positive-diagonal sform matrix. Go from (1-based) index to millimeters as
% follows: (index - origin) * scaling
% Origin on each dimension is stored in nii.hdr.hist.originator(1:3)
% Scaling on each dimension is stored in nii.hdr.dime.pixdim(2:4)
% for more info: http://www.rotman-baycrest.on.ca/~jimmy/NIfTI/FAQ.htm



