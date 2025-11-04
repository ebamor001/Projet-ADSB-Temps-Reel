function delta_t_estime = synchro_tmp(y, sp)
    N = length(y);
    Tp = length(sp);
    % Centrage
    y = y - mean(y);
    sp = sp - mean(sp);
    R = zeros(1, N - Tp);
    Es = sqrt(sum(abs(sp).^2)); % énergie du préambule
    % Corrélation glicssante normalisée
    for k = 1:(N - Tp + 1)
        num = sum(y(k:k+Tp-1) .* conj(sp));
        Ey =  sum(abs(y(k:k+Tp-1)).^2);
         if Ey ~= 0
            R(k) = abs(num) / (Es * Ey);  
        else
            R(k) = 0;
         end
    end
    %ou bien on peut faire directement une intercorrélation R= xcorr(y, sp);  
    [~, idx] = max(R); %[valeur_max, indice_max]
    delta_t_estime = idx -1;
end


    
    
   