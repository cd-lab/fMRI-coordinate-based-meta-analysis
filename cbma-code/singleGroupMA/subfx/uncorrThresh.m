function [clusFormThresh] = uncorrThresh(studies,coordvol,quantileImg,alpha)
% estimate the statistic value corresponding to uncorrected p-val 'alpha'
% this will be used as a cluster forming threshold. 
% (e.g., p<0.01 uncorrected)
%
% null hypothesis is that values are combined across studies without regard
% to spatial correspondence (except restriction to a mask)
%
% we are using a binary MKDA modeled-activation statistic. Therefore, under
% the hypothesis of spatial randomness, we can treat each study as an
% independent bernoulli trial, with probability corresponding to the
% study's proportion of positive voxels. the sum of positive voxels across
% studies follows a poisson binomial distribution. 

mask = (quantileImg==max(quantileImg(:))); % mask with p(GM) in the top quantile
nInMask = sum(mask(:));

% determine the proportion of in-mask voxels that are positive in each
% study
nStudies = length(studies);
propPos = nan(nStudies,1);
pmf = zeros(1,(nStudies+1)); 
% elements of pmf correspond values of 0 through nStudies for the sum
pmf(1) = 1; % initialize pmf with all probability on zero

for s = 1:nStudies
    
    % compute one study's indicator map
    im = make_IM(studies(s),coordvol);
    
    % count positive voxels in the mask
    im = (im & mask);
    nPosInMask = sum(im(:));
    p = nPosInMask/nInMask;
    propPos(s) = p;
    
    % update pmf
    pmf(1:(s+1)) = (1-p)*[pmf(1:s), 0] + p*[0, pmf(1:s)];
    
end % loop over studies

cdf = cumsum(pmf);
threshIdx = find(cdf>(1-alpha),1,'first');
% element i holds the probability that the sum is i-1 or less

% now convert the sum to a percentage of studies
clusFormThresh = 100*threshIdx/nStudies;

% print description of results
fprintf('Cluster-forming threshold = %1.2f, for nominal uncorrected alpha<%1.4f\n',...
    clusFormThresh,alpha);

% % OPTIONAL: plot results
% plot(100*(0:nStudies)/nStudies,cdf,'k-','LineWidth',1.5);
% xlabel('percent of studies with activation in a voxel');
% ylabel('cumulative probability');








