classdef AOmodulator
    %AOMODULATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        N       % number of point
        Fe      % Sampling Frequency
        Event   % Event Buffer
    end
    
    methods
        
        function obj = UpdateEventNumber(obj,Nevent)
        obj.Nevent = Nevent ;    
        end
        
        function obj = AOmodulator(tau_c,Fe)
            %AOMODULATOR Construct an instance of this class
            %   Detailed explanation goes here
            N = floor(tau_c*Fe);
            obj.Fe = Fe;
            obj.N = N;
        end
        
        function Event = BuildOF(f0,Nevent)
            t = (0:(obj.N-1))/(obj.Fe);
            Event = repmat( exp(-1i*2*pi*f0*t(:)) , 1 , Nevent );
        end
        function Event = BuildJM(obj,f0,nuZ0,c,Bascule,ScanParam)
            
            t = (0:(obj.N-1))/(obj.Fe);
            
            Nevent = size(ScanParam,1);
            
            Event = zeros(obj.N,Nevent);
            
            for nscan=1:Nevent
            nuZ = (ScanParam(nscan,1)*nuZ0);   % mm-1->m-1
            fz = c*nuZ ; %Hz
            Event(:,nscan) = exp(-1i*2*pi*f0*t(:));
            
                if strcmp(Bascule,'on')
                        Am = mod(ceil(2*fz*t(:)),4);
                        Am(Am==2)=0;
                        Am(Am==3)=-1;
                        Event(:,nscan) = exp(-1i*2*pi*f0*t(:)).*Am;
                else
                        if ScanParam(nscan,1)==0
                           Event(:,nscan) = exp(-1i*2*pi*f0*t(:)) ;
                        else
                           Event(:,nscan) = exp(-1i*2*pi*f0*t(:)).*( sin( 2*pi*fz*(t(:)) )> 0 );   
                        end    
                end
                
            end
        end
        function obj = AOsequenceGenerate(obj,param,ScanParam)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            FOC_type = param.FOC_type ;
            
            switch FOC_type
                
                case 'OF'
                obj.Event = BuildOF(param.f0,ScanParam) ;
                case 'JM'
                obj.Event = BuildJM(obj,param.f0,param.nuZ0,param.c,param.Bascule,ScanParam) ;
                    
            end
              
        end
        
        
        
        
        
        
    end
end
