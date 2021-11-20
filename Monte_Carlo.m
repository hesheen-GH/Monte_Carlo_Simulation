classdef Monte_Carlo < handle
    
    properties %(Access = private)
        N = 1000 %default number of samples
        noise_power = 1; %default, 0 dB
        modulation_scheme;
        sent_bits;
        recieved_bits;
        baseband_signal;
        AWGN;
        Rx_signal;
        threshold;
        num_of_bit_errors;
        num_of_symbol_errors;
        BER;
        SER;
        Q_sent_bits;
        I_sent_bits;
        
    end
    
    methods 
        
        function obj = set_modulation_scheme(obj,scheme)
            obj.modulation_scheme = scheme;
        end 
        
        function scheme = get_modulation_scheme(obj)
            scheme = obj.modulation_scheme;
        end 
        
        function BER = get_BER(obj)
            BER = obj.BER;
        end 
        
        function obj = set_threshold(obj,threshold)
            obj.threshold = threshold;
        end 
        
        function threshold = get_threshold(obj)
            threshold = obj.threshold;
        end 
        
        function obj = set_noise_power(obj,power)
            obj.noise_power = power;
        end 
        
        function power = get_noise_power(obj)
            power = obj.noise_power;
        end
        
        function obj = set_number_of_samples(obj,N)
            obj.N = N;
        end 
        
        function N = get_number_of_samples(obj)
            N = obj.N;
        end 
        
        function obj = generate_2_level_RandomBits(obj)
            %generates bits 1,0 with equal probability
            obj.sent_bits = round(rand(1,obj.N));       
        end 
        
        
        function obj = generate_Quadrature_Inphase_bits(obj)
            %generate even,odd Q,I
            obj.Q_sent_bits = obj.sent_bits(2:2:end);
            obj.I_sent_bits = obj.sent_bits(1:2:end);
              
        end 
            
        
        function obj = generate_baseband_signal(obj)
            %generates baseband BPSK signal +1 or -1
            
            switch obj.modulation_scheme
                case 'BPSK'
                    obj.baseband_signal = 2.*obj.sent_bits-1;
                
                %for the same energy per bit, the relation between OOK and
                %BPSK is A_ook  = sqrt(2)*A_bpsk (refer to claude's notes)
                case 'OOK'
                    obj.baseband_signal = sqrt(2).*obj.sent_bits;
                    
                case 'QPSK'
                    %generate phasor
                    obj.baseband_signal =  (2.*obj.I_sent_bits-1)+i*(2.*obj.Q_sent_bits-1);
                 
                    
            end 
              
        end 
        
        
        function obj = generate_AWGN(obj)
            %awgn generation
            rng(0,'twister');
            
            switch obj.modulation_scheme
                case 'BPSK'
                   obj.AWGN = sqrt(obj.noise_power)*randn(1,obj.N);  
                   
                case 'OOK'
                   obj.AWGN = sqrt(obj.noise_power)*randn(1,obj.N);  

                case 'QPSK'
                   obj.AWGN = sqrt(obj.noise_power)*randn(1,obj.N/2) + ...
                   i*sqrt(obj.noise_power)*randn(1,obj.N/2);
                   
            end 

                    
            
        end 
        
        function obj = generate_recieved_signal(obj)
            %add signal with awgn
            obj.Rx_signal = obj.baseband_signal + obj.AWGN;
        end 
        
        function obj = reciever(obj)
            %output of reciever and deciding binary output based on threshold
            %if signal == threshold, randomly choose 0 or 1
            
            switch obj.modulation_scheme
                
                case 'BPSK'
                    threshold_signals = obj.Rx_signal==obj.threshold;
                    r = 2*randi([0 1],nnz(threshold_signals),1,1)-1;
                    obj.Rx_signal(threshold_signals)=r;
                    obj.recieved_bits = obj.Rx_signal > obj.threshold;
                
                case 'OOK'
                    threshold_signals = obj.Rx_signal==obj.threshold;
                    r = sqrt(2)*randi([0 1],nnz(threshold_signals),1,1);
                    obj.Rx_signal(threshold_signals)=r;
                    obj.recieved_bits = obj.Rx_signal > obj.threshold;
                    
                case 'QPSK'
                    
                    constellation_points = [sqrt(2)*exp(i*pi/4),sqrt(2)*exp(i*3*pi/4), ...
                        sqrt(2)*exp(i*5*pi/4),sqrt(2)*exp(i*7*pi/4)];
                    
                    obj.recieved_bits = [];
                    
                    for k=1:length(obj.Rx_signal)
                        
                        distance = abs(constellation_points-obj.Rx_signal(k));
                        [min_distance, index] = min(distance);
                        
                        switch index
                            case 1
                                obj.recieved_bits(end+1) = 1;
                                obj.recieved_bits(end+1) = 1;
                                
                            case 2
                                obj.recieved_bits(end+1) = 0;
                                obj.recieved_bits(end+1) = 1;
                                
                            case 3
                                obj.recieved_bits(end+1) = 0;
                                obj.recieved_bits(end+1) = 0;
                                
                            case 4
                                obj.recieved_bits(end+1) = 1;
                                obj.recieved_bits(end+1) = 0;

                        end 
                        
                    end 
                        
                
                 
            end
            
            
            
        end 
        
        function obj = symbol_error_counter(obj)
            
            %count every 2 bits = symbol
            
            obj.num_of_symbol_errors = sum((string(obj.sent_bits(1:2:end)) ... 
                + string(obj.sent_bits(2:2:end))) ~= (string(obj.recieved_bits(1:2:end)) ... 
                + string(obj.recieved_bits(2:2:end))));
               
        end 
        
        
        function obj = compute_symbol_error_probability(obj)
            
            obj.SER = (1/(obj.N/2))*obj.num_of_symbol_errors;
        end 
        
        function obj = bit_error_counter(obj)
            %counts number of errors by comparing sent with recieved bits
            obj.num_of_bit_errors = sum(obj.sent_bits~=obj.recieved_bits);     
        end 
      
        function obj = compute_bit_error_probability(obj)
            obj.BER = (1/obj.N)*obj.num_of_bit_errors;
        end 
        
        function BER_theoretical = compute_theoretical_BER(obj,SNR)
            
            switch obj.modulation_scheme
                   
                case 'BPSK'
                    BER_theoretical = qfunc(sqrt(2*10.^(SNR/10)));
                        
                case 'OOK'
                    BER_theoretical = qfunc(sqrt(10.^(SNR/10)));
                        
                case 'QPSK'
                    BER_theoretical = qfunc(sqrt(2*10.^(SNR/10)));
            end 
            
        end 
        
        
        function SER_theoretical = compute_theoretical_SER(obj,SNR)
            
            switch obj.modulation_scheme
                     
                case 'QPSK'
                    SER_theoretical = erfc(sqrt(10.^(SNR/10)))- ...
                        (1/4)*(erfc(sqrt(10.^(SNR/10))))^2;
            end 
            
        end 
        
        function obj = plot_BER_vs_SNR(obj)
            
            SNR = 0:1:10; %in dB
            BER_experimental = [];
            BER_theoretical = [];
            SER_experimental = [];
            SER_theoretical = [];
            
            for i=1:length(SNR)
                
                obj.noise_power = 1/(2*10.^(SNR(i)/10)); %assuming Eb = 1;
                obj.generate_2_level_RandomBits();
                obj.generate_Quadrature_Inphase_bits();
                obj.generate_baseband_signal();
                obj.generate_AWGN();
                obj.generate_recieved_signal();
                obj.reciever()
                obj.symbol_error_counter();
                obj.compute_symbol_error_probability();
                obj.bit_error_counter();
                obj.compute_bit_error_probability();
                
                switch obj.modulation_scheme
                
                    case 'QPSK'
                    
                        SER_experimental(i) = obj.SER;
                        SER_theoretical(i) = obj.compute_theoretical_SER(SNR(i));
                    
                end 
                
                BER_experimental(i) = obj.BER;
                BER_theoretical(i) = obj.compute_theoretical_BER(SNR(i));
                
            end 
              
            figure;
            semilogy(SNR,BER_experimental);
            ylim([10^-6 0.1]);
            hold on;
            semilogy(SNR,BER_theoretical);
            hold on;
            
            switch obj.modulation_scheme
                
                case 'QPSK'
                
                    semilogy(SNR,SER_experimental);
                    hold on;
                    semilogy(SNR,SER_theoretical);
                    legend(string(obj.modulation_scheme) + ' Experimental BER', string(obj.modulation_scheme) + ' Theoretical BER' , ...
                        string(obj.modulation_scheme) + ' Experimental SER', string(obj.modulation_scheme) + ' Theoretical SER'); 
                    
                otherwise 
                    legend(string(obj.modulation_scheme) + ' Experimental BER', string(obj.modulation_scheme) + ' Theoretical BER');


            end 
                       
            hold off;
               
        end 
        
        
    end 
    
    
end 