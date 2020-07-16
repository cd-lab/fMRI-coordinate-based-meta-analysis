function [maskXYZ, studies, quantileImg] = gmStrata(studies,gmNii,coordvol)
% performs setup for gm-stratified spatial randomization
% Inputs:
%   studies is a struct with an entry for each study and coords in 
%       field .coords
%   gmNii is a nifti struct with the gray-matter probability map
%   coordvol is a struct with each voxel's x, y, and z coords
%
% Steps:
%   1. taking those voxels with p(gm)>0, divide them into similar-sized
%       quantiles
%   2. add the field .gmStrat to the studies structure, holding the gm
%       quantile index for each coordinate point
%   3. create the cell array maskXYZ, with each entry holding all the voxel
%       coordinates in a given stratum
%

% get the axis grid on each dimension
ax.x = squeeze(coordvol.x(:,1,1));
ax.y = squeeze(coordvol.y(1,:,1));
ax.z = squeeze(coordvol.z(1,1,:));

% determine the quantile boundaries
nQuants = 5;
quantPerc = (100/nQuants):(100/nQuants):100; % percentile points to set quantiles
gmVox = gmNii.img(:);
gmVox_nonzero = gmVox(gmVox>0);
% values in gmQuants are quantile upper boundaries
gmQuants = [0, prctile(gmVox_nonzero,quantPerc)]; % five nonzero quantiles

% create an image of quantile indices
quantileImg = zeros(size(gmNii.img));
for q = 1:nQuants
    quantileImg(gmNii.img > gmQuants(q)) = q;
end

% the quantile image is returned as an output and
% saved in the output directory for the current analysis

% record the quantile index for each coord point in studies
nStudies = length(studies);
for s = 1:nStudies
    
    nFoci = length(studies(s).coords);
    for f = 1:nFoci

        % set the current focus to the nearest voxel center
        [xMin, xIdx] = min(abs(ax.x - studies(s).coords{f}(1)));
        [yMin, yIdx] = min(abs(ax.y - studies(s).coords{f}(2)));
        [zMin, zIdx] = min(abs(ax.z - studies(s).coords{f}(3)));

        quantVal = quantileImg(xIdx,yIdx,zIdx);
        studies(s).gmStrat(f,1) = quantVal;

    end % loop over foci for one study
    
    % after completing the study, remove foci for which pGM==0
    gmZero = studies(s).gmStrat==0;
    if any(gmZero)
        fprintf('  removing %d foci with p(GM)=0 in study %d\n',...
            sum(gmZero),s);
        studies(s).coords(gmZero) = [];
        studies(s).gmStrat(gmZero) = [];
    end
    
end % loop over studies

% create arrays of voxel coordinates in maskXYZ
maskXYZ = cell(nQuants,1);
for q = 1:nQuants
    % store all the x/y/z coordinates for this quantile
    maskXYZ{q} = [coordvol.x(quantileImg==q), coordvol.y(quantileImg==q), coordvol.z(quantileImg==q)];
end





