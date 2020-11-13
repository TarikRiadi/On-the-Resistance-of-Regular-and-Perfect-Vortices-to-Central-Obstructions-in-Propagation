%% Foreword
%{
This script is escentially made to iterate over the function Obstruction_Analysis for different sets of arguments.
Used/Required functions:
1. Obstruction_Analysis.m, which uses:
2. Obstruct.m          -> Adds an obstruction of a specified radius in the form of a black circle onto the center of a given image.
3. Gaussian_2d.m       -> Generates a 2D gaussian given a sigma (StdDev) and an image size.
4. Propagate.m         -> Propagates a phase mask through a specified distance with either Fresnel [m=2] or Fraunhofer [m=3] propagation.
                          It can also add a gaussian to the intensity for regular OAMs.
5. Fresnel.m           -> Fresnel and Fraunhofer propagation mathematical definitions with Fresnel integral and fft.
6. Circ_Profile.m      -> It takes a profile described by a simple circumference of a specified radius.
7. OPE_Mask.m          -> Creates the phase mask for a perfect vortex.
8. besselzero.m        -> Finds a specified number [N] of Bessel zeroes.
9. OAMgridFullHD_GS    -> Creates the phase mask for a regular vortex.

Functions 5, 7, 8 and 9 are made by other authors.
Functions 1 through 4 and 6 are made by Tarik S. Riadi.
%}

%% Clear workspace
if exist('wb','var') == 1
    delete(wb);     % Clear the waitbar.
end
clear;              % Clear variables in the workspace.
clc;                % Clear console for a clean run.

%% Create folder to save results into
ti = tic;
folder_name = ['Results ' date]; % Folder is named "Results [date]", where date is today's date as: 01-Jan-2020
index = 1;                       % Index works only if folder name already exists, i.e, if one runs the code more than once a day.
while exist(folder_name,'dir') == 7 % If there is a folder of the same name.
    folder_name = ['Results ' date ' (' num2str(index) ')']; % Rewrite name as <<folder_name (#)>> where # is the first [index] available.
    index = index + 1;          % Increment index value until an unused one is found.
end
mkdir(folder_name);             % Make the new folder.
clear index                     % Unnecesary variable from now on.
    
%% Variables
prompt = {'Vortex Type(s)', 'State', 'Sigma - Regular Vortex', 'N - Perfect Vortex', 'R [px] - Perfect Vortex', 'Stage 1 Distances [mm]', 'Total Propagation Distances [mm]', 'Obstruction Radii [px]', 'Image format'};
dialog_title = 'Input Arguments';                           % Window/Dialog title.
dims = [1 35];                                              % Blank space dimensions.
default_input = {'0 1','10','100','40','764','0','1000 1500 inf', '0 10 20 30 40 50', 'epsc'};     % Default values.
answers = inputdlg(prompt,dialog_title,dims,default_input); % Input dialog as defined by above parameters.
img_size = 1080;                                            % Image size of HoloEye is 1920x1080 [px]. Its smallest size is 1080 [px].
types = str2num(answers{1,1});
state = str2double(answers{2,1});                           % Topological charge, AKA: state, mode or L (in figures).
sigma = str2double(answers{3,1});                           % Gaussian size for propagation. Only used by regular vortices.
N = str2double(answers{4,1});                               % Number of Bessel's zeroes, AKA # of rings. Only used by perfect vortices.
Rpx = str2double(answers{5,1});                             % Aperture in [px]. 500 -> R = 4 [mm]; 764 -> R = 6.11 [mm]. Only used by perfect vortices.
stage_1 = str2num(answers{6,1});                            % Stage 1 distances in [mm], separated by a space for multiple values.
stage_2 = str2num(answers{7,1});                            % Stage 2 distances in [mm], separated by a space for multiple values.
obs_radii = str2num(answers{8,1});                          % Obstruction radii in [px], separated by a space for multiple values.
img_format = answers{9,1};                                  % Image format (png or epsc).

%% If you save imgs as png, create directories to save them in an organized file structure, for easier access and previews.
if strcmp(img_format,'png')
    cd(folder_name);
    for name = stage_2
        mkdir(num2str(name));
        cd(num2str(name));
        mkdir('Perfect Vortices'); mkdir('Regular Vortices');
        cd('Perfect Vortices'); mkdir('TC'); cd ..;
        cd('Regular Vortices'); mkdir('TC'); cd ..;
        cd ..
    end
    cd ..
end

%% Obtain the OAM, its Profile and TC
wb = waitbar(0,'Starting','Name','Obstruction Analyzer Progress','CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
profile_radius = 200;
total_iterations = length(obs_radii) * length(stage_1) * length(stage_2) * length(types); % Counts each iteration.
runtime_per_iter = [];
total_images = 0;                                           % Verifier for it should be = total_iterations*2.
for type = types                                            % Alternate for regular and perfect vortices.
    for obstruction_radius = obs_radii                      % Alternate obstruction size. These values are in [px] and represent the obstruction radius' size. An obstruction of 0 means no obstruction at all.
        %if obstruction_radius == 0                         % If there's no obstruction, fix the profile_radius.
        %    profile_radius = 150;
        %else                                                % If there's an obstruction, make the profile_radius relative to the obstruction_radius.
        %    profile_radius = obstruction_radius + 50;       % Measure the profile just outside the obstruction.
        %end
        for z_i = stage_1                                   % Alternate staged propagation. The values here are in [mm] and represent the distance traveled before an obstruction is met.
            for z_f = stage_2                               % Alternate total propagation distance. Values here are in [mm] and represent the total propagation distance. The difference between z_f and z_i is the distance traveled with an obstruction.
                ti_r = tic;
                if getappdata(wb,'canceling')               % If cancel button is pressed:
                    delete(wb);                             % Close the waitbar.
                    error('Program Aborted!');               % And hand out an error to abort the whole program.
                end
                waitbar((total_images/2)/total_iterations,wb,['Creating Images (',num2str(round((100*total_images/2)/total_iterations)),'%)']);
                [PM, PM_z, OAM, Profile, title_1, TC, PM_z_FX, title_2] = Obstruction_Analysis(img_size, state, z_i, z_f, profile_radius, type, obstruction_radius, sigma, Rpx, N);
                name = ['type=',num2str(type),'_r=',num2str(obstruction_radius),'_zi=',num2str(z_i),'_zf=',num2str(z_f)]; % File name.
                name_tc = strcat(name,'_TC'); % File name for the topological charge plot.
                
                %% Display Images
                figure('Name','Topological Charge','units','normalized','outerposition',[0 0 1 1],'Visible','off');
                plot(TC,'color','c','LineWidth',1.5), set(gca,'color','k','Fontsize',18), set(gcf, 'InvertHardCopy', 'off'), 
                xlabel('Location in Cirumference'), ylabel('Intensity');
                title(title_2,'interpreter','latex','Fontsize',26)
                cd(folder_name);
                if strcmp(img_format,'png')
                    cd(num2str(z_f));
                    if type == 0
                        cd('Regular Vortices');
                        cd('TC');
                    else
                        cd('Perfect Vortices');
                        cd('TC');
                    end
                end
                saveas(gcf,name_tc,img_format);         % Save figure in eps color format. If png is desired, change 'epsc' -> 'png'.
                cd ..
                total_images = total_images + 1;
                figure('Name', 'PMs, OAM and Profile','units','normalized','outerposition',[0 0 1 1],'Visible','off'); 
                subplot(2,2,1);
                imshow(PM), axis('on','image'), xlabel('Width'), ylabel('Height');
                title(['Phase Mask at z = ',num2str(z_i)])
                subplot(2,2,2);
                imshow(PM_z_FX), axis('on','image'), xlabel('Width'), ylabel('Height');
                if z_f == inf
                    title('Phase Mask at z = \infty')
                else
                    title(['Phase Mask at z = ',num2str(z_f)])
                end
                subplot(2,2,3);
                imshow(OAM), axis('on','image'), xlabel('Width'), ylabel('Height');
                if z_f == inf
                    xlim([440 640]), ylim([440 640]); % Zoom into the intensity fields on infinity propagations.
                end
                if type == 1                          % Zoom into the intensity field on a perfect vortex.
                    if z_f == inf || z_f == -inf
                        xlim([440 640]), ylim([440 640]);
                    else
                        xlim([300 800]), ylim([300 800]); 
                    end
                end
                title('OAM')
                subplot(2,2,4);
                plot(Profile,'color','y','LineWidth',1.4), xlabel('Width'), ylabel('Intensity');
                axis on, xlim([0 1080]), ylim([0 1]), set(gca, 'Color', 'k'), set(gcf, 'InvertHardCopy', 'off');
                title('OAM''s Intensity Profile')
                sgtitle(title_1, 'interpreter', 'latex', 'Fontsize',24)                
                if strcmp(img_format,'png')
                    saveas(gcf,name,img_format);            % Save figure in eps color format. If png is desired, change 'epsc' -> 'png'.
                    cd ..; cd ..; cd ..;
                else
                    cd(folder_name);
                    saveas(gcf,name,img_format);            % Save figure in eps color format. If png is desired, change 'epsc' -> 'png'.
                    cd ..;
                end
                total_images = total_images + 1;
                tf_r = toc(ti_r);
                runtime_per_iter = [runtime_per_iter tf_r];
                fprintf('Runtime: %4.2f seconds.\n',tf_r);
                disp('------------------------------------------'); % Add separation to distinguish between each cycle.
            end
        end
    end
end

%% Wrap-up: Summary of execution and clear the waitbar.
waitbar((total_images/2)/total_iterations,wb,['Creating Images (',num2str(round((100*total_images/2)/total_iterations)),'%)']);
delete(wb);             % Close the progress bar window.
Total_Time = toc(ti);   % Measure total elapsed time
avg_time = mean(runtime_per_iter); % Measure the average runtime for each iteration.
fprintf('Program finished successfully!\nVortices analyzed: %d\nImages obtained: %d\nSaved in folder: %s\nTotal elapsed time: %d:%02d\nAverage runtime per vortex: %4.2f seconds\n', total_iterations, total_images, folder_name, round(floor(Total_Time/60)), round(mod(Total_Time,60)), avg_time)