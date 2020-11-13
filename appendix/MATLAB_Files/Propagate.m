function [Prop_Int,Field] = Propagate(Phase_Mask, z, m, sigma)

%{
This function propagates a field given its phase mask (2D image) through a distance z. If sigma is given, it adds a
gaussian to the variable Obj, which is useful for Fresnel propagation and regular OAMs. m is the type of propagation; its
criteria is defined in the function Fresnel.m. Usually for the beams worked for resolutions of 1080x1080 won't be greater than
200 [px], and given the pixel size and wavelength used, it means that for most cases m = 3 will be used.
%}
if nargin < 3
    m = 3;          % Because of the previous statement, m = 3 will be the default value as it has the lower failure probability.
    A = 1;          % Here, no sigma is provided. Therefore, default the real field A to the identity matrix.
elseif nargin < 4
    A = 1;          % If no sigma is provided, then default the real field A to the identity matrix.
else
    A = Gaussian_2D(size(Phase_Mask,1),sigma);
end
        
%% Modify phase mask and propagate with Fresnel.
initial_field = Phase_Mask.*(2*pi/max(max(Phase_Mask)));    % Normalization to 2*pi. Required for Fresnel.m
Obj = A.*exp(1i*initial_field);                             % This should be the 2D gaussian of form: A*e^{i*phi}.
[Field] = Fresnel(Obj, z, m);                               % Propagate the PM. Return the complex field.                                                                                            
Prop_Int = abs(Field).^2;                                   % Intensity field.
Prop_Int = Prop_Int-min(Prop_Int(:));                       % Normalize intensity field on {0,1} scale.
Prop_Int = Prop_Int/max(Prop_Int(:));                       % Normalize intensity field on {0,1} scale.

end

