function indices_trames = synchro_tmp_adapte(y, sp, Fse, seuil)
% Détection multiple du préambule ADS-B dans le signal reçu
% Sortie :
%   indices_trames - indices de début des trames détectées

    N  = length(y);
    Tp = length(sp);
    R  = zeros(1, N - Tp);

    % Corrélation normalisée glissante
    for k = 1:(N - Tp)
        num   = sum(y(k:k+Tp-1) .* sp);
        denom = sqrt(sum(abs(sp).^2) * sum(abs(y(k:k+Tp-1)).^2));
        R(k)  = abs(num) / (denom + eps);
    end

    % Détection des pics au-dessus du seuil
    indices = find(R > seuil);
    frame_len = round(112 * Fse);  % longueur d'une trame ADS-B

    % Nettoyage : suppression des doublons proches (< frame_len)
    indices_trames = [];
    last_idx = - frame_len; % pour que le premier indexe soit tjrs accepté

    for idx = indices
        if idx > last_idx + frame_len
            indices_trames(end+1) = idx; 
            last_idx = idx;
        end
    end
end
