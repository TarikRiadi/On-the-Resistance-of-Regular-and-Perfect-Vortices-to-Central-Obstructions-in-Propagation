function [PM, PM_z, OAM, Profile, title_name, TC, PM_z_FX, title_2] = Obstruction_Analysis(img_size, state, z_i, z_f, profile_radius, type, obstruction_radius, sigma, Rpx, N)
%% Default Arguments

% img_size = 1080;                % Image size of HoloEye is 1920x1080 [px]. Its smallest size is 1080 [px].
% state = 10;                     % Topological charge, AKA: Mode.
% z_f = 500;                      % Final propagation distance.
% z_i = 0;                        % For staged propagation. If z_i = 0 is the same as a direct propagation.
% m = 3;                          % Type of propagation. m = 2 is Fresnel's, m = 3 is Fraunhofer's.
% profile_radius = 70;            % Phase mask's profile radius. 
% type = 0;                       % If 0, use regular OAM. If 1, use Perfect Vortex.
% obstruction_radius = 0;         % Obstruction radius in pixels relative to the image (1080x1080). Also refered as obstruction size.
% sigma = 100;                    % Gaussian size for propagation.
% Rpx = 764;                      % Aperture in [px]. 500 -> R = 4; 764 -> R = 6.11
R = Rpx*8e-3;                     % Aperture in [mm]. This goes directly into the function. pixel size = 8e-3 [mm].
Rt = round(R,2);                  % Round the radius to two decimal spaces for title display.
% N = 40;                         % Number of Bessel's zeroes. AKA # of rings. Parameter is for perfect vortices, not regular OAMs.

%% Propagation type m criteria
% 171 is in [px] and was obtained from measuring using imfindcircles the beam size of both regular and perfect vortices. Because
% both measures are independent from the state, they are valid for all future iterations.

zl = 171*8e-3*8e-3/660e-6;        % Fresnel.m criteria for m argument.
if z_f-z_i > 2*zl && z_f-z_i < 3*zl
    m = 2;                        % if zl < z --> m = 2
elseif z_f-z_i >= 3*zl
    m = 3;                        % zl << z --> m = 3
elseif z_f-z_i == zl
    m = 1;                        % z --> m = 1
end
%% Create phase mask, block center (if obstruction_radius > 0) and propagate
if z_f == inf
    title_name = ['$\ell$ = ',num2str(state),', $z_{total}$ = $\infty$' ', Obstruction radius = ',num2str(obstruction_radius), ' [px]']; % Base title.
else
    title_name = ['$\ell$ = ',num2str(state),', $z_{total}$ = ',num2str(z_f), ', Obstruction radius = ',num2str(obstruction_radius), ' [px]']; % Base title.
end

if type == 0
    disp('REGULAR VORTEX');
    disp('Creating phase mask.');
    PM = OAMgridFullHD_GS(state);                                           % Generates the phase mask of a regular vortex.
    PM = imcrop(PM, [421 0 1079 1080]);                                     % Crop the mask to be of resolution: 1080x1080, while remaining centered.
    %PM = MrEM_newimg(PM,img_size,img_size,0);
    PM = Obstruct(PM,obstruction_radius,z_i,img_size);                      % Insert circular obstruction in the center of the phase mask.         
    [OAM, Field] = Propagate(PM,z_f-z_i,m,sigma);                           % Propagate the altered phase mask (obstructed or composite).
    disp('Propagating phase mask.');
    title_name = strcat(title_name,[', $\sigma$ = ',num2str(sigma)]);   % Add the sigma to the title.
elseif type == 1
    disp('PERFECT VORTEX');
    disp('Creating phase mask.');
    PM = OPE_Mask(img_size,state,R,N);                                         % Generates the phase mask of a perfect vortex.
    PM = Obstruct(PM,obstruction_radius,z_i,img_size);                      % Insert circular obstruction in the center of the phase mask.
    disp('Propagating phase mask.');        
    [OAM, Field] = Propagate(PM,z_f-z_i,m);                                 % Propagate the altered phase mask (obstructed or composite).
    % Add the # Bessel zeros (N) and aperture size (R) to the title:
    title_name = strcat(title_name,[', $N$ = ',num2str(N), ' and R = ',num2str(Rt),' [mm]']);
else
    error('The variable "type" should be either 0 or 1.');
end

% if z_f == inf || z_f == -inf
%     title_name = strcat(title_name, ', Far Field');
% elseif m == 2 || m == 3
%     title_name = strcat(title_name, ', Near Field');
% elseif m == 1
%     title_name = strcat(title_name, ', Very Near Field');
% end
                                                    
Profile = OAM(img_size/2,:);                        % Take intensity profile of propagated OAM.
PM_z = angle(Field)/(2*pi) + 0.5;                   % Normalize the propagated PM to {0,1} to match PM's values' representation.

%% Measure the topological charge
disp('Estimating topological charge.');
[TC,PM_z_FX] = Circ_Profile(PM_z,profile_radius);
title_2 = strcat(title_name,[', Profile Radius = ',num2str(profile_radius),' [px]']);

end
