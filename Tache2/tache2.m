addpath('..');
clear all
close all
clc


%% Paramètres
Nfft = 256;         % taille FFT
Nb   = 1000;      % nombre de bits
Fe   = 20e6;        % fréquence d'échantillonnage
Te   = 1/Fe;        
Ts   = 1e-6;        % durée symbole
Fse  = Ts/Te;       % suréchantillonnage (20 ici)

%% Définition des impulsions PPM
p_ref=[ones(1,Fse/2)];
p1 = [p_ref , 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0
p  = 0.5 * (p0 - p1);        

%% Génération du signal aléatoire
bits = randi([0 1], 1, Nb);
sl   = genere_signal(bits, p0, p1); 

%% Estimation de la DSP par Welch
sl_welch= Mon_Welch(sl, Nfft, Fe);
freq=(-Nfft/2:Nfft/2-1) * (Fe/Nfft);

%% DSP théoriqu
% Axe de fréquence
sl_theorique = zeros(1,Nfft);
for i = 1:Nfft
    f = freq(i);
    fsinc = sinc_n(f * Ts / 2);
    sl_theorique(i) = (pi^2 / 16) * (f^2) * (Ts^3) * fsinc^4;
end
% Ajouter le pic de Dirac à la fréquence 0
sl_theorique(Nfft/2 + 1) = sl_theorique(Nfft/2 + 1) + 1/4; 

%% Affichage
figure;
hold on;
plot(freq, 10*log10(sl_welch), 'DisplayName', 'DSP Simulée');  
plot(freq, 10*log10(sl_theorique), 'DisplayName', 'DSP Théorique'); 
title('Comparaison entre DSP Simulée et DSP Théorique');
xlabel('Fréquence (Hz)');
ylabel('DSP (dB)');
grid on;
legend show;
hold off;
