function [studies, coordvol] = createStatCube(studies,coordvol,maStat)
% for each element of studies, create a cube of modeled-activation values
% and cache it in studies(n).statCube
% 
% Geometry of the stat cube depends on coordvol and cubeRad.
% The statistic values themselves are controlled by maStat (a string, e.g.
% 'ale'). For some statistic types (including ale) values depend on the 
% number of subjects in each study (studies(n).nSubjects). 

% get the axis grid on each dimension
ax.x = squeeze(coordvol.x(:,1,1));
ax.y = squeeze(coordvol.y(1,:,1));
ax.z = squeeze(coordvol.z(1,1,:));

% cube radius is already stored in coordvol
cubeRad = coordvol.cubeRad;

% use a focus at the origin
focus = [0, 0, 0];

% define cube around the focus
cubeX = ax.x>=(focus(1)-cubeRad) & ax.x<=(focus(1)+cubeRad);
cubeY = ax.y>=(focus(2)-cubeRad) & ax.y<=(focus(2)+cubeRad);
cubeZ = ax.z>=(focus(3)-cubeRad) & ax.z<=(focus(3)+cubeRad);

% store axis indices for the cube in coordvol
coordvol.cubeAx.x = ax.x(cubeX);
coordvol.cubeAx.y = ax.y(cubeY);
coordvol.cubeAx.z = ax.z(cubeZ);

% for this cube only, get the euclidean distance
dst.x = coordvol.x(cubeX,cubeY,cubeZ) - focus(1); % distance in x direction
dst.y = coordvol.y(cubeX,cubeY,cubeZ) - focus(2); % distance in y direction
dst.z = coordvol.z(cubeX,cubeY,cubeZ) - focus(3); % distance in z direction
dst.euc = sqrt(dst.x.^2 + dst.y.^2 + dst.z.^2); % euclidean distance
    
% set kernal values as a function of distance
% for some MA stats, this is different for each study
for s = 1:length(studies)

    % convert distance to some function of distance
    switch maStat

        case 'rawDist'
            
            % MA map simply contains each voxel's distance in mm from the
            % nearest activation focus (for testing only)
            studies(s).statCube = dst.euc;

        case 'ale'
            
            % determine the gaussian width (in case maFx is 'ale')
            % this is GingerALE's formula for gaussian width
            nSubs = studies(s).nSubjects;
            fwhm = sqrt(log(2) * pi * (5.7^2 + (11.6^2 / nSubs)));             
            sigma = fwhm/(2*sqrt(2*log(2)));
            studies(s).aleSigma = sigma;
            
            % function given in Turkeltaub 2002 (matches GingerALE output)
            studies(s).statCube = 8 * exp(-(dst.euc.^2)./(2*sigma^2))./(((2*pi)^1.5)*sigma^3);
            
            % scale up values by a factor of
            % 1000 (more convenient for image viewers)
            studies(s).statCube = 1000*studies(s).statCube;
            
        case 'aleFix15'
            
            sigma = 15;
            studies(s).statCube = 8 * exp(-(dst.euc.^2)./(2*sigma^2))./(((2*pi)^1.5)*sigma^3);
            studies(s).statCube = 1000*studies(s).statCube;
            
        case 'aleFix10'
            
            sigma = 10;
            studies(s).statCube = 8 * exp(-(dst.euc.^2)./(2*sigma^2))./(((2*pi)^1.5)*sigma^3);
            studies(s).statCube = 1000*studies(s).statCube;
            
        case 'aleFix6'
            
            sigma = 6;
            studies(s).statCube = 8 * exp(-(dst.euc.^2)./(2*sigma^2))./(((2*pi)^1.5)*sigma^3);
            studies(s).statCube = 1000*studies(s).statCube;
            
        case 'kda10' % kda values are multiplied by 100 so final stat is a percent
            
            rad = 10;
            studies(s).statCube = 100*(dst.euc<=rad);
            
        case 'kda15'
            
            rad = 15;
            studies(s).statCube = 100*(dst.euc<=rad);
            
        case 'kda6'
            
            rad = 6;
            studies(s).statCube = 100*(dst.euc<=rad);
            

        otherwise

            error('unrecognized distance function for modeled activation map');

    end

    % zero out values that are very close to zero
    zeroThresh = 0.000001;
    studies(s).statCube(abs(studies(s).statCube)<zeroThresh) = 0;
    
end





