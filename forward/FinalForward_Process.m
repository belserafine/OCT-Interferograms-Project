%%FINAL Forward OCT MATLAB Process
clear variables
clc

%OCT Pipeline
%Step 1: Load the OCT data
files = dir('forward_pipeline_outputs_scaled*.mat'); %get the mat files in the 1 folder it is located in

for i = 1:length(files)
        filename= files(i).name;
        octData = load(filename);
        bscan_data_real = octData.raw_signals_real;
        bscan_data_im = octData.raw_signals_im;
        bscan_data = bscan_data_real + 1i .* bscan_data_im; % Combine real and imaginary parts
    
%raw_signals = 768 x 512 complex double 
%column is num of data points in 1 A line (496)(there are 768 a lines)
%[row, column]

%bscan_data = bscan_data.;   % <-- MAKE IT MATCH REVERSE
[num_ascans, num_depth] = size(bscan_data); % [768x512]
signal_length = num_depth;
%need to make a loop: for i = 1:NumberofAscans
%then implement below formulas for each A scan at a time

% Define Sampling Grid
%make sure to run once

 tvec = octData.tvec;
% kclk = 0.05 * rand(1,signal_length) - 0.025;
% kclk = tvec + kclk;
% kclk(1) = 0;


kclk = octData.kclk;

% OCT PARAMETERS
maxmin      = [800e-9, 900e-9];
a_coeffs    = [0, -4 * 10^-11, 0];
mynoise = 0.01 * randn(1, signal_length); % gaussian/white noise with mean = 0, var = 0.01
mybg = octData.mybg;
% STORAGE
%og_sig  = complex(zeros(signal_length, num_ascans));
b_recon = complex(zeros(num_ascans, signal_length));
% mybg = zeros(signal_length,1);
% mybg = 100000 * sin(tvec * 0.003);



    
    % FORWARD PIPELINE (reconstruct)
    tic
    for i = 1:num_ascans %(i = 1:768)
        raw = bscan_data(i, :); %(i, :) is going through every A scan and getting all its data points being 512
        s1 = bg_sub_f(raw);               % Remove background
        s2 = k_lin_f(s1, tvec, kclk);           % Linearize k-space
        s3 = disp_c_f(s2, maxmin, a_coeffs);   % Correct dispersion
        s4 = fft_f(s3);                         % FFT to spatial domain
        s5 = log_sc_f(s4);                      % Log scale magnitude
        s6 = gs_map_f (s5);
        b_recon(i, :) = s6;
    end
    toc

end



    %Functions used
    
    % Background subtraction
    function output = bg_sub_f(input)
        output = input - mean(input);
    end
    
    % function output = bg_sub_f(input, bg)
    %     output = input - bg;
    % end
    
    % Dispersion compensation
    function output = disp_c_f(input, maxmin, a_coeffs)
        % Forward: Remove dispersion (multiply by opposite phase)
        N = length(input);
        lambda = linspace(maxmin(1), maxmin(2), N);
        k = 2*pi ./ lambda;
        k0 = mean(k);
        phi = a_coeffs(2)*(k-k0).^2 + a_coeffs(3)*(k-k0).^3;
        output = input .* exp(-1i * phi);
    
    
    end
    
    %send cosine of phi and sin and phi
    
    
    
    % k linearization
    function output = k_lin_f(nonlinear_y, linear_x, nonlinear_x)
        % Forward: Map from nonlinear k-clock to linear k-space
         % assert(length(nonlinear_y) == length(nonlinear_x), ...
         %     'k_lin_f: signal and source grid must match');
        output = interp1(nonlinear_x, nonlinear_y, linear_x, 'cubic');
    end
    
    
    % FFT
    function output = fft_f(input)
        % Forward: FFT to spatial domain
        output = fft(input);
    end
    
    
    % lOG Scaling
    function output = log_sc_f(input)
        % Forward: Convert magnitude to dB scale
        % Input: complex data from FFT
        % Output: real dB magnitude (magnitude domain)
        %epsv = 1e-12;   
        output = 20*log10((input ));
    end
    
    
    % Grey scale mapping
    function output = gs_map_f(input)
     min_val = min(input);
        max_val = max(input);
    
        output = ((input - min_val) / (max_val - min_val)) *255;
        
      
    %Quantized_Log_Ref = ((A_Scan_DB - globalMin)/ (globalMax-globalMin)).*255; %a bit of 8 bits corresponds to 256 possible values. Modelling an OCT signal acquired by an 8 bit analog to digital converter makes the signal values
       
    end
    
    
 
    
    % Display 
    figure(1)
    %imagesc(20*log10(abs(b_recon +  1e-12)))
    % threshold = 1e-80;                  % values below this are considered background
    % b_recon(abs(b_recon) < threshold) = 0;
    b_recon_smooth = imgaussfilt(abs(b_recon), 0.2); % sigma = 1
    imagesc((b_recon_smooth).')
    colormap(gray)
     


