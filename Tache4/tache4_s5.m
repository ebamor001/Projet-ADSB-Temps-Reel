addpath('..');
clear all
close all
clc

%% Paramètres
Fe = 20e6; 
Te = 1/Fe;
Ts = 1e-6;      
Fse  = Ts/Te; 
Nb=88;

%% paramétres de distorsions 
max_delta_t = 100;
max_delta_f = 1000;
phi0_max = 2*pi;
alpha = 1;

%% Définition des impulsions PPM
p_ref=[ones(1,Fse/2)];
p1 = [p_ref, 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0

%% générer aléatoiremlent delta_t , delta_f et phi0 et des bits 
delta_t = randi(max_delta_t);
delta_f = (rand() * 2 * max_delta_f) - max_delta_f;  %intervalle -1000, 1000Hz
phi0 = rand() * phi0_max; 
bits = randi([0, 1], 1, Nb);
sl  = genere_signal(bits, p0, p1); 


%% générer préambule
s = [ones(1, Fse/2), zeros(1, Fse/2)]; %motif se répétant de 1 au premiere moitié
sp = [s, s, zeros(1, 3*Fse/2), s, s, zeros(1, 5*Fse/2)];
sl_decal = [zeros(1, delta_t), sp, sl]; % Ajouter le préambule et le décalage temporel

%% Temps d'échantillonnage
t = (0:Te:(length(sl_decal)-1)*Te);

%% Générer le bruit (sans bruit ici)
nl = 0; 

%% Ajouter l'effet Doppler , le facteur d'atténuation , et le déphasage à l'origine
yl = alpha * sl_decal .* exp(-1i * (2 * pi * delta_f * t + phi0)) + nl;


%% Estimation de delta_t avec l'intercorrélation
delta_t_estime = synchro_tmp(yl, sp);    % Estimer le décalage temporel

%% Affichage les résultats
disp(['Delta_t réel : ', num2str(delta_t)]);
disp(['Delta_t estimé : ', num2str(delta_t_estime)]);


