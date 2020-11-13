function [A] = Gaussian_2D(img_size,sigma)
% Gaussian 2D generates a centered 2D gaussian distribution.
%   size: Image size in pixels. Assumes a square size.
%   sigma: Standard deviation. Is the size of the gaussian in the image.
%   
mu = img_size/2;
A = zeros(img_size);
for x = 1:size(A,1)
    for y = 1:size(A,2)
        A(x,y) = (1/sigma*sqrt(2*pi))*exp(-((x-mu)^2+(y-mu)^2)/(2*sigma^2));
    end
end
A = mat2gray(A);
%figure(), imshow(A), axis('on','image'), impixelinfo(), xlabel('Width'), ylabel('Height'), title('Gaussian');
end

