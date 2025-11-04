addpath('..');

%% paramétres
Ts = 1e-6;          % Durée symbole = 1 µs
Fe = 20e6;          % Fréquence d'échantillonnage = 20 MHz
Te = 1/Fe;         
Fse = Ts/Te;        % Facteur de sur-échantillonnage
bits = [1 0 0 1 0];  

%% Définition des impulsions PPM
p_ref=[ones(1,Fse/2)];
p1 = [p_ref , 0*p_ref];   % impulsion pour bit 1
p0 = [0*p_ref, p_ref];   % impulsion pour bit 0

%% Chaîne de communication
sl = genere_signal(bits,p0,p1);         % Signal émis aprés modulation PPM
t = (0:length(sl)-1)*Te*1e6; % Axe temps pour le signal émis
[rl,retard] = filtre_adapte(sl,p_ref);          % Filtrage adapté
t_rl = (0:length(rl)-1)*Te*1e6; % axe temps en µs calculé aprés la conv pour le décalage
rm = decision(rl,Fse,length(bits), retard);     % Échantillonnage + décision
rl_aligne = rl(retard+1 : end-retard);

%% Affichages
figure;
subplot(3,1,1);
plot(t,sl);
title('Signal émis s_l(t)');
xlabel('Temps [µs]');
ylabel('amplitude');

subplot(3,1,2);
plot(t_rl,rl);
title('Signal convolué r_l(t)');
xlabel('Temps [µs]');
ylabel('amplitude');

subplot(3,1,3);
stem(0:length(rm)-1,rm,"filled");
title('décision bk');
xlabel('Index du symbole'); 
ylabel('décision');

