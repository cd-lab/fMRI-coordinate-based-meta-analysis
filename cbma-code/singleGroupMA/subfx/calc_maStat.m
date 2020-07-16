function [maStat,allIMs] = calc_maStat(studies,coordvol,maskNii)
% meta-analytic statistic is generated as follows (for either real or 
% randomized data):
%   1. An indicator map (IM) is created for each study.
%   2. IMs are averaged across subjects.

nStudies = length(studies);

% initialize a volume for the running sum
imSum = zeros(size(maskNii.img));

% initialize 4D volume of all single-study indicator maps
allIMs = zeros([size(maskNii.img), nStudies],'uint8');

% loop through studies, creating a modeled activation map for each
for s = 1:nStudies
    
    % compute one study's indicator map
    im = make_IM(studies(s),coordvol);
    
    % place in the 4D volume
    allIMs(:,:,:,s) = im;
    
    % update a running sum
    imSum = imSum + im;
        
end

% convert the sum to the average
maStat = imSum./nStudies;








