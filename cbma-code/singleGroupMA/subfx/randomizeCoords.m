function [studies_rand] = randomizeCoords(studies,maskXYZ)
% for a struct of studies and associated coordinates, create a
% corresponding struct where the coordinate locations are random.
%   method 1: draw each new location randomly from within a mask
%       in this case, maskXYZ is a nVox-by-3 matrix of coordinates
%   method 2: draw each new location randomly within the corresponding
%       stratum of gray-matter probability. In this case maskXYZ is a
%       cell array with each entry holding coords for a different stratum.
%       The studies struct contains the index of the gray-matter stratum
%       for each coordinate (in field .gmStrat)


studies_rand = studies; % initialize
nStudies = length(studies);

% method 1 (original)
if ~iscell(maskXYZ)
    nVoxInMask = size(maskXYZ,1);
    for s = 1:nStudies
        studies_rand(s).coords = {}; % delete real coords from studies_rand
        nFoci = length(studies(s).coords);
        for f = 1:nFoci
            % for each focus, place a randomly chosen focus into
            % studies_rand
            studies_rand(s).coords{f,1} = maskXYZ(randi(nVoxInMask),1:3);
        end
    end
    
    % current analyses don't use this method, so there is a warning.
    fprintf('Warning: using non-stratified foci randomization!\n');
    
end


% method 2: each focus is randomly repositioned within its stratum of gray-
% matter probability. To do this:
%   maskXYZ must be a cell array, each entry containing a list of all the
%       voxel coordinates in one stratum
%   studies must have a field .gmStrat, containing the quantile number
%       associated with each coordinate location
if iscell(maskXYZ)
    assert(isfield(studies,'gmStrat'),...
        'attempted stratified randomization, but studies struct lacks field .gmStrat');
    % get the number of voxels in each stratum
    nStrat = length(maskXYZ);
    nVox = zeros(nStrat,1);
    for q = 1:nStrat
        nVox(q) = size(maskXYZ{q},1);
    end
    % loop over studies and foci
    for s = 1:nStudies
        studies_rand(s).coords = {}; % delete real coords from studies_rand
        nFoci = length(studies(s).coords);
        for f = 1:nFoci
            % which stratum?
            q = studies(s).gmStrat(f);
            % place a randomly chosen focus from stratum q into
            % studies_rand
            studies_rand(s).coords{f,1} = maskXYZ{q}(randi(nVox(q)),1:3);
        end % loop over foci
    end % loop over studies    
end

