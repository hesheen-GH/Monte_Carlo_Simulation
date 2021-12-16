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
        num_of_symbol_errors = [];
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
                 
                case '16-QAM'
                    
                    obj.baseband_signal = []; 
                    quad_bits =(string(obj.sent_bits(1:4:end))+ string(obj.sent_bits(2:4:end)) ... 
                            + string(obj.sent_bits(3:4:end))+ string(obj.sent_bits(4:4:end)));  
                    
                    for k = 1:length(quad_bits) 
                        
                        switch(quad_bits(k))  
                            case '0000'
                                obj.baseband_signal(end+1) = -3+3i;
                            
                            case '0001'
                                obj.baseband_signal(end+1) = -3+1i;
                                
                            case '0010'
                                obj.baseband_signal(end+1) = -3-3i;
                                
                            case '0011'
                                obj.baseband_signal(end+1) = -3-1i;
                                
                            case '0100'
                                obj.baseband_signal(end+1) = -1+3i;
                            
                            case '0101'
                                obj.baseband_signal(end+1) = -1+1i;    
                                
                            case '0110'
                                obj.baseband_signal(end+1) = -1-3i;
                                
                            case '0111'
                                obj.baseband_signal(end+1) = -1-1i;
                                
                            case '1000'
                                obj.baseband_signal(end+1) = 3+3i;
                                
                            case '1001'
                                obj.baseband_signal(end+1) = 3+1i;
                                
                            case '1010'
                                obj.baseband_signal(end+1) = 3-3i;
                                
                            case '1011'
                                obj.baseband_signal(end+1) = 3-1i;
                                
                            case '1100'
                                obj.baseband_signal(end+1) = 1+3i;
                                
                            case '1101'
                                obj.baseband_signal(end+1) = 1+1i;
                                
                            case '1110'
                                obj.baseband_signal(end+1) = 1-3i;
                                
                            case '1111'
                                obj.baseband_signal(end+1) = 1-1i;
                                
                        end
                    end               
            end     
        end 
        
        
        function obj = generate_AWGN(obj)
            %awgn generation
            rng(0,'twister');
            
            switch obj.modulation_scheme
                case 'BPSK'
                   obj.AWGN = sqrt(obj.noise_power).*randn(1,obj.N);  
                   
                case 'OOK'
                   obj.AWGN = sqrt(obj.noise_power).*randn(1,obj.N);  

                case 'QPSK'
                   obj.AWGN = sqrt(obj.noise_power).*randn(1,obj.N/2) + ...
                   i*sqrt(obj.noise_power).*randn(1,obj.N/2);
               
                case '16-QAM'
                   obj.AWGN = sqrt(obj.noise_power).*randn(1,obj.N/4) + ...
                   i*sqrt(obj.noise_power).*randn(1,obj.N/4);    
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
                    
                    constellation_points = [-1;1];
                    obj.recieved_bits = [];
                    distance = abs(bsxfun(@minus,constellation_points,reshape(obj.Rx_signal.',[1,size(obj.Rx_signal.')])));
                    [min_distance, index] = min(distance);
                    
                    obj.recieved_bits = dec2bin(index-1,1);
                    obj.recieved_bits = reshape(obj.recieved_bits',[1 size(obj.recieved_bits,1)*size(obj.recieved_bits,2)]);
                    obj.recieved_bits = num2cell(obj.recieved_bits(:))';
                    obj.recieved_bits = sscanf(sprintf(' %s',obj.recieved_bits{:}),'%f',[1,Inf]);
                    [row,column,height] = size(index);
                    
                    obj.recieved_bits = reshape(obj.recieved_bits,column,[]).';
                                 
                case 'OOK'
                    
                    constellation_points = [0;sqrt(2)];
                    obj.recieved_bits = [];
                    distance = abs(bsxfun(@minus,constellation_points,reshape(obj.Rx_signal.',[1,size(obj.Rx_signal.')])));
                    [min_distance, index] = min(distance);
                    
                    obj.recieved_bits = dec2bin(index-1,1);
                    obj.recieved_bits = reshape(obj.recieved_bits',[1 size(obj.recieved_bits,1)*size(obj.recieved_bits,2)]);
                    obj.recieved_bits = num2cell(obj.recieved_bits(:))';
                    obj.recieved_bits = sscanf(sprintf(' %s',obj.recieved_bits{:}),'%f',[1,Inf]);
                    [row,column,height] = size(index);
                    
                    obj.recieved_bits = reshape(obj.recieved_bits,column,[]).';
                    
                case 'QPSK'
                      
                    constellation_points = [-1-i;-1+i;1-i;1+i];
                    
                    obj.recieved_bits = [];
                    
                    
                    distance = abs(bsxfun(@minus,constellation_points,reshape(obj.Rx_signal.',[1,size(obj.Rx_signal.')])));

                    [min_distance, index] = min(distance);
                    
                    obj.recieved_bits = dec2bin(index-1,2);
                    obj.recieved_bits = reshape(obj.recieved_bits',[1 size(obj.recieved_bits,1)*size(obj.recieved_bits,2)]);
                    obj.recieved_bits = num2cell(obj.recieved_bits(:))';
                    obj.recieved_bits = sscanf(sprintf(' %s',obj.recieved_bits{:}),'%f',[1,Inf]);
                    
                    [row,column,height] = size(index);
                    
                    obj.recieved_bits = reshape(obj.recieved_bits,2*column,[]).';
                                             
                case '16-QAM'
                    
                    constellation_points = [-3+3i;-3+1i;-3-3i;-3-1i;-1+3i;-1+1i; ...
                        -1-3i;-1-1i;3+3i;3+1i;3-3i;3-1i;1+3i;1+1i;1-3i;1-1i];
                                
                    obj.recieved_bits = [];
                    
                    distance = abs(bsxfun(@minus,constellation_points,reshape(obj.Rx_signal.',[1,size(obj.Rx_signal.')])));

                    [min_distance, index] = min(distance);
                    
                    obj.recieved_bits = dec2bin(index-1,4);
                    obj.recieved_bits = reshape(obj.recieved_bits',[1 size(obj.recieved_bits,1)*size(obj.recieved_bits,2)]);
                    obj.recieved_bits = num2cell(obj.recieved_bits(:))';
                    obj.recieved_bits = sscanf(sprintf(' %s',obj.recieved_bits{:}),'%f',[1,Inf]);
                    
                    [row,column,height] = size(index);
                    
                    obj.recieved_bits = reshape(obj.recieved_bits,4*column,[]).';
            end   
        end 
        
        function obj = symbol_error_counter(obj)
            
            %count every 2 bits = symbol
            
            switch obj.modulation_scheme
            
                case 'QPSK'
                    
                    obj.num_of_symbol_errors = bitxor(obj.sent_bits,obj.recieved_bits);
                    symbols = string(obj.num_of_symbol_errors(:,1:2:end)) + string(obj.num_of_symbol_errors(:,2:2:end));
                                        
                    obj.num_of_symbol_errors = sum(count(symbols,'11'),2) + ...
                        sum(count(symbols,'10'),2) + sum(count(symbols,'01'),2);
                
                case '16-QAM'
                    obj.num_of_symbol_errors = bitxor(obj.sent_bits,obj.recieved_bits);
                    symbols = string(obj.num_of_symbol_errors(:,1:4:end)) + string(obj.num_of_symbol_errors(:,2:4:end)) ...
                         + string(obj.num_of_symbol_errors(:,3:4:end)) + string(obj.num_of_symbol_errors(:,4:4:end));
                                        
                    obj.num_of_symbol_errors = sum(count(symbols,'0001'),2) + ...
                        sum(count(symbols,'0010'),2) + sum(count(symbols,'0011'),2) + ...
                        sum(count(symbols,'0100'),2) + sum(count(symbols,'0101'),2) + ...
                        sum(count(symbols,'0110'),2) + sum(count(symbols,'0111'),2) + ...
                        sum(count(symbols,'1000'),2) + sum(count(symbols,'1001'),2) + ...
                        sum(count(symbols,'1010'),2) + sum(count(symbols,'1011'),2) + ...
                        sum(count(symbols,'1110'),2) + sum(count(symbols,'1111'),2);
            end 

        end 
        
        
        function obj = compute_symbol_error_probability(obj)
            
            switch obj.modulation_scheme
                
                case 'QPSK'
                    obj.SER = (1/(obj.N/2)).*obj.num_of_symbol_errors;
                    
                case '16-QAM'
                    obj.SER = (1/(obj.N/4)).*obj.num_of_symbol_errors;  
            end 
            
        end 
        
        function obj = bit_error_counter(obj)
            %counts number of errors by comparing sent with recieved bits
            
            obj.num_of_bit_errors = bitxor(obj.sent_bits,obj.recieved_bits);
            obj.num_of_bit_errors = sum(obj.num_of_bit_errors,2);

        end 
      
        function obj = compute_bit_error_probability(obj)
            obj.BER = (1/obj.N).*obj.num_of_bit_errors;
        end 
        
        function BER_theoretical = compute_theoretical_BER(obj,SNR)
            
            switch obj.modulation_scheme
                   
                case 'BPSK'
                    BER_theoretical = qfunc(sqrt(2*10.^(SNR/10)));
                        
                case 'OOK'
                    BER_theoretical = qfunc(sqrt(10.^(SNR/10)));
                        
                case 'QPSK'
                    BER_theoretical = qfunc(sqrt(2*10.^(SNR/10)));
                
                case '16-QAM'
                    BER_theoretical = (4/log2(16))*(1-1/sqrt(16))*qfunc(sqrt(((3*log2(16))/(16-1))*10.^(SNR/10)));
            end 
            
        end 
        
        
        function SER_theoretical = compute_theoretical_SER(obj,SNR)
            
            switch obj.modulation_scheme
                     
                case 'QPSK'
                    SER_theoretical = erfc(sqrt(10.^(SNR/10)))- ...
                        (1/4)*(erfc(sqrt(10.^(SNR/10)))).^2; %Es = 2Eb
                
                case '16-QAM'
                    SER_theoretical = (3/2)*erfc(sqrt((4/10)*10.^(SNR/10))); %approximation Es=4Eb
                      
            end 
            
        end 
        
        function obj = plot_BER_vs_SNR(obj)
            
            SNR = 0:0.1:20; %in dB
            BER_theoretical = [];
            SER_theoretical = [];
            
            obj.generate_2_level_RandomBits();
            obj.generate_Quadrature_Inphase_bits();
            obj.generate_baseband_signal();
            
            switch obj.modulation_scheme
                   
                    case '16-QAM'
                        % Eb = Es/log2(M), Es = 10 for 16-QAM
                        obj.noise_power = (2.5./(2*10.^(SNR/10)))';    
                     
                    otherwise
                        %For QPSK, Es = 2, Eb = 1
                        obj.noise_power = (1./(2*10.^(SNR/10)))'; %assuming Eb=1
                                 
            end
            
            obj.generate_AWGN();
            obj.generate_recieved_signal();
            obj.reciever()
            obj.symbol_error_counter();
            obj.compute_symbol_error_probability();
            obj.bit_error_counter();
            obj.compute_bit_error_probability();
            
            BER_theoretical = obj.compute_theoretical_BER(SNR);
            
            if (strcmp(obj.modulation_scheme,'QPSK') || strcmp(obj.modulation_scheme,'16-QAM'))
            
                SER_theoretical = obj.compute_theoretical_SER(SNR);
            
            end
            
            figure;
            semilogy(SNR,obj.BER','LineWidth',1);
            ylim([10^-6 0.1]);
            xlim([0 20]);
            hold on;
            semilogy(SNR,BER_theoretical,'LineWidth',1);
            hold on;
            
            if (strcmp(obj.modulation_scheme,'QPSK') || strcmp(obj.modulation_scheme,'16-QAM'))

                
                semilogy(SNR,obj.SER','LineWidth',1);
                hold on;
                semilogy(SNR,SER_theoretical,'LineWidth',1);              
                legend(string(obj.modulation_scheme) + ' Experimental BER', string(obj.modulation_scheme) + ' Theoretical BER' , ...
                string(obj.modulation_scheme) + ' Experimental SER', string(obj.modulation_scheme) + ' Theoretical SER'); 
                title(string(obj.modulation_scheme) + ' BER and Symbol Error Rate (SER) in AWGN Channel')    
            else 
                legend(string(obj.modulation_scheme) + ' Experimental BER', string(obj.modulation_scheme) + ' Theoretical BER');
                title(string(obj.modulation_scheme) + ' BER in AWGN Channel')
            end
            
            xlabel('SNR: Eb/No [dB]');
            ylabel('Probability');
            grid on;
            hold off;
            
        end 
    end
end 