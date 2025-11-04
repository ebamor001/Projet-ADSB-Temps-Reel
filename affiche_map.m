function [] = affiche_map(AVION_LON, AVION_LAT)
% Plot trajectoire + logo avion

figure(1);
hold on;

%Bdx
x = linspace(-1.3581,0.7128,1024);
y = linspace(44.4542,45.1683,1024);

meshgrid(x,y(end:-1:1));
im = imread('fond.png');
image(x,y(end:-1:1),im);
plot(AVION_LON ,AVION_LAT ,'b--','MarkerSize',20,LineWidth=2);
%hold on;
plot(AVION_LON(end) ,AVION_LAT(end) ,'.b','MarkerSize',20,LineWidth=2);
text(AVION_LON(end)+0.05,AVION_LAT(end),'Current Pos','color','b')


set(gca,'YDir','normal')
xlabel('Longitude en degres');
ylabel('Lattitude en degres');
zlim([0,4e4]);

