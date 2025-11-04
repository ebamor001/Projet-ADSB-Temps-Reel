addpath('..');

% clear
clear;
close all;
clc;

%% Paramètres
Fe = 20e6; 
Te = 1/Fe;
Ts = 1e-6;      
Fse  = Ts/Te; 
Nb=112;
eb_n0_dB = 0:1:10;
eb_n0 = 10.^(eb_n0_dB/10);


%% Distorsions
alpha = 1;
max_delta_t = 100;
max_delta_f = 1000; 
phi0_range = 2 * pi; 

%% Paramètres 
p_ref=[ones(1,Fse/2)];
p1 = [p_ref , 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0
% Générer le préambule 
s = [ones(1, Fse/2), zeros(1, Fse/2)]; 
sp = [s, s, zeros(1, 3*Fse/2), s, s, zeros(1, 5*Fse/2)];
sigA2 = 1;  % Variance théorique des symboles
Eg = sum(abs(p_ref) .^2); 
sigma2 = (sigA2 * Eg) ./ (2*eb_n0); 
TEB_simule = zeros(1, length(eb_n0));
Pb = 0.5 * erfc(sqrt(eb_n0/2));  % Théorique PPM


%% Boucle sur Eb/N0
for j = 1:length(eb_n0)
    nb_erreurs = 0;
    bits_totaux = 0;

    while nb_erreurs < 1000  % au moins 100 erreurs pour validité statistique
        delta_t = randi(max_delta_t);
        delta_f = (rand() * 2 * max_delta_f) - max_delta_f; % Uniforme [-1kHz, 1kHz]
        phi0 = rand() * phi0_range;

        % Génération bits aléatoires
        bits = randi([0, 1], 1, Nb);

        % Modulation PPM
        sl = genere_signal(bits,p0,p1);        

        % décaler le signal
        sl_decal = [zeros(1, delta_t), sp, sl]; 

        % Générer le bruit
        nl = sqrt(sigma2(j)/2) * (randn(size(sl_decal)) + 1i * randn(size(sl_decal)));
        
        % Temps d'échantillonnage
        t =0:Te:(length(sl_decal)-1)*Te;
        
        % Ajouter l'effet Doppler et le bruit
        yl = alpha*sl_decal .* exp(-1i * (2 * pi * delta_f * t + phi0)) + nl;
        
        % Estimation de delta_t avec l'intercorrélation
        delta_t_estime = synchro_tmp(yl, sp); % Estimer le décalage temporel
           
       %  Estimation fréquentielle via synchro_f()
        start_idx = delta_t_estime + 1;
        end_idx   = start_idx + length(sp) - 1;
        if end_idx > length(yl), end_idx = length(yl); end
        y_preamb = yl(delta_t_estime + 1:end_idx);
        delta_f_estime = synchro_f(y_preamb, sp, Te);

        % Compensation du Doppler estimé
        yl_corr = yl .* exp(1i * 2*pi*delta_f_estime*t);
        yl_sync = yl_corr(delta_t_estime + length(sp) + 1:end); % Décaler le signal de delta_t


       
        

        % Filtre adapté
        [rl,retard] = filtre_adapte(yl_sync,p_ref);   
        
        % Décision par corrélations early/late
        rm = decision_adapte(rl, Fse, Nb, retard); %bits_recus
        
        % Calculer les erreurs
        L = min(length(bits), length(rm));
        erreurs = sum(bits(1:L) ~= rm(1:L));
        nb_erreurs = nb_erreurs + erreurs;
        bits_totaux = bits_totaux + length(rm);
        
    end
    TEB_simule(j) = nb_erreurs / bits_totaux;
end

% Tracer le TEB
figure;
semilogy(eb_n0_dB, TEB_simule, 'o-');
hold on;
semilogy(eb_n0_dB, Pb, 'r-');
title('TEB en fonction de Eb/N0');
xlabel('Eb/N0 (dB)');
ylabel('TEB');
legend('TEB simulé', 'TEB théorique');
grid on;


        

        