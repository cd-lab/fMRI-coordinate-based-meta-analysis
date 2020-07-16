function [maxVox, statmap] = maxVoxel(statmap,varargin)
% For the input image 'statmap', return the maximum voxel value.
%
% This function is set up to be interchangeable with 'maxClustMass' and
% 'maxClustSize'. Those functions return cluster-based test statistics.
% This function just uses simple voxel value as the test statistic, but
% allows for extra unused arguments that would be passed to the clustering
% functions. 

maxVox = max(statmap(:));

