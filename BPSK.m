clear all;
clc;

monte_carlo = Monte_Carlo();
monte_carlo.set_number_of_samples(10000000);
monte_carlo.set_threshold(0);
monte_carlo.set_modulation_scheme('BPSK')
monte_carlo.plot_BER_vs_SNR();


