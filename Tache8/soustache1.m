addpath('..');
clear; close all; clc;

%% Chargement des données réelles
load('buffers.mat');     % charge Rs (=4e6) et buffers (2e6x9)
Fe = Rs;                 % fréquence d'échantillonnage réelle
Te = 1/Fe;
Ts=1e-6;
Fse = Ts/Te;                % facteur de suréchantillonnage théorique (20 MHz / 1 MHz)

fprintf('Nombre de buffers : %d\n', size(buffers,2));
fprintf('Durée par buffer : %.3f s\n', size(buffers,1)/Fe);

%% Choisir un buffer à analyser
i =2;   
yl = buffers(:, i).';    % signal complexe reçu

%% Visualisation brute 
figure;
subplot(3,1,1);
plot(real(yl));
title(sprintf('Buffer %d - Partie réelle du signal reçu', i));
xlabel('Échantillons'); ylabel('Amplitude');
grid on;

subplot(3,1,2);
plot(abs(yl).^2);
title('|y[k]|^2 - Énergie instantanée');
xlabel('Échantillons'); ylabel('Amplitude^2');
grid on;

subplot(3,1,3);
pwelch(yl, [], [], [], Fe, 'centered');
title('Spectre du signal (PWelch)');

%% Détection du préambule 
% Création du motif de préambule utilisé précédemment
s  = [ones(1, Fse/2), zeros(1, Fse/2)];
sp = [s, s, zeros(1, 3*Fse/2), s, s, zeros(1, 5*Fse/2)];


% Détection zone forte énergie,  correspondant à la trame utile
rl = abs(yl).^2;
[~, pic] = max(rl); % Position approximative du signal utile
fenetre = max(1, pic-2000) : min(length(yl), pic+2000);

% On applique la corrélation normalisée uniquement dans cette zone
delta_t_estime_local = synchro_tmp(rl(fenetre), sp);
delta_t_estime = fenetre(1) + delta_t_estime_local - 1;


fprintf('Décalage temporel estimé : %d échantillons\n', delta_t_estime);

%% Affichage du repérage du préambule 
figure;
plot(rl);
hold on;
xline(delta_t_estime, 'r', 'LineWidth', 2);
title(sprintf('Énergie reçue avec repérage du préambule (Buffer %d)', i));
xlabel('Échantillons'); ylabel('|y|^2');
legend('Signal', 'Préambule estimé');
grid on;

%% Estimation simple du SNR 
signal_zone = rl(delta_t_estime : delta_t_estime + 2000);
bruit_zone  = rl(1 : max(1, delta_t_estime - 20000));
SNR_dB = 10*log10(mean(signal_zone)/mean(bruit_zone));
fprintf('SNR estimé ≈ %.2f dB\n', SNR_dB);

