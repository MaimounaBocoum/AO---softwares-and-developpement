%%% generation of traces using radon transform for OP - OS parameters
% maimouna bocoum 24-10-2017
clearvars ;

addpath('..\Field_II')
addpath('..\radon inversion')
addpath('..\radon inversion\shared functions folder')
field_init(0);

parameters;
IsSaved = 0 ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%% Start an experiment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CurrentExperiement = Experiment(param);
% evaluate Phantom on simulation Box :
CurrentExperiement = CurrentExperiement.EvalPhantom();
% I = CurrentExperiement.ShowPhantom();
[MyTansmission,R,zR] = CurrentExperiement.ShowPhantom(param.angles);

Lprobe = param.N_elements*(param.width + param.kerf) ;
Z0 = (max(CurrentExperiement.MySimulationBox.z)-min(CurrentExperiement.MySimulationBox.z))/2 ;


x = CurrentExperiement.MySimulationBox.x + Lprobe/2;
z = CurrentExperiement.MySimulationBox.z ;
[X,Z] = meshgrid(x,z);



% radon transform of the image :
AOSignal = zeros(length(z),CurrentExperiement.Nscan) ;
DelayLAWS = zeros(param.N_elements,CurrentExperiement.Nscan);


 for n_scan = 1:CurrentExperiement.Nscan
theta = CurrentExperiement.ScanParam(n_scan,1);
CurrentExperiement = CurrentExperiement.InitializeProbe(n_scan) ;
DelayLAWS( : ,n_scan) = CurrentExperiement.MyProbe.DelayLaw ;
 end
 
X_m = (1:param.N_elements)*param.width; 
ActiveLIST = CurrentExperiement.BoolActiveList ;

% C : point of invariation by rotation of angle theta
[angles, M0 , ~ , ~ ,C] = EvalDelayLawOS_shared( X_m , DelayLAWS, ActiveLIST, param.c);

M = repmat([Lprobe/2 , 18e-3],CurrentExperiement.Nscan,1);
angles = CurrentExperiement.ScanParam(:,1);
Nangles = length(unique(angles)) ; 

%% run scan 
figure ;
for n_scan = 1:CurrentExperiement.Nscan
% theta = angle(n_scan);
% C : center of rotation = [mean(X_m),0]
[Irad,MMcorner] = RotateTheta( X , Z , MyTansmission , angles(n_scan) , M(n_scan,:) );

% u = [cos(theta) ; -sin(theta)] ;
% v = [sin(theta) ; cos(theta)]  ;

Mask0 = interp1(CurrentExperiement.MyProbe.center(:,1,1) ,...
               double(CurrentExperiement.BoolActiveList(:,n_scan)),(X-Lprobe/2));
%            if n_scan ==1
%            Mask = cos(0*X);    
%            else
            
                if ( n_scan > Nangles )
                    
    if  ( mod( n_scan - Nangles , 2*Nangles )+1  <= Nangles )
    Mask = cos(2*pi*param.df0x*CurrentExperiement.ScanParam(n_scan,2)*(X-Lprobe/2));
    elseif ( mod( n_scan- Nangles , 2*Nangles )+1 > Nangles )
    Mask = sin(2*pi*param.df0x*CurrentExperiement.ScanParam(n_scan,2)*(X-Lprobe/2));   
    else
    Mask = 0;
     end
                else
                    Mask = 1;
                end

        

 Irad = Irad.*Mask ;
 %Irad = Irad.*Mask ;  


% correction matrice
imagesc(x*1e3,z*1e3,Irad)
xlabel('x(mm)')
ylabel('ct(mm)')
AOSignal(:,n_scan) = trapz(x,Irad,2) ;
% AOSignal(:,n_scan) = interp1(1:size(Irad,1),trapz(x,Irad,2),...
%                             (1:size(Irad,1))-d_offset,'linear',0) ;
drawnow
axis equal
end
 
AOSignal = AOSignal + 0*1e-3*rand(size(AOSignal)) ;

figure;
imagesc(CurrentExperiement.ScanParam(:,2),z*1e3,AOSignal)
xlabel('order N_x')
ylabel('z(mm)')

%% filtered retroprojection

figure;
imagesc(CurrentExperiement.ScanParam(:,2),z*1e3,AOSignal)
xlabel('order N_x')
ylabel('z(mm)')
% structure with appropriate axis and fourier transform methods
MyImage = OS(AOSignal,CurrentExperiement.ScanParam(:,1),...
             CurrentExperiement.ScanParam(:,2),param.df0x,...
             CurrentExperiement.MySimulationBox.z,...
             param.fs_aq,...
             param.c,[min(X_m) , max(X_m)]);

%% resolution par iradon
[ F_ct_kx , theta , decimation ] = MyImage.AddSinCos( MyImage.R ) ;
% figure;imagesc(real(F_ct_kx(:,182:end)))
MyImage.F_R = MyImage.fourierz( F_ct_kx ) ; 
%  F_Rconj = MyImage.fourierz( conj(F_ct_kx) ) ; 
%  FILTER = MyImage.GetFILTER(0.5e-3,size(MyImage.F_R,2));
%  Fin   = MyImage.ifourierz(MyImage.F_R.*FILTER) ;
 Fin =  MyImage.F_R ;
%  F_Rconj = conj(Fin);
 
%  subplot(221);surfc(theta(182:end)*180/pi,MyImage.fz,abs(Fin(:,182:end)))
%  subplot(221);imagesc(theta(182:end)*180/pi,MyImage.fz,abs(Fin(:,1:182)))
 
 df0x =param.df0x;
 
%  figure;imagesc(MyImage.z,theta*180/pi,abs(Fin))

        I0 = find(decimation == 0);
        F0 = repmat( Fin(:,I0) , 1 , length(unique(decimation)) ); % extract decimation = 0
       
        [DEC,FZ] = meshgrid(decimation,MyImage.fz) ;
       
        Hinf = (abs(FZ) < DEC*df0x) ;
        
        Hsup = (abs(FZ) >= DEC*df0x & FZ >= 0) ; %   
%         Hsup_conj = (abs(FZ) >= DEC*df0x & FZ <= 0 ) ;
        
        Lobject = 0.2e-3;
        FILTER = MyImage.GetFILTER(Lobject,size(Fin,2));
        
        
        Finf = F0.*FILTER.*Hinf ;
        
        Fsup = Fin.*FILTER.*Hsup ;
%         F_Rconj= F_Rconj.*FILTER.*Hsup_conj ;
       
        Fsup = MyImage.ifourierz(Fsup);
%         F_Rconj= MyImage.ifourierz(F_Rconj);
        
        Finf = MyImage.ifourierz(Finf);

            
[X,Z]= meshgrid(X_m,MyImage.z);
Ireconstruct = zeros(size(X,1),size(X,2),'like',X);

%[H0,~] = RotateTheta( X , Z , h0 , -theta(i) , M(i,:) );
        figure;
        %  A = axes ;
       for i=1:length(theta)
       
       % filter properly      
        
        T =   (X - M(i,1)).*sin( theta(i) ) ...
            + (Z - M(i,2)).*cos( theta(i) ) + M(i,2) ;
        S =   (X  -  Lprobe/2).*cos(theta(i) ) ...
            - (Z - M(i,2)).*sin( theta(i) ) ;

        % common interpolation: 

        %Mask = double( interp1(X_m,ActiveLIST(:,i),X,'linear',0) );
        H0 = exp(1i*2*pi*decimation(i)*df0x*S);

        projContrib_sup = interp1(MyImage.z,Fsup(:,i),T(:),'linear',0);
        projContrib_sup = reshape(projContrib_sup,length(MyImage.z),length(X_m));
%         projContrib_supConj = interp1(MyImage.z,F_Rconj(:,i),T(:),'linear',0);
%         projContrib_supConj = reshape(projContrib_supConj,length(z),length(x));
        
        
      
        projContrib_inf = interp1(MyImage.z,Finf(:,i),T(:),'linear',0);
        projContrib_inf = reshape(projContrib_inf,length(MyImage.z),length(X_m));

    
       % retroprojection: Conj
        Ireconstruct = Ireconstruct + H0.*projContrib_sup + conj(H0.*projContrib_sup) + projContrib_inf ;
        %%% real time monitoring %%%  
       imagesc( X_m*1e3,MyImage.z*1e3,real(Ireconstruct))
       hold on
       plot(M(1,1)*1e3,M(1,2)*1e3,'o')
       colormap(parula)
       cb = colorbar ;
       title(['angle(�): ',num2str(theta(i)*180/pi)])
       ylim(MyImage.Lz*1e3)
       xlabel('x (mm)')
       ylabel('z (mm)')
       caxis( [ min(real(Ireconstruct(:))) , (1+1e-3)*max(real(Ireconstruct(:)))  ] )
      
       %saveas(gcf,['Q:\AO---softwares-and-developpement\radon inversion\gif folder/image',num2str(i),'.png'])
       drawnow

 
       end

        %%

figure;
%test : fourier transform of original object
 x_phantom = CurrentExperiement.MySimulationBox.x ;
 z_phantom = CurrentExperiement.MySimulationBox.z ;
 imagesc(x_phantom*1e3,z_phantom*1e3,MyTansmission)
       xlabel('x (mm)')
       ylabel('z (mm)')
       cb = colorbar ;
% figure
% imagesc(X_m*1e3, MyImage.z*1e3,real(Ireconstruct))
% xlim(param.Xrange*1000+ mean(X_m)*1000)
% ylim(param.Zrange*1000) 
