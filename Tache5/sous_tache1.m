addpath('..');
clear all
close all
clc

%% Paramètres
Fe = 20e6; 
Te = 1/Fe;
Ts = 1e-6;      
Fse  = Ts/Te; 
alpha = 1;
Nb=100;

%% paramétres de distorsions 
max_delta_t = 100;
max_delta_f = 1000;
phi0_max = 2*pi;

%% Définition des impulsions PPM
ppi=[ones(1,Fse/2)];
p1 = [ppi , 0*ppi];   % impulsion pour bit 1
p0 = [0*ppi, ppi];   % impulsion pour bit 0
p  = 0.5 * (p0 - p1);        


%% générer aléatoiremlent delta_t , delta_f et phi0 et des bits 
delta_t = randi(max_delta_t);
delta_f = (rand() * 2 * max_delta_f) - max_delta_f;  %intervalle -1000, 1000Hz
phi0 = rand() * phi0_max; 
b = randi([0, 1], 1, Nb);
sl  = genere_signal(b, p0, p1); 


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


% Estimation du décalage fréquentiel sur le préambule
start_idx = delta_t + 1;
end_idx = start_idx + length(sp) - 1;
if end_idx > length(yl)
    end_idx = length(yl);
end
y_preamb = yl(start_idx:end_idx);

% Estimation
delta_f_estime = synchro_f(y_preamb, sp, Te);
%% Affichage
fprintf('Décalage fréquentiel réel   : %+8.2f Hz\n', delta_f);
fprintf('Décalage fréquentiel estimé : %+8.2f Hz\n', delta_f_estime);
fprintf('Erreur relative             : %.4f %%\n', ...
        100*abs((delta_f_estime - delta_f)/delta_f));

