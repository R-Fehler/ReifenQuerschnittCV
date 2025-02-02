%% Class of round wires with respect to dpi value

classdef Wire
    
    
    properties
        % strings
        FileName
        Name
        % scalars
        LayerLevel = 1% in Image upper layer 1, lower layer 2 even lower 3 ...
        DPI = 600%default value is 600dpi
        SteelGrayvalueThreshold = 60
        SensitivityLvL
        MaxNoOfCircles
        MinimumRadius
        MaximumRadius
        DistanceThresholdTuningValue=40
        % numerical Vectors in [px]
        PositionInImage% X,Y Coordinate
        Radius
        % matrices
        ImageOriginal
        ImageProcessed
        ImageUsedForCV
        
        % booleans
        UseOldSpline=false
        %Objects
        WireMaterial
        
        
    end
    
    properties (Dependent = true)
        %scalars
        MMPerPx
        DistanceThreshold %[px] threshold to ignore neighbouring wires
        RadiusMedian
        DiameterMedian
        %Vectors
        PositionInImageMM
        % Objects
        CrossSectionA
        DistanceToNextW
        
        
    end
    %% Public Methods
    methods
        
        %% Constructor
        function obj=Wire(img,dpi,filename,name,material)
            if nargin==0
            else
                obj.ImageOriginal=img;
                obj.DPI=dpi;
                obj.FileName=filename;
                obj.Name=name;
                obj.WireMaterial=material;
            end
        end
        %% f�r Copy Constructor bei bedarf
        function output = copyObject(input, output)
            C = metaclass(input);
            P = C.Properties;
            
            for k = 1:length(P)
                
                if ~P{k}.Dependent
                    output.(P{k}.Name) = input.(P{k}.Name);
                end
                
            end
            
        end
        
        %% GETTER / SETTER
        function out = get.MMPerPx(obj)
            out = 25.4 / obj.DPI;
        end
        function out =get.RadiusMedian(obj)
            out=median(obj.Radius,'omitnan');
        end
        function out=get.DiameterMedian(obj)
            out=obj.RadiusMedian*2;
        end
        function out= get.DistanceThreshold(obj)
            out=obj.DistanceThresholdTuningValue*obj.DPI/600;
            % 40 is set because of exp. with example images
            % with the Cap Ply Layer
        end
        
        function out = get.PositionInImageMM(obj)
            out = obj.PositionInImage * obj.MMPerPx;
        end
        
        function crossSectionArea = get.CrossSectionA(obj)
            crossSectionArea = CrosssectionArea;
            crossSectionArea.Px = pi * obj.Radius.^2; % number of pixels in cicle
            % TODO die Berechnung von N Pixeln in mm^2 pr�fen
            crossSectionArea.MM = crossSectionArea.Px * obj.MMPerPx.^2; % px* mm/px*mm/px with px^2=px
            crossSectionArea.MeanMM = mean(crossSectionArea.MM, 'omitnan');
            crossSectionArea.MedianMM = median(crossSectionArea.MM, 'omitnan');
        end
        
        function obj = set.PositionInImage(obj, positionInImage)
            
            obj.PositionInImage = positionInImage;
            
        end
        
        function out = get.DistanceToNextW(obj)
            out = DistanceToNextWire;
            %         VectorsPx
            %         VectorsMM
            %         MedianVector
            %         MedianNorm
            %         MeanVector
            %         MeanNorm
            srt_cntrs = sortrows(obj.PositionInImage);
            cntrs_dst = zeros(size(srt_cntrs, 1) - 1, 2);
            
            for nn = 1:(size(srt_cntrs, 1) - 1)
                cntrs_dst(nn, 1) = srt_cntrs(nn + 1, 1) - srt_cntrs(nn, 1);
                cntrs_dst(nn, 2) = srt_cntrs(nn + 1, 2) - srt_cntrs(nn, 2);
            end
            
            out.VectorsPx = cntrs_dst;
            out.VectorsPx(abs(out.VectorsPx) > obj.DistanceThreshold) = NaN;
            out.VectorsMM = out.VectorsPx * obj.MMPerPx;
            out.MedianVector = median(out.VectorsMM, 'omitnan');
            out.MedianNorm = norm(out.MedianVector);
            out.MeanVector = mean(out.VectorsMM, 'omitnan');
            out.MeanNorm = norm(out.MeanVector);
            
        end
        
        %% Methods
        
        
        
        
        
        function obj = findCapPly(obj,deltaArg)
            %use deltaArg for runs without User Input. eg. deltaArg=16
            %this function return a wire object with recocgnized CapPly layer properties
            global delta;
            if nargin>1
                delta=deltaArg;
            end
            name = obj.FileName;
            img = obj.ImageOriginal;
            
            % Stahl Lage entfernen (helle Werte > 60) um nur CapPly zu erkennen
            steel_grayvalue = obj.SteelGrayvalueThreshold;
            img(img > steel_grayvalue) = 30;
            thresholded_img = img;
            % Adaptive Histogram sorgt für starke Kontraste
            contrast_img = adapthisteq(thresholded_img, 'clipLimit', 0.5, 'Distribution', 'rayleigh');
            figure, imshowpair(thresholded_img, contrast_img, 'montage');
            title('Original Image (left) and Contrast Enhanced Image (right)');
            % segmentImageAdaptiveThreshold filtert dunklen Hintergrund weg
            [BW_Mask_afterThreshold, masked_contrast_img] = Wire.segmentImageAdaptiveThreshold(contrast_img);
            figure, imshowpair(BW_Mask_afterThreshold, masked_contrast_img, 'montage');
            title('BW_Mask_afterThreshold (left) and masked_contrast_img (right)');
            obj.ImageProcessed=masked_contrast_img;
            close all
            
            img=obj.ImageProcessed;
            % ROI Spline auswaehlen
            figureHandle = figure('keypressfcn', @Wire.functionHandle_KeyPressFcn);
            imshow(img);
            figureHandle.WindowState = 'fullscreen';
            axis manual;
            axis([0 length(img(1, :)) 0 length(img(1, :)) / 1.6]);
            
            % hier werden manuell Punkte entlang der CapPly gewählt oder alte Daten geladen
            mkdir('selectedPoints');
            
            if (isfile(fullfile('selectedPoints', [name '.mat'])) && obj.UseOldSpline)
                load(fullfile('selectedPoints', [name '.mat']), 'X', 'Y')
            else
                title(' Zoome und druecke Enter');
                zoom on;
                waitfor(gcf, 'CurrentCharacter', char(13))
                zoom reset
                zoom off
                [X, Y] = Wire.selectPoints(figureHandle);
                save(fullfile('selectedPoints', name), 'X', 'Y')
                
            end
            
            xgrid = 1:1:length(img(1, :));
            yspline = spline(X, Y, xgrid);
            hold on;
            plot(X, Y, 'o', xgrid, yspline);
            if nargin==1
                Wire.plotEinhuellende(figureHandle,gca(), xgrid, yspline);
            end
            
            % Schneide alle PixelWerte weg die nicht im ROI liegen
            newmask = Wire.createMaskfrom(img,yspline,delta);
            bw_img_masked_withSplineROI = BW_Mask_afterThreshold;
            bw_img_masked_withSplineROI(~newmask) = 0;
            
            % Erosion durchführen um Rauschen zu entfernen
            structuring_element = strel('disk', 3, 0); % radius, aproxx. line elements
            
            bw_img_masked_withSplineROI_Opened = imopen(bw_img_masked_withSplineROI, structuring_element);
            figure, imshowpair(bw_img_masked_withSplineROI, bw_img_masked_withSplineROI_Opened, 'montage');
            title('normal vs opened')
            obj.ImageUsedForCV = bw_img_masked_withSplineROI_Opened;
            close all;
            % nun sind alle Image PreProcessing Schritte fertig.
            % finde in initData() die Wire Koordinaten und Radii usw.
            obj = obj.initData();
            % Outlier werden nur im manuellen Modus (nargin==1) entfernt
            if nargin==1
                obj = obj.removeOutliers();
            end
            
            
            close all;
        end
        
        function [obj, upperLayerObj, lowerLayerObj] = findWiresAndSplitSteelLayers(oldObj,deltaArg)
            close all;

            global delta;
            if nargin>1
                delta=deltaArg;
            end
            
            % kein Preprocessing nötig bei SteelPly, direkt finden der Wire Koordinaten und Radii
            obj=oldObj.initData();
            img=obj.ImageOriginal;
            % anschließendes reduzieren auf ROI mithilfe von Polynom fits
            [obj,xPolyCoord,yPolyCoord]=obj.fitPolynom(2);

            
            figureHandle = figure('keypressfcn', @Wire.functionHandle_KeyPressFcn);
            figureHandle.WindowState = 'fullscreen';
            imshow(img);
            hold on;
            
            plot(xPolyCoord, yPolyCoord, 'LineWidth', 2, 'Color', 'green');
            
            %% eine manuelle ROI ausw�hlen (Delta Kriterium in |y| )
            if nargin ==1
                Wire.plotEinhuellende(figureHandle,gca(), xPolyCoord, yPolyCoord);
            end
            
            %% Eine Maske mit dem neuen ROI erstellen
            mask = Wire.createMaskfrom(img,yPolyCoord,delta);
            
            %% entfernen der Outliers (Kreise ausserhalb des ROIs)
            obj=obj.removeOutliersFromMask(mask);
            
            
            %% neuer Polyfit mit deg=6 diesmal ohne Outliers
            [obj,xPolyCoord,yPolyCoord]=obj.fitPolynom(6);
            plot(xPolyCoord, yPolyCoord, 'LineWidth', 2, 'Color', 'green');

            
            
            
            %% eine manuelle ROI ausw�hlen (Delta Kriterium in |y| )
            if nargin ==1
                Wire.plotEinhuellende(figureHandle,gca(), xPolyCoord, yPolyCoord);
            end
            if nargin>1
                delta=40;
            end
            
            
            %% Eine Maske mit dem neuen ROI erstellen
            mask = Wire.createMaskfrom(img,yPolyCoord,delta);
            obj=obj.removeOutliersFromMask(mask);
            %%  weitere Outliers nur manuell entfernen
            if nargin==1
                obj=obj.removeOutliers();
            end
            
            new_radii = obj.Radius;
            new_centers = obj.PositionInImage;
            
            % Teile die Wires anhand des Polynoms in upper/lower
            % wenn Koordinaten über yPolyCoord liegen oben sonst unten
            upper_centers = [];
            upper_radii = [];
            lower_centers = [];
            lower_radii = [];
            
            for nn = 1:size(new_centers, 1)
                
                if new_centers(nn, 2) < yPolyCoord(round(new_centers(nn, 1)))
                    upper_centers = cat(1, upper_centers, new_centers(nn, :));
                    upper_radii = cat(1, upper_radii, new_radii(nn));
                end
                
                if new_centers(nn, 2) >= yPolyCoord(round(new_centers(nn, 1)))
                    lower_centers = cat(1, lower_centers, new_centers(nn, :));
                    lower_radii = cat(1, lower_radii, new_radii(nn));
                end
                
            end
            % erstelle return DoubleWire Objekte Upper/Lower
            upperLayerObj = DoubleWire(obj);
            upperLayerObj.PositionInImage = upper_centers;
            upperLayerObj.Radius = upper_radii;
            
            lowerLayerObj = DoubleWire(obj);
            lowerLayerObj.PositionInImage = lower_centers;
            lowerLayerObj.Radius = lower_radii;
            lowerLayerObj.LayerLevel=2;
            close all;
        end
        
        % Plotting Methods
        function figurehandle=plot(obj)
            figurehandle=figure;
            imshow(obj.ImageOriginal);
            title(sprintf('Plot of %s: recognized wires(%f) and distances(%f)', obj.Name,obj.RadiusMedian, obj.DistanceToNextW.MedianNorm));
            
            hold on
            plot(obj.PositionInImage(:, 1), obj.PositionInImage(:, 2), 'o', 'LineWidth', 2, 'XDataSource', 'obj.PositionInImage(:, 1)', 'YDataSource', 'obj.PositionInImage(:, 2)','ZDataSource', 'obj.Radius');
            viscircles(obj.PositionInImage,obj.Radius);
            obj.quiverPlot();
            hold off
        end
        
        
        function fighandle = plotDistanceToNextWire(obj)
            fighandle = figure;
            hold on
            title(sprintf('Abstandsverteilung von %s: %s ueber X Koordinate in [mm]', obj.FileName, obj.Name));
            plot(obj.PositionInImageMM(1:end - 1, 1), obj.DistanceToNextW.VectorsMM(:, 1), '.');
            plot(obj.PositionInImageMM(1:end - 1, 1), norm(obj.DistanceToNextW.VectorsMM), 'x');
            legend('Only X Distance', 'Norm of (X,Y) Distance');
            hold off
        end
        
        function obj = removeOutliers(obj)
            fh=figure('WindowState', 'maximized');
            imshow(obj.ImageProcessed);
            X=obj.PositionInImage(:, 1);
            Y=obj.PositionInImage(:, 2);
            Z=obj.Radius;
            hold on
            plot(X,Y, 'o', 'LineWidth', 2, 'XDataSource', 'X', 'YDataSource', 'Y','ZDataSource', 'Z');
            
            %% hier kann im Plot falsche Daten mit Tool -->brusch +link entfernt werden
            title('L�sche Outlier: Linksclick oder Rechtecksauswahl (mit Shift f�r mehrere) dann Rechtsclick auf einen der roten Punkte --> Remove');
            warninghandle=warndlg('Loeschen von Outliern nur mit Rechtsclick, nicht Tastatur Delete! ');
            
            linkdata on;
            brush on;
            
            %% da brushing nur im debug modus funktioniert.
            doneHandle = uicontrol('String', 'Done', 'Callback', {@(src, evt)(com.mathworks.mlservices.MLExecuteServices.consoleEval('dbcont'))}');
            keyboard;
            obj.PositionInImage=[X,Y];
            obj.Radius=Z;
            brush off;
            linkdata off;
            close(fh);
            if(ishandle(warninghandle))
                close(warninghandle);
            end
            hold off;
        end
        
        function [] = plotDistribution(obj)
            centers_dst_filtered = sqrt(((nonzeros(obj.DistanceToNextW.VectorsMM(:, 1)))).^2 ...
                + ((nonzeros(obj.DistanceToNextW.VectorsMM(:, 2)))).^2);
            
            distance_cap_mean=obj.DistanceToNextW.MeanNorm;
            figure;
            histo_dist_X = histogram(nonzeros(centers_dst_filtered), 50, 'Normalization', 'pdf');
            title('Histogram der Abstaende');
            %         Check why its flat...
            %         hold on
            %         y = nonzeros(centers_dst_filtered);
            %         y = sort(y);
            %         mu = distance_cap_mean;
            %         sigma = 4;
            %         f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
            %         plot(y, f, 'LineWidth', 1.5)
            %         hold off
            
        end
        
    end
    
    %% Private Methods
    methods(Access=private)
        function obj = initData(obj)
            
            if (isempty(obj.ImageUsedForCV))
                obj.ImageUsedForCV = obj.ImageOriginal;
            end
            if (isempty(obj.ImageProcessed))
                obj.ImageProcessed = obj.ImageOriginal;
            end
            if (obj.WireMaterial == Material.Steel)
                obj.SensitivityLvL = 0.95;
                obj.MaxNoOfCircles = 450;
                obj.MinimumRadius = 3 * 600 / obj.DPI; 
                obj.MaximumRadius = 7 * 600 / obj.DPI;
            end
            
            if (obj.WireMaterial == Material.Polymer)
                obj.SensitivityLvL = 0.95;
                obj.MaxNoOfCircles = 60;
                obj.MinimumRadius = 6 * 600 / obj.DPI;
                obj.MaximumRadius = 10 * 600 / obj.DPI;
            end
            
            [~, ~, centers, radii] = Wire.segmentImageCircles(obj.ImageUsedForCV, ...
                obj.SensitivityLvL, obj.MaximumRadius, obj.MinimumRadius, obj.MaxNoOfCircles);
            
            obj.PositionInImage = centers;
            obj.Radius = radii;
            
        end
        
        function fh = quiverPlot(obj)
            srt_cntrs = sortrows(obj.PositionInImage);
            cntrs_dst = obj.DistanceToNextW.VectorsPx;
            hold on
            fh = quiver(srt_cntrs(1:end - 1, 1), srt_cntrs(1:end - 1, 2), cntrs_dst(:, 1), cntrs_dst(:, 2), 0);
            hold off
        end
        
        function obj=removeOutliersFromMask(obj,mask)
            centers = obj.PositionInImage;
            radii = obj.Radius;
            img = obj.ImageOriginal;
            new_centers = [];
            new_radii = [];
            
            for nn = 1:size(centers, 1)
                
                if mask(round(centers(nn, 2)), round(centers(nn, 1))) == true
                    new_centers = cat(1, new_centers, centers(nn, :));
                    new_radii = cat(1, new_radii, radii(nn, :));
                end
                
            end
            
            obj.PositionInImage = new_centers;
            obj.Radius = new_radii;
            
            img_masked_withPolyROI = img;
            img_masked_withPolyROI(~mask) = 0;
            obj.ImageUsedForCV = img_masked_withPolyROI;
            
        end
        function [obj,xPolyCoord,yPolyCoord]=fitPolynom(obj,degreeOfPoly)
            centers = obj.PositionInImage;
            radii = obj.Radius;
            img = obj.ImageOriginal;
            p = polyfit(centers(:, 1), centers(:, 2), degreeOfPoly);
            n = length(img(1, :));
            xPolyCoord = linspace(0, length(img(1, :)), n);
            yPolyCoord = polyval(p, xPolyCoord);
        end
    end
    
    
    %% Static Methods
    methods (Static)
        
        function [BW, maskedImage] = segmentImageAdaptiveThreshold(X)
            % Threshold image - adaptive threshold
            BW = imbinarize(X, 'adaptive', 'Sensitivity', 0.340000, 'ForegroundPolarity', 'bright');
            
            % Create masked image.
            maskedImage = X;
            maskedImage(~BW) = 0;
        end
        
        function mask = createMaskfrom(img,yPolyCoord,delta)
            mask = false(size(img, 1), size(img, 2));
            
            for xx = 1:length(img(1, :))
                
                for yy = 1:length(img(:, 1))
                    
                    if (abs(yy - yPolyCoord(xx)) <= delta)
                        mask(yy, xx) = true;
                    end
                    
                end
                
            end
        end
        
        
        
        function [BW,maskedImage,centers,radii] = segmentImageCircles(X,sensitivity,maxRad,minRad,maxN)
            
            % Find circles
            [centers,radii,~] = imfindcircles(X,[minRad maxRad],'ObjectPolarity','bright','Sensitivity',sensitivity);
            BW = false(size(X,1),size(X,2));
            [Xgrid,Ygrid] = meshgrid(1:size(BW,2),1:size(BW,1));
            for n = 1:maxN
                BW = BW | (hypot(Xgrid-centers(n,1),Ygrid-centers(n,2)) <= radii(n));
            end
            
            % Create masked image.
            maskedImage = X;
            maskedImage(~BW) = 0;
        end
        

        
        
        function [x, y] = selectPoints(figurehandle)
            ph = pan(figurehandle);
            x = [];
            y = [];
            while (true)
                title('waehle die Stuetzpunkte im Bild aus mit linker Maustaste! Return/Eingabe um zu bestaetigen');
                
                [x_buff, y_buff] = ginput;
                x = cat(1, x, x_buff);
                y = cat(1, y, y_buff);
                
                title(' pan (verschiebe) und druecke Space, dann wieder Stuetzpunkte auswaehlen. q fuer quit / beenden');
                
                ph.Enable = 'on';
                btn = 0;
                
                while (btn == 0)
                    btn = waitforbuttonpress;
                end
                
                if (figurehandle.CurrentCharacter == ' ')
                    ph.Enable = 'off';
                end
                
                if (figurehandle.CurrentCharacter == 'q')
                    ph.Enable = 'off';
                    
                    break;
                end
                
            end
            
        end
        
        % function der als callback in figure den ROI (mithilfe delta) anpasst mit arrow up/down
        function [] = functionHandle_KeyPressFcn(H, E)
            % Figure keypressfcn
            global delta
            
            
            switch E.Key
                
                case 'rightarrow'
                case 'leftarrow'
                case 'uparrow'
                    delta = delta + 1;
                case 'downarrow'
                    delta = delta - 1;
                    
                otherwise
            end
            
        end
        
        function [] = plotEinhuellende(figurehandle,figureaxis, xPolyCoord, yPolyCoord)
            global delta
            
            if isempty(delta)
                delta=0;
            end
            
            hold(figureaxis, 'on');
            while (true)
                linehandle = plot(figureaxis,xPolyCoord, yPolyCoord + delta, 'm--', xPolyCoord, yPolyCoord - delta, 'm--');
                title(['Druecke Up/Down Arrow um den Bereich der entsprechenden '...
                    'Drahtlage(n) komplett mit dem pinken Bereich einzuschliessen' newline...
                    'Druecke anschliessend Enter!']);
                waitforbuttonpress;
                
                if (figurehandle.CurrentCharacter == char(13))%% enter
                    title('Beendet!')
                    
                    break;
                end
                
                children = get(gca, 'children');
                delete(children(1));
                delete(children(2));
            end
            hold (figureaxis,'off');
        end
        
        
    end
    
end
