%  Tâche 8 - Sous-tâche 2
%  Vérification des avions détectés à partir de buffers.mat
%  (chaîne complète : synchro + démodulation + décodage)
addpath('..');
clear; close all; clc;

%% Paramètres généraux
load("buffers.mat");      % variables : buffers, Rs (= 4 MHz)
Fe = Rs; 
Te = 1/Fe;
Ts = 1e-6; 
Fse = Ts/Te;
Nb = 112;            % trame ADS-B

REF_LON =-0.699308;   % Longitude de référence : Bordeaux-Mérignac
REF_LAT =  44.830418;   % Latitude de référence

fprintf("Nombre total de buffers : %d\n\n", size(buffers,2));

%% Définitions PPM 
p_ref=[ones(1,Fse/2)];
p1 = [p_ref, 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0

% Préambule ADS-B (8 impulsions connues)
s  = [ones(1,Fse/2), zeros(1,Fse/2)];
sp = [s, s, zeros(1, 3*Fse/2), s, s, zeros(1, 5*Fse/2)];


%% Structures de stockage 
liste_avions = {};
positions = struct();
nb_trames_valides = 0;

%% Boucle sur chaque buffer
for j = 1:size(buffers,2)
    fprintf("\n--- Traitement du buffer %d ---\n", j);
    yl = buffers(:, j).';      % signal complexe reçu
    
    rl = abs(yl).^2;           % énergie instantanée
    indices_trames = synchro_tmp_adapte(rl, sp, Fse, 0.7);
    fprintf("   → %d trame(s) détectée(s)\n", length(indices_trames));
    
    for idx = indices_trames
        if idx + length(sp) + 112*Fse <= length(yl)
            trame = yl(idx + length(sp) + 1 : idx + length(sp) + 112*Fse);
            
            % filtrage + démodulation + décodage
            [rl_filt, retard] = filtre_adapte(trame, p_ref);
            bits_recus = decision_adapte(rl_filt, Fse, Nb, retard);
            bits_recus = double(bits_recus(:));
    
            registre = bit2registre(bits_recus, REF_LAT, REF_LON);
            if isempty(registre) || ~isfield(registre,'format') || registre.format~=17
                fprintf("   ⚠ DF ≠ 17 → trame ignorée.\n");
                continue;
            end
        
            addr = registre.adresse;
            field_name = ['avion_' addr];   %  champ MATLAB valide
            fprintf("   ✓ Trame valide - Avion %s (type %d)\n", addr, registre.type);
            
            % Si nouvel avion, créer une entrée
            if ~any(strcmp(liste_avions, addr))
                liste_avions{end+1} = addr;
                positions.(field_name).lat = [];
                positions.(field_name).lon = [];
            end
            
            % Sauvegarder la position si dispo
            if isfield(registre,'latitude') && isfield(registre,'longitude') ...
                    && ~isempty(registre.latitude)
                positions.(field_name).lat(end+1) = registre.latitude;
                positions.(field_name).lon(end+1) = registre.longitude;
            end
        end
    end
end

%% Résumé des résultats
fprintf("\n=== RÉSUMÉ DES AVIONS DÉTECTÉS ===\n");
for k = 1:length(liste_avions)
    addr = liste_avions{k};
    field_name = ['avion_' addr];
    fprintf(" → Avion %d : %s (%d positions valides)\n", ...
        k, addr, length(positions.(field_name).lat));
end

fprintf("Total : %d avions détectés (%d trames valides)\n", ...
    length(liste_avions), nb_trames_valides);

%% Affichage des trajectoires détectées
affiche_map(REF_LON, REF_LAT);  % affiche  aéroport + fond.png
hold on;

% Boucle d'affichage des trajectoires
for i = 1:length(liste_avions)
    addr = liste_avions{i};
    field_name = ['avion_' addr];

    % Vérifie que des positions existent
    if ~isfield(positions, field_name)
        continue;
    end

    lon = positions.(field_name).lon;
    lat = positions.(field_name).lat;

    if isempty(lon) || isempty(lat)
        continue;
    end

    % Tracé de la trajectoire
    plot(lon, lat, 'b--', 'LineWidth', 1.2);
    plot(lon(end), lat(end), 'b.', 'MarkerSize', 15);
    text(lon(end) + 0.02, lat(end), sprintf('0x%s', addr), ...
        'Color', 'b', 'FontSize', 10, 'FontWeight', 'bold');
end

title('Trajectoires détectées depuis buffers.mat');
grid on;
axis equal;
xlim([-1.3581,0.7128]);
ylim([44.4542,45.1683]);

hold off;
