function [Sim] = setup_sim(varargin)
    model 	=   varargin{1};
        % =============================================================== %
        try Sim     =   varargin{2};
            if ~isstruct(Sim); Sim = []; end
        catch; Sim = [];
        end
        % -----------------------------------------------------------------
        T1      =   293;      % Inlet temperature (m/s)
        p2      =   101300;   % Outlet pressure (Pa)
        % -----------------------------------------------------------------
        if contains(model, 'low')
            u1      =   0.001;       % Inlet velocity (m/s) - LOM 0.1
            R_out	=   -1;       % Reflection coefficient in open BC
            R_in	=   -1;       % Reflection coefficient in open BC
            Qbar    =   0;    % 100000 Heat release rate (W) - check how T2 changes
        elseif contains(model, 'high')
            u1      =   10;       % Inlet velocity (m/s) - LOM 0.1
            R_out   =   -0.999;       % Reflection coefficient in open BC
            R_in    =   -0.999;       % Reflection coefficient in open BC
            Qbar    =   20000;    % 100000 Heat release rate (W) - check how T2 changes
        else
            error('define high or low order model')
        end
        % -----------------------------------------------------------------
        % Load the geometry
        Geom	=   fn_define_geometry(2);
        % Define boundary conditions
        Geom.BC1    =   'open';
        Geom.BC2    =   'open';
        % -----------------------------------------------------------------
        % Compute the mean flow:
        Mean        =   fn_mean_flow(u1,T1,p2,Qbar,Geom,R_in,R_out);  
        % -----------------------------------------------------------------
        if contains(model, 'G_eqn')
            fprintf('with G equation. \n') 
            Mean.Heat_law   =   'G_eqn';
        else  
            if nargin > 2 
                Mean.beta = varargin{end-1};
                Mean.Tau = varargin{end};
            else
                Mean.beta       =   1E6;
                Mean.Tau        =   1E-3 ;                                     % Matthiew Yoko - tau order 2E-3
            end
            Mean.kappa      =   3E4; 
            % -------------------------------------------------------------
            if contains(model, 'tan');      Mean.Heat_law   =   'atan';
            elseif contains(model, 'sqrt')     
                if contains(model, 'mod');  Mean.Heat_law   =   'sqrt_mod';
                else;                       Mean.Heat_law   =   'sqrt';
                end
            elseif contains(model,'cub');   Mean.Heat_law   =   'cubic';
            end
        end
        % -----------------------------------------------------------------
        Sim     =   set_forcing_measurement(Sim);
        Sim.dt  =   1/10000;%1/10007;               % Time step of simulation
        if Sim.Measurement.Fs > 1/Sim.dt
            error(['Lower sampling freq. below: ',num2str(1/Sim.dt),' Hz'])
        end
        Sim.Mean 	=   Mean;
        Sim.Geom 	=   Geom;
end

% ======================================================================= %
function Sim  = set_forcing_measurement(Sim)    
    % Define Forcing Conditions:
    Forcing.Speaker             =   'OFF';
    Forcing.Speaker_Downstream  =   'OFF';
    % Define measurement parameters
    Measurement.Fs      =   10000; 	% Sampling frequency (Hz)    
    Measurement.Time    =   5;     % Length of the measurements(s)
    Measurement.PMT     =   'ON';   % Photomultiplier:    
    Measurement.Mic     =   'ON';   % Differential Microphones:
    Measurement.HWA     =   'OFF';	% Hot wire anemometry:
    Measurement.Mic_Pos	=   [-1, -0.7,-0.2, 0, 0.35, 0.6]; % (m)    
    % Store
    Sim.Forcing      =   Forcing;
    Sim.Measurement  =   Measurement;
end