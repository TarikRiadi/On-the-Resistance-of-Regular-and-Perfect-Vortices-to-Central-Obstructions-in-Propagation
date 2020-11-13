function [Profile,Circumference] = Circ_Profile(PM, radius)
% Circular Profile, or Circ_Profile for short, takes a profile of a phase mask [PM] on a circumference of radius [radius]. 
% It returns the values in said points arranged in a single array named [Profile].

img_size = size(PM,1);                                                      % Obtain image size from input.
centre = [img_size/2 img_size/2];                                           % Centre coordinates, assuming input is a (1:1) image.
theta = linspace(0,2*pi,10000);                                             % Define the angle as 0 -> 2*pi with an interval resolution of 1e4.
x = centre(1)+radius*cos(-theta+pi);                                        % x coordinates of the circumference.
y = centre(2)+radius*sin(-theta+pi);                                        % y coordinates of the circumference.
x_1 = floor(x); y_1 = floor(y);
Profile = zeros(1,length(x_1));                                             % Prelocate profile size for efficiency.
thetai = 0; thetaf = 2*pi;                                                  % Make a full circle from 0 -> 2*pi.
for i = 1:length(x_1)    
   if i < (length(x_1)*thetaf)/(2*pi) && i > (length(x_1)*thetai)/(2*pi)
       Profile(i) = PM(x_1(i),y_1(i));                                      % Adds the value to the array Profile.
   end
end
Circumference = insertShape(PM, 'circle', [centre radius], 'LineWidth', 4, 'Color', 'Cyan'); % Draw a circumference where the profile was taken.
end

