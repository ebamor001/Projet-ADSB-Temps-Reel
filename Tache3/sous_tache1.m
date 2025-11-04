addpath('..');
clear;close all;clc;


%% paramétres
Ts = 1e-6;          % Durée symbole = 1 µs
Fe = 20e6;          % Fréquence d'échantillonnage = 20 MHz
Te = 1/Fe;         
Fse = Ts/Te;        % Facteur de sur-échantillonnage
Nb=88;           
N=Nb*Fse;

%% CRC
%definir polynome generateur
pgen = 'z^24+z^23+z^22+z^21+z^20+z^19+z^18+z^17+z^16+z^15+z^14+z^13+z^12+z^10+z^3+1';
genCRC =comm.CRCGenerator(pgen);                   % objet générateur CRC
detCRC = comm.CRCDetector(pgen);                   % objet détecteur CRC
%% Définition des impulsions PPM
p_ref=[ones(1,Fse/2)];
p1 = [p_ref , 0*p_ref];                            % impulsion pour bit 1
p0 = [0*p_ref, p_ref];                             % impulsion pour bit 0

%% Chaîne de communication  
data =randi([0, 1],Nb,1);                          %notre 88 bits
Message = genCRC(data);                            %112 bits sortie codeur CRC 
%sigma2 = 2;                                        %variance
sl = genere_signal(Message,p0,p1);                 %sortie de modulateur PPM
%ici on génére pas encore la préambule
%w = sqrt(sigma2) * randn(size(sl));               % bruit 
%sl_bruite = sl+w;                                 % Signal émis(avec bruit)
[rl,retard] = filtre_adapte(sl,p_ref);             % Filtrage adapté
rm = decision(rl,Fse,length(Message), retard);     % Échantillonnage + décision
rm_col = rm(:);                                    %comm.CRCDetector attend un vecteur colonne
[msg, err] = detCRC(rm_col);                       % detCRC renvoie : [message_sans_crc, flag_erreur]

%% affichage(1 = erreur détectée, 0 = message validé)
if err
    disp("erreur détectée ");
    disp("->message non validé");
else
    disp("aucune erreur détectée");
    disp("->message validé");
end

%% Affichages
%axes 
t = (0:length(sl)-1)*Te*1e6;                        % Axe temps pour le signal émis
t_rl = (0:length(rl)-1)*Te*1e6;                     % axe temps en µs calculé aprés la conv pour le décalage
%figures
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
title('Échantillons r_m ');
xlabel('Index du symbole'); 
ylabel('décision');

