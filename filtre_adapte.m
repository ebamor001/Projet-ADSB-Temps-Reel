function [rl, retard] = filtre_adapte(x, p)
    h      = fliplr(p);
    rl     = conv(x, h );                  % pas 'same'
    retard =  length(h)-1;               
end
