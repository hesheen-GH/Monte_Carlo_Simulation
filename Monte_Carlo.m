classdef Monte_Carlo < handle
    
    properties %(Access = private)
        N = 1000 %default number of samples
        noise_power = 1; %default, 0 dB
        sent_bits;
        recieved_bits;
        baseband_signal;
        AWGN;
        Rx_signal;
        threshold;
        num_of_errors;
        BER;
        
    end
    
    methods 
        
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
        
        function obj = generate_baseband_signal(obj,scheme)
            %generates baseband BPSK signal +1 or -1
            
            switch scheme
                case 'BPSK'
                    obj.baseband_signal = 2.*obj.sent_bits-1;
                
                %for the same energy per bit, the relation between OOK and
                %BPSK is A_ook  = sqrt(2)*A_bpsk (refer to claude's notes)
                case 'OOK'
                    obj.baseband_signal = sqrt(2).*obj.sent_bits; 
                    
            end 
              
        end 
        
        function obj = generate_AWGN(obj)
            %awgn generation
            rng(0,'twister');
            obj.AWGN = sqrt(obj.noise_power)*randn(1,obj.N);  
        end 
        
        function obj = generate_recieved_signal(obj)
            %add signal with awgn
            obj.Rx_signal = obj.baseband_signal + obj.AWGN;
        end 
        
        function obj = reciever(obj)
            %output of reciever and deciding binary output based on threshold
            %if signal == threshold, randomly choose 0 or 1
            threshold_signals = obj.Rx_signal==obj.threshold;
            r = 2*randi([0 1],nnz(threshold_signals),1,1)-1;
            obj.Rx_signal(threshold_signals)=r;
                        
               %for i=1:size(signal)
               %    if signal(i) == 0
               %        signal(i) = 2*randi([0 1])-1;
               %    end 
               %end 
           
            obj.recieved_bits = obj.Rx_signal > obj.threshold;
        end 
        
        function obj = error_counter(obj)
            %counts number of errors by comparing sent with recieved bits
            obj.num_of_errors = sum(obj.sent_bits~=obj.recieved_bits);     
        end 
        
        function obj = compute_error_probability(obj)
            obj.BER = (1/obj.N)*obj.num_of_errors;
        end 
        
        function obj = plot_BER_vs_SNR(obj,scheme)
            
            SNR = 0:1:10; %in dB
            BER_experimental = [];
            BER_theoretical = [];
            
            for i=1:length(SNR)
                
                
                
                obj.noise_power = 1/(2*10.^(SNR(i)/10)); %assuming Eb = 1;
                obj.generate_2_level_RandomBits();
                obj.generate_baseband_signal(scheme);
                obj.generate_AWGN();
                obj.generate_recieved_signal();
                obj.reciever();
                obj.error_counter();
                obj.compute_error_probability();
                BER_experimental(i) = obj.BER;
                
                switch scheme
                   
                    case 'BPSK'
                        BER_theoretical(i) = qfunc(sqrt(2*10.^(SNR(i)/10)));
                        
                    case 'OOK'
                        BER_theoretical(i) = qfunc(sqrt(10.^(SNR(i)/10)));
                end 
            end 
              
            figure;
            semilogy(SNR,BER_experimental);
            ylim([10^-6 0.1]);
            hold on;
            semilogy(SNR,BER_theoretical);
            legend(string(scheme) + ' Experimental BER', string(scheme) + ' Theoretical BER');
            hold off;
               
        end 
        
    end 
    
    
end 