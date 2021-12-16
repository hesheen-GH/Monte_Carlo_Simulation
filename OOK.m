clear all;
clc;

monte_carlo = Monte_Carlo();
monte_carlo.set_number_of_samples(100000);
monte_carlo.set_modulation_scheme('OOK')
monte_carlo.plot_BER_vs_SNR();
