function [C] = OAMgridFullHD_GS(state)
lambda = 660e-9;
Wo = 0.001;
z = 0;
ang = 0;
kind = 2;
state2 = 0;
mul = 0;
pp = 0;
%[MASK] = OAMgridFullHD_GS(lambda, Wo, state,  z, ang, kind, state2, mul,pp);
%Hologram for modulate a SLM SDE1280 ouput with a OAM interference mask.
%Input variables:
% lambda    - wavelength [m] (660e-9 for Thorlabs pigtail laser)
% Wo        - beam waist [m]  
% state - phase singularity/topological charge [state=1,2..]
% z - propagation distance [m]
% ang - angle between Eref and Eobj [degrees]
% kind - specifies the kind of hologram to be simulated
%       kind  = 1   --> 1D Binary hologram
%       kind  = 2   --> 1D Blazed hologram
%       kind  = 3   --> 1D Sinusoidal hologram
%       kind  = 4   --> 2D Sinusoidal hologram
%       kind  = 5   --> 2D Sinusoidal Analyzer hologram
%       kind  = 6   --> 1D Sinusoidal Colineal LG modes hologram
%   OBS: 2D gratings have no curvature.
% state2 - phase singularity/topological charge of the 2nd mask / Colinear
%          LG mode
% mul - generate from values > zero, a forced curvature radius for a
%      converging OAM beam. mul = 1 allow propagation curvature
% pp - vertical/horizontal holograma (only for 1D gratings). Use OAM sign
%      for invert pattern.
%      0 = horizontal 1D grating ; 1 = vertical 1D grating
%GG - define el rango de fase del slm


%Calling example:
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49);            <-- OAM binary grid
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 2);         <-- OAM blazed grid
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 3, 0, 1);   <-- OAM sinusoidal grid with curvature
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 3, 0, 0, 1);<-- OAM vertical sinusoidal grid
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 4, 3);      <-- OAM 2D sinusoidal grid
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 5, 3);      <-- OAM 2D blazed grid
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 6, 3);      <-- OAM Analyzer at grid z = 0
%   P = OAMgridLinealized(660e-9, 0.001, 1, 1200e-9, 0.49, 6, 3);<-- OAM Analyzer 
%   P = OAMgridLinealized(660e-9, 0.001, 1, 0, 0.49, 7, -3);     <-- OAM Colineal LG modes hologram
% 1st revision: 07/April/2012 - Joaquin Herreros Fernandez
% 2nd revision: 09/Sept/2014 - Jaime Anguita



%Parameters
z0=Wo^2*pi/lambda;          % Rayleigh length
Rz=z*(1+(z0/z)^2);          % radius of curvature
K = 2*pi/lambda;            % wave-vector

%Holoeye Pluto II HD parameters
width = 0.01536;           % hologram width [m]    
heigth = 0.00864;          % hologram height [m]
Nx = 1920;                  % Pixel Resolution - width
Ny = 1080;                  % Pixel Resolution - height
%elip2 = Nx/Ny;              % Correction parameters of display ellipticity

%Parameters for Phase Reconstruction
%width = 0.007;           % hologram width [m]    
%heigth = 0.007;          % hologram height [m]
%Nx = 512;                  % Pixel Resolution - width
%Ny = 512;                  % Pixel Resolution - height

%Parameters for Phase Reconstruction
%width = 0.00864;      %0.00864 for 1080 and 0.007 for 512    % hologram width [m]    
%heigth = 0.00864;     %0.00864 for 1080 and 0.007 for 512    % hologram height [m]
%Nx = 1080;                  % Pixel Resolution - width 1080 or 512
%Ny = 1080;                  % Pixel Resolution - height 1080 or 512

%Fake curvature radius - makes a converging OAM beam
if(mul<=0)
    Rz=Inf;
end
if(mul>0)
    if(z == 0)
        Rz = mul;
    else
        Rz=Rz*mul;
    end
end

%Saving index for filename
if(state >= 0)
    oamstr=num2str(state);
else
    prev = num2str(state);
    oamstr=strcat('m',prev);
end
if(state2 >= 0)
    oamstr2=num2str(state2);
else
    prev2 = num2str(state2);
    oamstr2=strcat('m',prev2);
end

%Creating the Hologram Mask
C = zeros(Ny,Nx);
xp = (-width/2: width/(Nx-1): width/2);     % spatial grids
yp = (-heigth/2: heigth/(Ny-1): heigth/2);
aux1 = ones(length(yp),1);
aux2 = ones(length(xp),1);
x = aux1*xp;                                % spatial axis matrices
y = -(aux2*yp)';%*elip2;
r = sqrt(x.^2 + y.^2);                      % radius
phi = atan2(y,x);                           % azimuth angle
 
%Creating interference profiles
orientacion = '';
switch kind
  
  case 2
        if pp==0
            delta =  K*sin(ang*pi/180)*(x*(1 - pp) + y*pp) + K/2*r.^2/Rz - state*phi + pi/2*(mod(sign(state)*state,4)-2*mod(sign(state)*state+1,2));
            orientacion = '_vertical';
        elseif pp==1
            delta =  K*sin(ang*pi/180)*(x*(1 - pp) + y*pp) + K/2*r.^2/Rz - state*phi + pi;
            orientacion = '_horizontal';
        end
        C = mod(delta,2*pi)/(2*pi);
        name2='Blz';
  
  otherwise
    C = 0;
    disp('Wrong Value for "kind" parameter. Type "help OAMgrid" for explanation.');
    return;
end


% File writing
filename=strcat(name2,'_OAM',oamstr,'and',oamstr2,'_ang',num2str(ang),orientacion,'.png');
%imwrite(C ,filename)
%figure; imshow(C)
