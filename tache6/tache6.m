%% Tâche 6 - Sous-tâche 3 : Décodage et affichage de trajectoire
addpath('..'); 
clear; close all; clc;

%% Paramétres
REF_LON =-0.699308;   % Longitude de référence : Bordeaux-Mérignac
REF_LAT =  44.830418;   % Latitude de référence

% Définition des impulsions PPM
Fe = 4e6; 
Te = 1/Fe;
Ts = 1e-6;      
Fse  = Ts/Te; 
p_ref=[ones(1,Fse/2)];
p1 = [p_ref, 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0

load("adsb_msgs.mat");        % Contient la variable adsb_msgs (112 x N)
[nb_bits, nb_trames] = size(adsb_msgs);
fprintf("Nombre total de trames chargées : %d\n", nb_trames);

%%  Initialisation 
% Tableaux pour stocker les positions valides
latitudes  = [];
longitudes = [];
altitudes  = [];

%% Boucle principale sur les trames 
for i = 1:nb_trames
    bits = adsb_msgs(:, i);  % Récupération d'une trame (ligne)
    
    % Décodage complet de la trame
    registre = bit2registre(bits,REF_LAT,REF_LON);

    % Si la trame est valide et contient une position GPS
    % Afficher toutes les informations dans la console
    fprintf('Trame %d:\n', i);
    if isfield(registre, 'nom')
        fprintf('Nom de lappareil: %s\n', registre.nom);
    end
    if isfield(registre, 'adresse')
        fprintf('Adresse OACI: %s\n', registre.adresse);
    end
    if isfield(registre, 'altitude')  && ~isempty(registre.altitude) 
        fprintf('Altitude: %d pieds\n', registre.altitude);
        altitudes = [altitudes, registre.altitude];
    end
    if isfield(registre, 'latitude') && isfield(registre, 'longitude')...
    && ~isempty(registre.latitude)   && ~isempty(registre.longitude) 
        fprintf('Latitude: %.6f, Longitude: %.6f\n', registre.latitude, registre.longitude);
        latitudes = [latitudes, registre.latitude];
        longitudes = [longitudes, registre.longitude];
    end
    fprintf('\n'); % Ligne de séparation pour chaque trame
         
end

%% Affichage de la  carte avec les positions 
if isempty(latitudes)
    warning('Aucune position valide détectée (vérifier le décodage).');
else
    % Afficher la carte avec les positions
    affiche_map(REF_LON, REF_LAT);
    
    % Tracer les points des avions
    hold on;
    plot(longitudes, latitudes, 'b-o'); % Tracé des points des avions sur la carte
    xlim([-1.3581,0.7128]);
    ylim([44.4542,45.1683]);
    hold off;
end

fprintf("Décodage terminé. %d trames valides utilisées pour la trajectoire.\n", length(latitudes));
