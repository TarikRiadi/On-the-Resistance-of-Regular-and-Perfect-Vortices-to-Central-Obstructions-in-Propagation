function [Phase_Mask] = Obstruct(PM,radius,z,img_size)
% Add black circular obstruction of radius [radius] to the phase mask [PM]. If staged propagation is desired, propagate PM a
% distance z before adding the obstruction. If radius = 0, no obstruction is added.


%% Propagate phase mask (PM) a distance z before adding the obstruction

zl = 171*8e-3*8e-3/660e-6;        % Fresnel.m criteria for m argument.
if z > 2*zl && z < 3*zl
    m = 2;
elseif z >= 3*zl
    m = 3;
else
    m = 1;
end

[foo, Field] = Propagate(PM,z,m);     % Propagate such phase mask a "z" distance before adding the obstruction (first stage propagation).
clear foo;                          % Clear OAM, not needed for propagation.
PM = angle(Field)/(2*pi) + 0.5;     % Phase Mask normalized from 0 to 1, like original OPE_Mask.


%% Obtain the inner circle's radius.

Phase_Mask = insertShape(PM, 'FilledCircle', [img_size/2 img_size/2 radius], 'color', 'black', 'Opacity', 1); 
Phase_Mask = rgb2gray(Phase_Mask);                              % Change back into single matrix instead of 3 dimensional RGB.
% else
%     radius = 0;
%     center = [img_size/2 img_size/2];
% end

end

