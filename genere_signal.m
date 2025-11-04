
function sl = genere_signal(bits, p0, p1)
    Ns = length(p0);          % nb d2échantillons par symbole
    N  = length(bits);        % nb de symboles

    sl = zeros(1, Ns * N);    % préallocation du signal complet

    for k = 1:N
        if bits(k) == 0
            sl((k-1)*Ns + (1:Ns)) = p0;
        else
            sl((k-1)*Ns + (1:Ns)) = p1;
        end
    end
end