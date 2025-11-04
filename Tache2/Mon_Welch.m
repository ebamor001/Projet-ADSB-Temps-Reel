  function y = Mon_Welch(x, Nfft, Fe)
    N = length(x);
    nb_segments = ceil(N / Nfft);        % nombre total de segments (y compris le dernier incomplet)
    y = zeros(1, Nfft);                  % initialisation de la DSP moyenne

    % Zero-padding pour compléter le dernier segment
    x = [x, zeros(1, nb_segments * Nfft - N)];

    % On ne garde que les segments complets
    for i = 0:nb_segments-1
        X = fft(x(i*Nfft + 1 : (i+1)*Nfft), Nfft);
        y = y + abs(X).^2;
    end

    % Normalisation : c'est ici que ton binôme est différent
    y = y / (Fe * nb_segments * Nfft);
    y = fftshift(y);
end
