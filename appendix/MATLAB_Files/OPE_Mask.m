function [C,r,phi,alpha,state] = OPE_Mask(size, state, aperture, bs_k)
%[MASK] = OPE_Mask(size, lambda, state,  aperture, bs_k);
%Hologram for modulate a SLM SDE1280 ouput with a Optimal Phase Element mask.
%Input variables:
%   state - phase singularity/topological charge [state=1,2..]
%   aperture:  radii of the aperture in mm
%   bs_k number of zeros of bessel function (N). [Tarik:] Also affects size of resulting mask's inner circle. N >> -> smaller radius. 

%Bessel zeros values and scalar alpha
%if nargin < 5
%    gauss_size = 8.64;
%end

R=aperture;
J = besselzero(state,bs_k,1);
alpha = J(bs_k)/R; %state = 10, bs_k = 40 -> alpha = 22.9435

%Holoeye Pluto II HD parameters
Nw = 0.01536/1920;        % Pixel Resolution - width (8e-6)
%Nw = gauss_size*10^-6;
Nh = 0.00864/1080;        % Pixel Resolution - height (8e-6)
%Nh = gauss_size*10^-6;
Nx = size; width = Nx*Nw*1000;          % hologram width [mm] (1080*8e-6*1000 = 8.64)      
Ny = size; height = Ny*Nh*1000;         % hologram height [mm]        

%width = gauss_size;   % Total width of the gaussian expressed in px.
%height = gauss_size;  % Total height of the gaussian expressed in px.

%Creating the Hologram Mask
%C = zeros(Ny,Nx);
xp = (-width/2: width/(Nx-1): width/2);     % spatial grids
yp = (-height/2: height/(Ny-1): height/2);
aux1 = ones(length(yp),1);
aux2 = ones(length(xp),1);
x = aux1*xp;                                % spatial axis matrices
y = -(aux2*yp)';
r = sqrt(x.^2 + y.^2);                      % radius
%in_r = imcomplement(r);
%figure(), imshow(in_r), axis('on', 'image'), xlabel('Width'), ylabel('Height'), title('Gaussian Beam');
phi = atan2(y,x);                           % azimuth angle


J_n = besselj(state,alpha*r);               %Bessel function
circ=zeros(size,size);
%Creating circ function
for l=1:size
    for k=1:size
        if r(l,k)<=R
            circ(l,k)=1;
        else
            circ(l,k)=0;
        end
    end
end

%Creating phase Mask

delta = state*phi + pi/2*sign(J_n);
delta = delta.*circ;    


C = mod(delta,2*pi)/(2*pi);



