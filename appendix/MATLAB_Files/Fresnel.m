function Frt=Fresnel(Obj1,di,m)

% Propagation through Transfer Function Fourier Transform
% dx,dy: pixel size in mm
% wa: wavelength in mm
% di: Propagation distance z in mm
% p: padding size regards the original image
% m: Employed metod (1 if for ASP, 2 is near field (Fresnel), 3 is far field (Fraunhofer))
% if zl = W*dx*dy/wa : z --> m = 1 | if zl < z --> m = 2 | zl << z --> m = 3
% The previous criteria is not the same as the far field distance Fraunhofer. Hence, 3 is not far field, is a Fresnel mod. The 
% only true far field in this funtion comes from setting di = infinity or - infinity, which bypasses the argument m by definition.

dx = 8e-3; 
dy = 8e-3;
wa = 660e-6;
p = 2;
%%% Size and scale
aobj=mean(mean((abs(Obj1)).^2));

W0=size(Obj1);
Wy=W0(1);
Wx=W0(2);
Wy2=Wy/2;
Wx2=Wx/2;

Ny=p*Wy;
Nx=p*Wx;
NN=Ny*Nx;
N=sqrt(NN);
Ny2=Ny/2;
Nx2=Nx/2;

%%% Window
Obj2=zeros(Ny,Nx);
ya=Ny2-Wy2+1;
yb=ya+Wy-1;
xa=Nx2-Wx2+1;
xb=xa+Wx-1;
Obj2(ya:yb,xa:xb)=Obj1;

if aobj==0 Frt=zeros(Wy,Wx); return; end

%%% Different cases
switch di
    case 0
        Frt=Obj1;
    case inf
        Transf=fftshift(fft2(fftshift(Obj2)))/N;
        Frt=Transf(ya:yb,xa:xb);
        afrt=mean(mean((abs(Frt)).^2));
        Frt=Frt*sqrt(aobj/afrt);
    case -inf
        Transf=fftshift(ifft2(fftshift(Obj2)))/N;
        Frt=Transf(ya:yb,xa:xb);
        afrt=mean(mean((abs(Frt)).^2));
        Frt=Frt*sqrt(aobj/afrt);
    otherwise
        %%% Constants and others
        y1=1-Ny2;
        y2=Ny-Ny2;
        x1=1-Nx2;
        x2=Nx-Nx2;
        [Fx,Fy]=meshgrid(x1:1:x2,y1:1:y2);
        if m==1
            k=di/wa;
            kx=(wa/(dx*Nx))^2;
            ky=(wa/(dy*Ny))^2;
            FTrans=exp(-1i*2*pi*k*sqrt(1-ky*Fy.^2-kx*Fx.^2));
            Const=1;
        end
        if m==2
            k=(wa*di)/((dx*dy)*NN);
            FTrans=exp(-1i*pi*k*(Fy.^2+Fx.^2));
            Const=exp(1i*2*pi*di/wa);
        end
        if m==3
            k=(dx*dy)/(wa*di);
            FresR=exp(1i*2*pi*di/wa)*exp(1i*pi*k*(Fy.^2+Fx.^2));
            FTrans=fftshift(fft2(fftshift(FresR)))/N;
            Const=1;
        end
        %%% Propagation
        Transf=fftshift(fft2(fftshift(Obj2)))/N;
        Transf=FTrans.*Transf;
        Transf=fftshift(ifft2(fftshift(Transf)))/N;
        Transf=Const.*Transf;

        %%% Window
        Frt=Transf(ya:yb,xa:xb);
        %%% Scale adjustment
        afrt=mean(mean((abs(Frt)).^2));
        Frt=Frt*sqrt(aobj/afrt);
end
    
    