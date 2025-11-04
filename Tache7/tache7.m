%% Tâche 6 - Sous-tâche 3 : Décodage et affichage de trajectoire
addpath('..'); 
clear; close all; clc;

%% Paramétres
REF_LON = -0.699308;   % Longitude de référence : Bordeaux-Mérignac
REF_LAT =  44.830418;   % Latitude de référence

% Définition des impulsions PPM
Fe = 4e6; 
Te = 1/Fe;
Ts = 1e-6;     
Nb = 112;            % trame ADS-B

Fse  = Ts/Te; 
p_ref=[ones(1,Fse/2)];
p1 = [p_ref, 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0
s  = [ones(1,Fse/2), zeros(1,Fse/2)];
sp = [s, s, zeros(1, 3*Fse/2), s, s, zeros(1, 5*Fse/2)];



load("buffers.mat");        % Contient la variable adsb_msgs (112 x N)

%%  Initialisation 
% Tableaux pour stocker les positions valides
latitudes  = [];
longitudes = [];
altitudes  = [];

%% Boucle principale sur les trames 
for j = 1:size(buffers,2)
    fprintf("\n--- Traitement du buffer %d ---\n", j);
    yl = buffers(:, j).';      % signal complexe reçu
    
    rl = abs(yl).^2;           % énergie instantanée
    indices_trames = synchro_tmp_adapte(rl, sp, Fse, 0.7);

    for idx = indices_trames
        if idx + length(sp) + 112*Fse <= length(yl)
            trame = yl(idx + length(sp) + 1 : idx + length(sp) + 112*Fse);
            % filtrage + démodulation + décodage
            [rl_filt, retard] = filtre_adapte(trame, p_ref);
            bits_recus = decision_adapte(rl_filt, Fse, Nb, retard);
            bits_recus = double(bits_recus(:));
    
            % Si la trame est valide et contient une position GPS
            % Afficher toutes les informations dans la console
            registre = bit2registre(bits_recus,REF_LAT,REF_LON);
            
            if isfield(registre, 'velocity') && ~isempty(registre.velocity)
                fprintf('Trame type 19 %d:\n', idx);
                fprintf('Vitesse: %d KT\n', registre.velocity);
                fprintf('\n'); % Ligne de séparation pour chaque trame
            end
       
            
        end
    end
         
end

%% Affichage de la  carte avec les positions 

fprintf("Décodage terminé. %d trames valides utilisées pour la trajectoire.\n", length(latitudes));
