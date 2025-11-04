addpath('..');

%% Paramètres
Ts = 1e-6;          % Durée symbole = 1 µs
Fe = 20e6;          % Fréquence d'échantillonnage = 20 MHz
Te = 1/Fe;         
Fse = Ts/Te;        % Facteur de sur-échantillonnage
Nb = 1000;          %longueur des bits à envoyer
N = Nb * Fse;


%% Définition des impulsions PPM
p_ref=[ones(1,Fse/2)];
p1 = [p_ref , 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0

%% Energie et bruit
Eg = Fse/2; 
Eb_N0_dB = 0:1:10;  
Eb_N0 = 10.^(Eb_N0_dB/10);
sigma2 =  Eg ./  (2*Eb_N0); 

%% TEB théorique d'une détection early/late PPM sous AWGN
Pb = 0.5 * erfc(sqrt(Eb_N0/2));


%% Initialisation
TEB_simule = zeros(1,length(Eb_N0));

%% Boucle sur Eb/N0
for i = 1:length(Eb_N0)
    nb_erreurs = 0;
    bits_totaux = 0;

    while nb_erreurs < 100  % au moins 100 erreurs pour validité statistique

        % Génération bits aléatoires
        bits = randi([0, 1], 1, Nb);
        % Construction du signal PPM
        sl = genere_signal(bits,p0,p1);        

        % Ajout bruit gaussien
        bruit = sqrt(sigma2(i)) * randn(1, length(sl));
        sl_bruite = sl + bruit;

        % Filtre adapté
        [rl,retard] = filtre_adapte(sl_bruite,p_ref);     

        % Décision par corrélations early/late
        rm = decision(rl, Fse, Nb, retard); %bits_recus

        % Comptage erreurs
        erreurs = sum(bits ~= rm);
        nb_erreurs = nb_erreurs + erreurs;
        bits_totaux = bits_totaux + Nb;
    end

    % Estimation du TEB
    TEB_simule(i) = nb_erreurs / bits_totaux;
end

%% Affichage
figure;
semilogy(Eb_N0_dB, TEB_simule, '-o'); 
hold on;
semilogy(Eb_N0_dB, Pb, 'r-');
xlabel('Eb/N0 (dB)');
ylabel('TEB');
title('Comparaison TEB simulé vs théorique (PPM)');
legend('TEB simulé','TEB théorique de PPM');
grid on;
