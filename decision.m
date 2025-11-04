function rm = decision(rl, Fse, Nb, retard)
    % On évalue le filtre adapté aux 2 instants par symbole :
    %  - "early" : milieu de la 1/2 symbol (k-1)*Fse + Fse/2
    %  - "late"  : fin de symbole k*Fse
    % Comme on a utilisé conv(...,'full'), on ajoute le retard pour retomber sur les index que donnerait 'same'.
    % Règle : si rE > rL => bit = 1 (p1 a son impulsion en première moitié)
    % sinon      => bit = 0

    rm = zeros(1, Nb);

    for k = 1:Nb
        idxE = (k-1)* Fse  + retard +1; %on décale explicitement
        idxL = idxE + Fse/2;
        %un patch ajouté dans la tache 4 , à supprimer
        if idxL > length(rl)
            rm = rm(1:k-1); %on enleve les dépassement et on arréte 
            break;
        end
        
        rE = rl(idxE);   
        rL = rl(idxL);

        rm(k) = (rE > rL);   % -> 1 si early > late, sinon 0
    end
end


