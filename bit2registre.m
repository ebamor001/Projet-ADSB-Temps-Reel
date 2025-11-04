function registre = bit2registre(bits, lat_ref,lon_ref)

% Fonction de décodage d'une trame ADS-B complète (112 bits)
% Entrée :
%   bits  - vecteur binaire (1x112) contenant la trame reçue
% Sortie :
%   registre - structure contenant les informations extraites :
%              (format, adresse, type, altitude, vitesse, latitude, longitude, etc.)
% Si le CRC est invalide, la fonction renvoie un champ vide.

    %% Étape 0 : vérifications préliminaires
    if length(bits) ~= 112
        error('Le message doit contenir exactement 112 bits.');
    end

    %% Étape 1 : Vérification du CRC
    poly_crc = 'z^24+z^23+z^22+z^21+z^20+z^19+z^18+z^17+z^16+z^15+z^14+z^13+z^12+z^10+z^3+1';
    crc_detector = comm.CRCDetector(poly_crc);
    [msg_dec, err_flag]=crc_detector(bits(:));
    if err_flag
        %disp('Erreur CRC détectée : trame rejetée.');
        registre = [];
        return;
    end

    %% Étape 2 : Extraction des champs principaux 
    registre = struct('adresse',[],'format',[],'type',[],'nom',[],'altitude',[],...
                'timeFlag',[],'cprFlag',[],'latitude',[],'longitude',[]);

    registre.format  = bi2de(fliplr(bits(1:5)'));  % format de trame :DF
    registre.adresse = dec2hex(bi2de(fliplr(bits(9:32)')), 6);  % Adresse OACI
    registre.type    = bi2de(fliplr(bits(33:37)')); % Type de message (FTC)

    %% Étape 3 : Décodage selon le type de message 
    if registre.format ~= 17
        disp('Trame ignorée : DF différent de 17 (non ADS-B).');
        registre = [];
        return;
    end
    type_msg = registre.type;
    if (type_msg >= 1 & type_msg <= 4)
        % Identification (types 1 à 4)
        registre.nom = decode_ident(bits(41:88));

    elseif (type_msg >= 9 & type_msg <= 18)
        % Position en vol (types 9 à 18, sauf 19)
        %12 premiers bits c l'altitude 
        alt_bits = bits(41:52);          % 12 bits bruts 
        alt_bits(8) = [];                % Suppression du bit inutile (b8)
        ra = bi2de(fliplr(alt_bits'));
        registre.altitude = 25 * ra - 1000;

        registre.timeFlag = bits(53);
        registre.cprFlag  = bits(54);
        % Calcul latitude / longitude via CPR
        registre.latitude  = decode_lat(bits(55:71), registre.cprFlag, lat_ref);
        registre.longitude = decode_lon(bits(72:88), registre.cprFlag, registre.latitude,lon_ref);
    % la position au sol (Type 5 à 8)
    elseif (5 <= type_msg && type_msg <= 8)
        y = decode_lat(bits(55:71), registre.cprFlag);
        x = decode_lon(bits(72:88), registre.cprFlag, y);
        registre.position_sol = [x y]; % Position au sol (longitude, latitude)
    
    % la vitesse (Type 19)
    elseif type_msg == 19
        vitesse_x = signe(bits(46)) * (bi2de(fliplr(bits(47:56)')) - 1);
        vitesse_y = signe(bits(57)) * (bi2de(fliplr(bits(58:67)'))- 1);
        vitesse_z = signe(bits(69)) * (bi2de(fliplr(bits(70:78)')) - 1);
        registre.velocity = sqrt((vitesse_z.^2) + (vitesse_y.^2) + (vitesse_x.^2)); % Vitesse
    else
        disp('Type de trame non pris en charge ou inconnu.');
    end
end
    

    

%  Sous-fonctions locales
function nom = decode_ident(bits_nom)
    % Table de correspondance officielle ICAO (64 caractères possibles)
    alphabet =['#ABCDEFGHIJKLMNOPQRSTUVWXYZ#####_###############0123456789#####'];
    nom = ''; 

    % Boucle sur les 8 caractères (8 x 6 bits)
    for i = 0:7
        idx = bi2de(fliplr(bits_nom(i*6 + (1:6))'));  % 0 → 63
        idx = idx + 1;  % MATLAB commence à 1

        if idx <= length(alphabet)
            nom = [nom, alphabet(idx)];
        else
            nom = [nom, '_']; % caractère inconnu
        end
    end

    % Nettoyage final (remplacer les '#' par des espaces)
    nom = strrep(nom, '#', ' ');
    nom = strtrim(nom);
end

function lat = decode_lat(lat_bits, cpr_flag,lat_ref)
% Calcul de la latitude à partir du codage CPR
    LAT = bi2de(fliplr(lat_bits'));
    Nz = 15;         %le nombre de latitudes géographiques considérées entre l'équateur et un pôle 
    Nb = 17;         % le nombre de bits constituant le registre de latitude 
    Dlat = 360 / (4*Nz - cpr_flag);
    j = floor(lat_ref / Dlat) + floor(0.5 + (MOD(lat_ref, Dlat)/Dlat) - LAT/(2^Nb));
    lat = Dlat * (j + LAT/(2^Nb));

end

function lon = decode_lon(lon_bits, cpr_flag, lat, lon_ref)
% Calcul de la longitude à partir du codage CPR
    LON = bi2de(fliplr(lon_bits'));    
    Nb = 17;
    Nl = compute_Nl(lat);
    if Nl - cpr_flag > 0
        Dlon = 360 / (Nl - cpr_flag);
    else
        Dlon = 360;
    end
    m = floor(lon_ref / Dlon) + floor(0.5 + (MOD(lon_ref, Dlon)/Dlon) - LON/(2^Nb));
    lon = Dlon * (m + LON/(2^Nb));
end



function rep = MOD(a, b)
    rep = a - b * floor(a / b);
end

function Nl = compute_Nl(lat)
    lat = abs(lat);
    Nz = 15;
    if lat > 87
        Nl = 1;
    elseif lat == 0
        Nl = 59;
    elseif lat == 87
        Nl = 2;
    else
        a = 1 - cos(pi / (2 * Nz));
        b = cos(pi * lat / 180);
        Nl = floor(2 * pi ./ acos(1 - a ./ (b.^2)));
    end
end

function signe = signe(a)
    if bi2de(a) == 0
        signe = 1;
    else
        signe = -1;
    end
end
