%% Reifenquerschnittsauswertung: Stahl und Cap Ply
% Skript um den Querschnitt zu analysieren
function []=Reifenquerschnitt()

clearvars ;
close all; clc;
%% Einlesen der Bilder
[path,cancelled]=uigetimagefile();
if(cancelled)
    error('kein Image gew�hlt');
end
img=imread(path);
fh=figure('keypressfcn',@fh_kpfcn),imshow(img);
imggrad=imgradient(img);
sensitivity=0.95;
maxN_Circles=450;
minRad=3; %% bei 96 dpi
maxRad=7; %% bei 96 dpi
delta=0;



%% Kreise Segmentieren (Stahl)
[BW,maskedImg,centers,radii]=segmentImageCircles(img,sensitivity,maxRad,minRad,maxN_Circles);

imshow(BW);
hold on
plot(centers(:,1),centers(:,2),'o','LineWidth',2); %% hier kann im Plot falsche Daten mit Tool -->brusch +link entfernt werden
%% Polynom mit den Kreismittelpunkten fitten
p=polyfit(centers(:,1),centers(:,2),2);
n=length(img(1,:));
x1 = linspace(0,length(img(1,:)),n);
y1 = polyval(p,x1);




plot(x1,y1,'LineWidth',2,'Color','green');

%% eine manuelle ROI ausw�hlen (Delta Kriterium in |y| )
plotEinhuellende();
close gcf;


%% Eine Maske mit dem neuen ROI erstellen
mask = false(size(img,1),size(img,2));

for xx=1:length(img(1,:))
    for yy=1:length(img(:,1))
        if(abs(yy-y1(xx))<=delta)
            mask(yy,xx)=true;
        end
    end
end

%% entfernen der Outliers (Kreise ausserhalb des ROIs)
new_centers=[];
new_radii=[];
for nn=1:size(centers,1)
    if mask(round(centers(nn,2)),round(centers(nn,1)))==true
        new_centers=cat(1,new_centers,centers(nn,:));
        new_radii=cat(1,new_radii,radii(nn,:));
    end
end


BW_masked=img;
BW_masked(~mask) = 0;


fh=figure,imshow(BW_masked);
hold on

%% neuer Polyfit mit deg=6 diesmal ohne Outliers
p=polyfit(new_centers(:,1),new_centers(:,2),6);
n=length(img(1,:));
x1 = linspace(0,length(img(1,:)),n);
y1 = polyval(p,x1);


%% linked brushing funktioniert nur im breakpoint/keyboard modus!! Daten 
title('L�sche ungewollte Mittelpunkte mit Link und Brush Tool bei Bedarf,>>K dbcont eingeben,Press Done');
plot(new_centers(:,1),new_centers(:,2),'o','LineWidth',2,...
    'XDataSource','new_centers(:,1)','YDataSource','new_centers(:,2)','ZDataSource','new_radii');

linkdata on; 
brush on;
doneHandle=uicontrol('String','Done', 'Callback', {@part2function}'); 
keyboard
%% ENTER dbcont in K>> console

    function []= part2function(src,evt)

%% Kreise in oberhalb und unterhalb des Polynoms einteilen

linkdata off;
brush off;
delete(doneHandle)
plot(x1,y1,'LineWidth',2,'Color','green');

upper_centers=[];
upper_radii=[];
lower_centers=[];
lower_radii=[];
for nn=1:size(new_centers,1)
    if new_centers(nn,2)<y1(round(new_centers(nn,1)))
        upper_centers=cat(1,upper_centers,new_centers(nn,:));
        upper_radii=cat(1,upper_radii,new_radii(nn));
    end
    if new_centers(nn,2)>=y1(round(new_centers(nn,1)))
        lower_centers=cat(1,lower_centers,new_centers(nn,:));
        lower_radii=cat(1,lower_radii,new_radii(nn));
    end
end

imshow(BW_masked);
hold on;

plot(upper_centers(:,1),upper_centers(:,2),'x','LineWidth',2);
waitforbuttonpress;
plot(lower_centers(:,1),lower_centers(:,2),'x','LineWidth',2);

%% Berechnen der A und D Werte
A_s_upper=pi*upper_radii.^2;
A_s_upper_avg=mean(A_s_upper)
D_s_upper=upper_radii*2;
D_s_upper_avg=mean(D_s_upper)

A_s_lower=pi*lower_radii.^2;
A_s_lower_avg=mean(A_s_lower)
D_s_lower=lower_radii*2;
D_s_lower_avg=mean(D_s_lower)

upper_avg_centers=zeros(size(upper_centers,1),2);
lower_avg_centers=zeros(size(upper_centers,1),2);

%% mittelpunkte upper stahl � zwischen beiden Draehten
for nn=1:size(upper_centers,1)
    for mm=1:size(upper_centers,1)
        if (norm(upper_centers(nn)-upper_centers(mm))<1.5*D_s_upper_avg && mm~=nn)
            
            upper_avg_centers(nn,1)=(upper_centers(nn,1)+upper_centers(mm,1))/2;
            upper_avg_centers(nn,2)=(upper_centers(nn,2)+upper_centers(mm,2))/2;
        
    
        end
        
    end
    if  upper_avg_centers(nn,1)==0 %% wenn nur ein kreis erkannt wird setzte diesen als  Mittelpunkt
            upper_avg_centers(nn,1)=upper_centers(nn,1);
            upper_avg_centers(nn,2)=upper_centers(nn,2);
    end
end

%% abst�nde upper stahl  � zwischen beiden Draehten
sorted_upper_avg_centers=sortrows(upper_avg_centers);
for nn=1:(size(upper_avg_centers,1)-1)
    
    
    upper_avg_centers_dst(nn,1)=sorted_upper_avg_centers(nn+1,1)-sorted_upper_avg_centers(nn,1);
    upper_avg_centers_dst(nn,2)=sorted_upper_avg_centers(nn+1,2)-sorted_upper_avg_centers(nn,2);
    
    
end



%% mittelpunkte lower stahl  � zwischen beiden Draehten
for nn=1:size(lower_centers,1)
    for mm=1:size(lower_centers,1)
        if (norm(lower_centers(nn)-lower_centers(mm))<1.5*D_s_upper_avg && mm~=nn)
            
            lower_avg_centers(nn,1)=(lower_centers(nn,1)+lower_centers(mm,1))/2;
            lower_avg_centers(nn,2)=(lower_centers(nn,2)+lower_centers(mm,2))/2;
            
        end
            
    end
            if  lower_avg_centers(nn,1)==0 %% wenn nur ein kreis erkannt wird setzte diesen als  Mittelpunkt
                    lower_avg_centers(nn,1)=lower_centers(nn,1);
                    lower_avg_centers(nn,2)=lower_centers(nn,2);
            end
    
end

%% abst�nde lower stahl  � zwischen beiden Draehten
sorted_lower_avg_centers=sortrows(lower_avg_centers);
for nn=1:(size(lower_avg_centers,1)-1)
    
    
    lower_avg_centers_dst(nn,1)=sorted_lower_avg_centers(nn+1,1)-sorted_lower_avg_centers(nn,1);
    lower_avg_centers_dst(nn,2)=sorted_lower_avg_centers(nn+1,2)-sorted_lower_avg_centers(nn,2);
    
    
end


plot(upper_avg_centers(:,1),upper_avg_centers(:,2),'x','LineWidth',2);
plot(lower_avg_centers(:,1),lower_avg_centers(:,2),'x','LineWidth',2);
waitforbuttonpress;

p_upper = sorted_upper_avg_centers;                        
dp_upper = upper_avg_centers_dst;                       
quiver(p_upper(1:end-1,1),p_upper(1:end-1,2),dp_upper(:,1),dp_upper(:,2),0)


distanceUpper=sqrt((mean(nonzeros(dp_upper(:,1))))^2+(mean(nonzeros(dp_upper(:,2))))^2)

p_lower = sorted_lower_avg_centers;                        
dp_lower = lower_avg_centers_dst;                       
quiver(p_lower(1:end-1,1),p_lower(1:end-1,2),dp_lower(:,1),dp_lower(:,2),0)
distanceLower=sqrt((mean(nonzeros(dp_lower(:,1))))^2+(mean(nonzeros(dp_lower(:,2))))^2)



waitforbuttonpress;
viscircles(upper_centers, upper_radii,'EdgeColor','r');

viscircles(lower_centers, lower_radii,'EdgeColor','b');

figure;

subplot(2,2,1),histo_upper_complete=histogram(nonzeros(dp_upper),100,'Normalization','pdf');
hold on
y = nonzeros(dp_upper);
y(y<10)=NaN;
y=sort(y);
mu = distanceUpper;
sigma = 4;
f = exp(-(y-mu).^2./(2*sigma^2))./(sigma*sqrt(2*pi));
plot(y,f,'LineWidth',1.5)
hold off
subplot(2,2,2),histo_lower_complete=histogram(nonzeros(dp_lower),100,'Normalization','pdf');

hold on
y = nonzeros(dp_lower);
y(y<10)=NaN;
y=sort(y);
mu = distanceLower;
sigma = 4;
f = exp(-(y-mu).^2./(2*sigma^2))./(sigma*sqrt(2*pi));
plot(y,f,'LineWidth',1.5)
hold off


dp_upper(dp_upper<11)=NaN;
dp_lower(dp_lower<11)=NaN;

subplot(2,2,3),histo_A_upper=histogram(nonzeros(dp_upper),100,'Normalization','pdf');
hold on
y = nonzeros(dp_upper);
y(y<10)=NaN;
y=sort(y);
mu = distanceUpper;
sigma = 4;
f = exp(-(y-mu).^2./(2*sigma^2))./(sigma*sqrt(2*pi));
plot(y,f,'LineWidth',1.5)
hold off
subplot(2,2,4),histo_A_lower=histogram(nonzeros(dp_lower),100,'Normalization','pdf');
hold on
y = nonzeros(dp_lower);
y(y<10)=NaN;
y=sort(y);
mu = distanceLower;
sigma = 4;
f = exp(-(y-mu).^2./(2*sigma^2))./(sigma*sqrt(2*pi));
plot(y,f,'LineWidth',1.5)
hold off
keyboard;

    end

% ph=pan(fh);
% bwlimit=0.2;
%  bwimg = imbinarize(img,'adaptive','ForegroundPolarity','bright','Sensitivity',0.01);
% imshowpair(img,imggrad,'montage');

% set(h_fig,'KeyPressFcn',@(H,E) assignin('base','a',E.Key));


%% fitte ein Polynom vom Grad polyDeg um manuell gew�hlte Punkte im Bild. ROI im Bild
    function[p]=polyfitManual(polyDeg)
        
        fh.WindowState='fullscreen';
        axis manual;
        axis([0 length(img(1,:)) 0 length(img(1,:))/1.6]);
        title(' Zoome und dr�cke Enter');
        zoom on;
        waitfor(gcf, 'CurrentCharacter', char(13))
        zoom reset
        zoom off
        stopvar=false;
        
        [x,y]=selectPoints();
        p=polyfit(x,y,polyDeg);
        n=10^4;
        x1 = linspace(0,length(img(1,:)),n);
        y1 = polyval(p,x1);
        
        delta=0;
        
        hold on
        plot(x,y,'o','LineWidth',2);
        plot(x1,y1,'LineWidth',2,'Color','green');
        hold on
        
        
        
        plotEinhuellende();
        
    end

%% manuelles Ausw�hlen von Punkten im Bild. Dient der Polynom Regression um ROI zu bestimmen
    function [x,y]=selectPoints()
        while(true)
            title('w�hle die Kreuze aus mit linker Maustaste! Return/Eingabe um zu best�tigen');
            
            [x_buff,y_buff] = ginput;
            x=[];
            y=[];
            x=cat(1,x,x_buff);
            y=cat(1,y,y_buff);
            
            title(' pan und dr�cke Space. q f�r quit / beenden');
            
            ph.Enable='on';
            btn=0;
            while(btn==0)
                btn=waitforbuttonpress;
            end
            if(fh.CurrentCharacter==' ')
                ph.Enable='off';
            end
            
            
            
            if(fh.CurrentCharacter=='q')
                ph.Enable='off';
                
                break;
            end
            
        end
    end



%% Plottet den Bereich der als ROI in Frage kommt
    function []= plotEinhuellende()
        while(true)
            linehandle=plot(x1,y1+delta,'m--',x1,y1-delta,'m--');
            title('up/down arrow um Einh�llende zu fitten')
            waitforbuttonpress;
            
            if(fh.CurrentCharacter == char(13)) %% enter
                title('Beendet!')
                
                break;
            end
            children = get(gca, 'children'); %% dot operator.data.x==[] ersetzen
            delete(children(1));
            delete(children(2));
        end
        
        
        
        
    end
%% function der als callback in figure den ROI (mithilfe delta) anpasst mit arrow up/down
    function [] = fh_kpfcn(H,E)
        % Figure keypressfcn
        switch E.Key
            
            case 'rightarrow'
            case 'leftarrow'
            case 'uparrow'
                delta=delta+1;
            case 'downarrow'
                delta=delta-1;
                
            otherwise
        end
    end
end





