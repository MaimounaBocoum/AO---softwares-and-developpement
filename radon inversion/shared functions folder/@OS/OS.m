classdef OS < TF2D
    %OP Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % image parameters
        theta
        decimation
        ct
        R      % Input radon transform of the object        
        F_R    % Fourier Transform of R with respect to t direction       
        L      % [min max] : dimension of input image in z direction
    end
    
    properties (Access = private)
        SamplingRate         % Samplinf frequency in Hz
        c                    % sound velocity in m/s
        Fc                   % Frequency Cut-Off for screening
        Linphase_fit      
    end
    
    methods
        
        function obj = OS(InputImage,theta,decimation,df0x,ct,SamplingRate,c)
            %N: number of points for fourier transform
            N = 2^10 ;
            Fmax_x = (N-1)*df0x;
            Fmax_z = 1/(ct(2)-ct(1)) ;
            obj@TF2D(N,Fmax_x,Fmax_z);
            
            if (size(InputImage,1) == length(ct) && size(InputImage,2) == length(theta))
            % checkin that dimension match the input image
            obj.SamplingRate = SamplingRate ;
            obj.ct = ct; % longitudinal index for reconstruction box
            obj.c = c ;
            obj.L = [min(ct),max(ct)] ;
            obj.R = InputImage;
            obj.theta = theta;          
            obj.decimation = decimation; 
            
            % interpolation of raw data into fourier grid :
            obj.R = interp1(ct,obj.R,obj.z,'linear',0);
    
            else
            msg = 'dimension matrix mismatch';
            error(msg);
            
            end
            
        end
        
        function obj = InitializeFourier(obj,varargin)

            if nargin == 2
                N = varargin{1};
                t = obj.t ;    
                % udate fourier parameters
                DXsample = obj.c*1/(obj.SamplingRate) ; 
                obj = obj.Initialize(N,1/DXsample);
                % interpolated trace on fourier param
                obj.R = interp1(t,obj.R,obj.ct,'linear',0);
            elseif nargin == 3
                N = varargin{1};
                Fc = varargin{2};
                t = obj.ct ;  
                obj = obj.Initialize(N,Fc);        
                % interpolated trace on fourier param
                obj.R = interp1(t,obj.R,obj.ct,'linear',0);
                
            end
        
        end
              
        function [] = Show_R(obj)
           
            % find number of different angular value :
           [Angles,~,Iangles] = unique(obj.theta) ;
           
           Hf = figure;
           
           for iangle=1:length(Angles)
           % for given angle, get proper decimation list :
           Iextract = find(Iangles == iangle) ;
           
           imagesc(obj.decimation(Iextract),obj.z*1e3,obj.R(:,Iextract))
           xlabel('decimation')
           ylabel('ct (mm)')
           ylim(1e3*obj.L)
           title(['Traces for',num2str(Angles(iangle))])
           colorbar
           drawnow
           
           end
            
        end
        
        function [] = Show_F_R(obj)
            
           % find number of different angular value :
           [Angles,~,Iangles] = unique(obj.theta) ;
           
           Hf = figure;
           
           for iangle=1:length(Angles)
           % for given angle, get proper decimation list :
           Iextract = find(Iangles == iangle) ;
                      
           % loop on decimation values to reconstruct fourier composant           
           imagesc(obj.decimation(Iextract),obj.fz*1e-3,abs( obj.F_R(:,Iextract) ) )
           xlabel('decimation')
           ylabel('fz (mm-1)')
           title(['Traces for',num2str(Angles(iangle)*180/pi)])
           colorbar
           drawnow
           
           end
     

        end
        
        function Iout = GetFourier(obj,Iin,decimation)
            
            I0 = obj.N/2 + 1 ;
            
            Iout = zeros(obj.N,obj.N) ;
            Iout(:,I0 + decimation) = Iin ;
            Iout(:,I0 - decimation) = conj(flipud(Iin)) ;
            Iout(:,I0) = Iout(:,I0)/2 ;
            
            
        end
        
        function [Iout,theta,decim] = AddSinCos(obj,Iin)
            
           % find number of unique couple values:
           ScanParam = [obj.decimation(:),obj.theta(:)];
           [Angles,ia,ib] = unique(ScanParam,'rows') ;
           % ia : index of singleton representing group
           % ib : index list of goups

           theta = Angles(:,2)  ; % same size as ia 
           decim = Angles(:,1)  ; % same size as ia 
           
           % divide the second dimension by the number of phases = 4
           % accounting for single zero order
           Iout = zeros(size(Iin,1),1+(size(Iin,2)-1)/4) ;
           
           Iout(:,1) = Iin( : , 1 ) ;
           % starting loop after 0 order
%                        fx = (26.0417)*decim(i_decimate);
%                        Neff = 1/(fx*(0.2*1e-3));
%                        fxeff   = 1/(Neff*1e-3);
%                        
           for i = 2:length(ia)
               
           Isimilardecimate = sort( find(ib == i) ) ;
           
           % cos = Iin(:,Isimilardecimate(1)) - Iin(:,Isimilardecimate(2))
           % sin = Iin(:,Isimilardecimate(3)) - Iin(:,Isimilardecimate(4))
           
           % sin-cos sequence
          % Iout(:,i) = Iin(:,Isimilardecimate(1)) - 1i*Iin(:,Isimilardecimate(2)) ;
                   
           % own sequence
           Iout(:,i) = ( Iin(:,Isimilardecimate(1)) - Iin(:,Isimilardecimate(2)) )...
                     - 1i*( Iin(:,Isimilardecimate(3)) - Iin(:,Isimilardecimate(4)) );
                   
                   
          % Iout(:,i) = hilbert(Iin(:,Isimilardecimate(1)) - Iin(:,Isimilardecimate(2)) );    
            Iout(:,i) = Iout(:,i)/2 ;   
           end       
           
        end
                
        function Fm = Fmax(obj)
            dt = obj.ct(2) - obj.ct(1) ;
            Fm = 1/dt; % in m-1
        end
        
        

    
    end

end
