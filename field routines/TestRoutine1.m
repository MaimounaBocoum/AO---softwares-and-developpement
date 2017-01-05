%%% this is a test routine %%%
%% maimouna bocoum 04-01-2017
clear all
clearvars ;

addpath('..\Field_II')
field_init(0);
field_debug(0);
% set_field('show_time',1);

f0=6e6; % Transducer center frequency [Hz]
fs=500e6; % Sampling frequency [Hz]
c=1540; % Speed of sound [m/s]
lambda=c/f0; % Wavelength [m]
element_height= 10/1000; % Height of element [m]
width=0.2/1000; % Width of element [m]
kerf= 0; % Distance between transducer elements [m]
N_elements = 128; % Number of elements
%N_active = 128; % number of active elements for the reception
focus = [0 0 35]/1000; % Initial electronic focus
Rfocus = 40/1000; % Elevation focus
attenuation = 0.6;         % en db/cm/Mhz
no_sub_x = 1;
no_sub_y = 10;

%% Probe defintion :
% Set the sampling frequency
set_sampling(fs);
set_field('c',c);
set_field('Freq_att',attenuation*100/1e6);
set_field('att',2.6*100);
set_field ('att_f0',f0); 
set_field('use_att',1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generate aperture for emission
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Probe = xdc_linear_array (N_elements, width, element_height, kerf,no_sub_x,no_sub_y, focus);
Probe = xdc_focused_array(N_elements,width,element_height,kerf,Rfocus,no_sub_x,no_sub_y,focus);
%show_xdc (Probe)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setting the impulse response field (Green function)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Emission signal : I think by befault, the green function is calculated
% for a different frequency
 impulse = sin(2*pi*f0*(0:1/fs:2/f0));
 impulse=impulse.*hanning(length(impulse))'; 
 xdc_impulse (Probe, impulse);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Definition of excitation function for actuator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

N = N_elements;
PositionActuators = [1:N]';
% user defined excitation :
% f0 : central frequency defined above used in default - wavform definition
% fs : sampling frequency defined above used in default - wavform definition
% N number of actuator 
% PositionActuators : Position of active actuator. 


% RI = MakeRI_Remote(f0,fs,50);
% Tpulse = length(RI)/fs;
% xdc_excitation(te,RI);
%Actuators = ExcitationField(f0,fs,N);
%ele_waveform(Probe,PositionActuators,0*Actuators.Excitation);

% test excitatation

%excitation= Actuators.Excitation(1,:);%sin(2*pi*f0*(0:1/fs:2/f0));

% Noc = 2;
% excitation = sin(2*pi*f0*[0:1/fs:Noc/f0]);
% excitation = excitation.*hanning(length(excitation))';
%xdc_excitation (Probe, excitation);

RI = MakeRI_Remote(f0,fs,50);
Tpulse = length(RI)/fs;
xdc_excitation (Probe, RI);

% apodisation :
apodisation = ones(N_elements,1);
xdc_apodization(Probe,0,apodisation')
%xdc_focus (Probe,4e-6,[0 0 3]/1000);
%ele_waveform(Probe,PositionActuators,Actuators.Excitation);

%% Simulation box initialization : 
Nx = 18;
Ny = 4;
Nz = 20;

Xrange = [-0.45 0.45]; % in m
Yrange = [-1 1];
Zrange = [35 45]/1000; % in m

SimulationBox = AO_FieldBox(Xrange,Yrange,Zrange,Nx,Ny,Nz);
Hf1 = figure(1);
set(Hf1,'name','position of detection')
% scatter3(SimulationBox.X*1e3,SimulationBox.Y*1e3,SimulationBox.Z*1e3)
% xlabel('x(mm)')
% ylabel('y(mm)')
% zlabel('z(mm)')

% calculation of the emitted Field :
[h,t] = calc_hp(Probe,SimulationBox.Points());
time = t + [0:(size(h,1)-1)]/fs;
% h : each column corresponds to the field calculated for the
% SimulationBox.Points() list

% Screen Raw data Result
Hf2 = figure(2);
set(Hf2,'name','raw data returned By calc_hp function')
%imagesc(1:Nx*Ny*Nz,time,log(abs(h)))
[~,I] = sort(SimulationBox.X(:).^2 + SimulationBox.Y(:).^2 +SimulationBox.Z(:).^2);
imagesc(1:Nx*Ny*Nz,time*1e6,log(h(:,I).^2))
title('image in log scale')
xlabel('Point index')
ylabel('time (\mu s)')
colorbar

% Screen maximum field for each position:
Field_resized = reshape(h',[Nx,Ny,Nz,length(time)]);

MaxAxis = max(Field_resized(:).^2);
% for loop = 1:10:length(time)
% Hf2 = figure(3);
% set(Hf2,'name','field resized to simulation box')
% imagesc(SimulationBox.x*1e3,SimulationBox.z*1e6,abs(squeeze(Field_resized(:,1,:,loop))).^2);
% title(['image in log scale at',num2str(time(loop)),'s'])
% xlabel('x (mm)')
% ylabel('z (\mu m)')
% caxis([0 MaxAxis])
% colorbar
% 
% end

% screen maximum value for the field :
Field_max= reshape(max(h,[],1),[Nx,Ny,Nz]);
Hf3 = figure(3);
set(Hf3,'name','maximum field values')
imagesc(SimulationBox.x*1e3,SimulationBox.z*1e6,abs(squeeze(Field_max(1,:,:))).^2);
xlabel('x (mm)')
ylabel('z (\mu m)')
caxis([0 MaxAxis])
colorbar


xdc_free(Probe);
field_end;
