function y = sinc_n(x)
% le sinus cardinal normalisé défini en x=0 par sinc(0)=1.

    y = ones(size(x));             % initialise à 1 (pour x=0)
    idx = (x ~= 0);               
    y(idx) = sin(pi*x(idx)) ./ (pi*x(idx)); 
end