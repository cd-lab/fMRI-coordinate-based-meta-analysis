function [im] = make_IM(study,coordvol)
% Create the indicator map for a single study (sometimes also called the
% 'modeled activation map').
%
% Each voxel's value depends on its distance from the nearest activation
% focus. Another way of saying this is that each voxel holds the maximum
% statistic value that would be associated with any individual focus. 
%
% Outputs:
%   im: the study's modeled activation map
% Inputs:
%   study is a struct containing data about just one study. Fields:
%       coords: cell array w/ each entry containing an xyz coordinate
%       statCube: 3D matrix with stat values that surround each focus
%           (study-specific in case one wants to use something like a more
%           diffuse kernel for smaller-n studies.)
%   coordvol is a struct with the following fields:
%       .x, .y, .z each holds a volume with each voxel's spatial coord
%       .cubeRad: radius of the statCube
%       .cubeAx.x, .cubeAx.y, .cubeAx.z hold axis values for voxels in the
%       statCube relative to its center. 
%           
% NOTE: for efficiency, coordinate foci are reset to the nearest voxel 
%   center (a shift of at most 1mm if using either 2mm or 3mm output grid)
%   and a cached cube of voxel values is centered on that location.


% initialize as zero
volDims = size(coordvol.x);
im = zeros(volDims);
nFoci = length(study.coords);
cubeRad = coordvol.cubeRad;

% get the axis grid on each dimension
ax.x = squeeze(coordvol.x(:,1,1));
ax.y = squeeze(coordvol.y(1,:,1));
ax.z = squeeze(coordvol.z(1,1,:));

% loop through foci
for f = 1:nFoci
    
    % set the current focus to the nearest voxel center
    [xMin, xIdx] = min(abs(ax.x - study.coords{f}(1)));
    [yMin, yIdx] = min(abs(ax.y - study.coords{f}(2)));
    [zMin, zIdx] = min(abs(ax.z - study.coords{f}(3)));
    focus = [ax.x(xIdx), ax.y(yIdx), ax.z(zIdx)];
    
    % define cube around the focus
    % (these 3 lines also appear in createStatCube.m)
    cubeX = ax.x>=(focus(1)-cubeRad) & ax.x<=(focus(1)+cubeRad);
    cubeY = ax.y>=(focus(2)-cubeRad) & ax.y<=(focus(2)+cubeRad);
    cubeZ = ax.z>=(focus(3)-cubeRad) & ax.z<=(focus(3)+cubeRad);
    
    % For foci near the edge of the volume, the cube will not be its full 
    % size. Determine which elements to take from the cached cube. 
    cacheX = (coordvol.cubeAx.x+focus(1))>=min(ax.x) & (coordvol.cubeAx.x+focus(1))<=max(ax.x);
    cacheY = (coordvol.cubeAx.y+focus(2))>=min(ax.y) & (coordvol.cubeAx.y+focus(2))<=max(ax.y);
    cacheZ = (coordvol.cubeAx.z+focus(3))>=min(ax.z) & (coordvol.cubeAx.z+focus(3))<=max(ax.z);
    
    % place the stat cube into im
    % im will hold the *greater* of either its current value or the value
    % in maCube
    im(cubeX,cubeY,cubeZ) = max(im(cubeX,cubeY,cubeZ),study.statCube(cacheX,cacheY,cacheZ));
    
end % loop over foci







