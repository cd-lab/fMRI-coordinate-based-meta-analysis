function [alestat_pvals] = spatPermut(ma,alestatImg,maskImg)
% function for running a spatially randomized permutation test
% inputs:
%   - ma is a cell array. each entry holds an image of modeled activation
%   values for one study in the meta-analysis
%   - alestatImg is the collection of ale statistics (computed from the
%   modeled activation images)
%   - maskImg is a binary mask image
%
% approach:
%   alestats are probability unions of the modeled activation values
%   (a future modification might just use the mean modeled activation
%   value)
%   the question for the permutation test is what ale statistic values
%   would be expected under the null hypothesis that, within the mask,
%   there is no spatial correspondence across different studies' MA maps
%   we answer this by repeatedly computing ale values for different spatial
%   randomizations of all the MA maps.

%%% place the within-mask MA values from each study in the columns of a
%%% matrix
nStudies = length(ma);
nVoxInMask = sum(maskImg(:));
maVals = zeros(nVoxInMask,nStudies);
for s = 1:nStudies
    maVals(:,s) = ma{s}(maskImg>0);
end

%%% generate a null distribution
%%% compute ALE values over multiple iterations, randomizing each column
%%% independently
nIters = 10;
nullVals = zeros(nVoxInMask,nIters);
for i = 1:nIters
    if mod(i,5)==0 % show updates periodically
        fprintf('spatial permutation: iteration %d of %d\n',i,nIters);
    end
    randmat = rand(size(maVals));
    [m, randidx] = sort(randmat);
    for s = 1:nStudies
        maVals(:,s) = maVals(randidx(:,s),s);
    end
    nullVals(:,i) = 1 - prod(1-maVals,2);
end

%%% print information about the null distribution
fprintf('null distribution:\n');
fprintf('\t%d samples\n',numel(nullVals));
ptiles = prctile(nullVals(:),[50,95,99]);
fprintf('\t50th pct: %1.4f; 95th pct: %1.4f; 99th pct: %1.4f\n',ptiles);
nOver99 = sum(alestatImg(:)>ptiles(3));
propOver99 = nOver99/length(alestatImg(:));
fprintf('%d empirical values exceed 99th null percentile (%1.2f%%)\n',...
    nOver99,propOver99*100);

%%% create image of p values
% should be 1-tailed or 2-tailed?
% for now implementing a ONE-TAILED test
% i.e., only interested in higher-than-expected ale stats
% (also, can probably improve efficiency of this loop)
alestat_pvals = nan(size(alestatImg));
fprintf('filling in p values...');
for i = 1:size(alestatImg,1)
    fprintf('i=%d...',i);
    for j = 1:size(alestatImg,2)
        for k = 1:size(alestatImg,3)
            if maskImg(i,j,k)>0
                aleVal = alestatImg(i,j,k);
                pval = mean(nullVals(:)>=aleVal);
                alestat_pvals(i,j,k) = pval;
            end
        end
    end
end
fprintf('done\n');


keyboard


