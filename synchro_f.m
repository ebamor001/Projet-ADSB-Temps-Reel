function delta_f_estime = synchro_f(yl, sp, Te)
    % Estimation de la dérive fréquentielle par analyse de phase
    % Entrées :
    %   yl : portion du signal reçu contenant le préambule (complexe)
    %   sp : préambule connu (binaire)
    %   Te : période d'échantillonnage

    % On garde uniquement les échantillons du préambule actif
    sp_abs = abs(sp);
    indices_actifs = find(sp_abs > 0.5);

    % Phases correspondantes du signal reçu
    phase_vals = angle(yl(indices_actifs));

    % Temps associés
    t_actifs = (indices_actifs - 1) * Te;

    % Ajustement linéaire (phase = pente * t + cste)
    p = polyfit(t_actifs, phase_vals, 1);
    pente = p(1);

    % Fréquence Doppler estimée
    delta_f_estime = -pente / (2*pi);
end
