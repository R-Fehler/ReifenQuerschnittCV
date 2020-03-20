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
        %Vectors
        PositionInImageMM
        % Objects
        CrossSectionA
        DistanceToNextW
        DistanceThreshold %[px] threshold to ignore neighbouring wires


    end
    %% Public Methods
    methods

        %% Constructor (hier keiner)
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
            crossSectionArea.MM = crossSectionArea.Px * obj.MMPerPx.^2; % px*mm/px*mm/px with px^2=px
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

        % plots quivers on top of original image
 

       

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
            figure, imshow(obj.ImageOriginal);
            X=obj.PositionInImage(:, 1);
            Y=obj.PositionInImage(:, 2);
            Z=obj.Radius;
            hold on
            plot(X,Y, 'o', 'LineWidth', 2, 'XDataSource', 'X', 'YDataSource', 'Y','ZDataSource', 'Z');
            
            %% hier kann im Plot falsche Daten mit Tool -->brusch +link entfernt werden
            title('Loesche ungewollte Mittelpunkte mit Link und Brush Tool bei Bedarf ACHTUNG: Rechtsklick und Remove! ');
            warndlg('L�schen von Outliern nur mit Rechtsclick --> Remove (im Debug Mode)');
         
            linkdata on;
            brush on;

            %% da brushing nur im debug modus funktioniert.
            doneHandle = uicontrol('String', 'Done', 'Callback', {@(src, evt)(com.mathworks.mlservices.MLExecuteServices.consoleEval('dbcont'))}');
            keyboard;
            obj.PositionInImage=[X,Y];
            obj.Radius=Z;
            brush off;
            linkdata off;
            close gcf;
        end

        function obj = findCapPly(obj)
            global delta;
            name = obj.FileName;
            img = obj.ImageOriginal;

            % Stahl Lage entfernen (helle Werte >60)
            steel_grayvalue = obj.SteelGrayvalueThreshold;
            img(img > steel_grayvalue) = 30;
            thresholded_img = img;

            contrast_img = adapthisteq(thresholded_img, 'clipLimit', 0.5, 'Distribution', 'rayleigh');
            figure, imshowpair(thresholded_img, contrast_img, 'montage');
            title('Original Image (left) and Contrast Enhanced Image (right)');

            [BW_Mask_afterThreshold, masked_contrast_img] = Wire.segmentImageAdaptiveThreshold(contrast_img);
            figure, imshowpair(BW_Mask_afterThreshold, masked_contrast_img, 'montage');
            title('BW_Mask_afterThreshold (left) and masked_contrast_img (right)');
            obj.ImageProcessed=masked_contrast_img;
            close all

            % ROI Spline auswaehlen
            figureHandle = figure('keypressfcn', @Wire.functionHandle_KeyPressFcn);
            imshow(img);
            figureHandle.WindowState = 'fullscreen';
            axis manual;
            axis([0 length(img(1, :)) 0 length(img(1, :)) / 1.6]);


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

            Wire.plotEinhuellende(figureHandle, xgrid, yspline);
            newmask = false(size(img, 1), size(img, 2));

            for xn = 1:1:length(img(1, :))

                for yn = 1:length(img(:, 1))

                    if (abs(yn - yspline(xn)) <= delta)
                        newmask(yn, xn) = true;
                    end

                end

            end

            bw_img_masked_withSplineROI = BW_Mask_afterThreshold;
            bw_img_masked_withSplineROI(~newmask) = 0;

            structuring_element = strel('disk', 3, 0); % radius, aproxx. line elements

            bw_img_masked_withSplineROI_Opened = imopen(bw_img_masked_withSplineROI, structuring_element);
            figure, imshowpair(bw_img_masked_withSplineROI, bw_img_masked_withSplineROI_Opened, 'montage');
            title('normal vs opened')
            obj.ImageUsedForCV = bw_img_masked_withSplineROI_Opened;
            close all;
            obj = obj.initData();
            obj = obj.removeOutliers();

        end

        function [obj, upperLayerObj, lowerLayerObj] = splitSteelLayers(oldObj)
            global delta;
            obj=oldObj.initData();

            centers = obj.PositionInImage;
            radii = obj.Radius;
            img = obj.ImageOriginal;
            p = polyfit(centers(:, 1), centers(:, 2), 2);
            n = length(img(1, :));
            x1 = linspace(0, length(img(1, :)), n);
            y1 = polyval(p, x1);
            
              figureHandle = figure('keypressfcn', @Wire.functionHandle_KeyPressFcn);
            imshow(img);
            figureHandle.WindowState = 'fullscreen';
            hold on;
            plot(x1, y1, 'LineWidth', 2, 'Color', 'green');

            %% eine manuelle ROI ausw�hlen (Delta Kriterium in |y| )
            Wire.plotEinhuellende(figureHandle, x1, y1);
            close gcf;

            %% Eine Maske mit dem neuen ROI erstellen
            mask = false(size(img, 1), size(img, 2));

            for xx = 1:length(img(1, :))

                for yy = 1:length(img(:, 1))

                    if (abs(yy - y1(xx)) <= delta)
                        mask(yy, xx) = true;
                    end

                end

            end

            %% entfernen der Outliers (Kreise ausserhalb des ROIs)
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


            %% neuer Polyfit mit deg=6 diesmal ohne Outliers
            p = polyfit(new_centers(:, 1), new_centers(:, 2), 6);
            n = length(img(1, :));
            x1 = linspace(0, length(img(1, :)), n);
            y1 = polyval(p, x1);

                  obj=obj.removeOutliers();
            new_radii = obj.Radius; % werden entfernt
            new_centers = obj.PositionInImage; % werden nicht entfernt

            upper_centers = [];
            upper_radii = [];
            lower_centers = [];
            lower_radii = [];

            for nn = 1:size(new_centers, 1)

                if new_centers(nn, 2) < y1(round(new_centers(nn, 1)))
                    upper_centers = cat(1, upper_centers, new_centers(nn, :));
                    upper_radii = cat(1, upper_radii, new_radii(nn));
                end

                if new_centers(nn, 2) >= y1(round(new_centers(nn, 1)))
                    lower_centers = cat(1, lower_centers, new_centers(nn, :));
                    lower_radii = cat(1, lower_radii, new_radii(nn));
                end

            end

            upperLayerObj = DoubleWire(obj);
            upperLayerObj.PositionInImage = upper_centers;
            upperLayerObj.Radius = upper_radii;

            lowerLayerObj = DoubleWire(obj);
            lowerLayerObj.PositionInImage = lower_centers;
            lowerLayerObj.Radius = lower_radii;
            lowerLayerObj.LayerLevel=2;

            figure, imshow(obj.ImageOriginal);
            hold on;

            plot(upper_centers(:, 1), upper_centers(:, 2), 'x', 'LineWidth', 2);
            plot(lower_centers(:, 1), lower_centers(:, 2), 'x', 'LineWidth', 2);
            hold off;
    
            


            
        end
        
        function figurehandle=plot(obj)
            figurehandle=figure;
            imshow(obj.ImageOriginal);

            hold on
            plot(obj.PositionInImage(:, 1), obj.PositionInImage(:, 2), 'o', 'LineWidth', 2, 'XDataSource', 'obj.PositionInImage(:, 1)', 'YDataSource', 'obj.PositionInImage(:, 2)','ZDataSource', 'obj.Radius');
            viscircles(obj.PositionInImage,obj.Radius);
            obj.quiverPlot();
        end
        
        function [] = plotDistribution(obj)
        
         centers_dst_filtered=norm(obj.DistanceToNextW.VectorsMM);
         distance_cap_mean=obj.DistanceToNextW.MeanNorm;
         figure;
        histo_dist_X = histogram(nonzeros(centers_dst_filtered), 50, 'Normalization', 'pdf');
        hold on
        y = nonzeros(centers_dst_filtered);
        y = sort(y);
        mu = distance_cap_mean;
        sigma = 4;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5)
        title('Histogram der gefilterten Abstaende');
        hold off

    end 

    end

    %% Private Methods
    methods(Access=private)
         function obj = initData(obj)
          
            if (isempty(obj.ImageUsedForCV))
                obj.ImageUsedForCV = obj.ImageOriginal;
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

            [~, ~, centers, radii] = segmentImageCircles(obj.ImageUsedForCV, ...
                obj.SensitivityLvL, obj.MaximumRadius, obj.MinimumRadius, obj.MaxNoOfCircles);

            obj.PositionInImage = centers;
            obj.Radius = radii;

         end
        
                function fh = quiverPlot(obj)
            srt_cntrs = sortrows(obj.PositionInImage);
            cntrs_dst = obj.DistanceToNextW.VectorsPx;
            hold on
            title(sprintf('Plot of %s: recognized wires and distances', obj.Name));
            fh = quiver(srt_cntrs(1:end - 1, 1), srt_cntrs(1:end - 1, 2), cntrs_dst(:, 1), cntrs_dst(:, 2), 0);
            hold off
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

        function [x, y] = selectPoints(figurehandle)
            ph = pan(figurehandle);
                x = [];
                y = [];
            while (true)
                title('waehle die Kreuze aus mit linker Maustaste! Return/Eingabe um zu bestaetigen');

                [x_buff, y_buff] = ginput;
                x = cat(1, x, x_buff);
                y = cat(1, y, y_buff);

                title(' pan und druecke Space. q fuer quit / beenden');

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

        function [] = plotEinhuellende(figurehandle, x1, y1)
            global delta
            delta=0;


            while (true)
                linehandle = plot(x1, y1 + delta, 'm--', x1, y1 - delta, 'm--');
                title('up/down arrow um Einh�llende zu fitten')
                waitforbuttonpress;

                if (figurehandle.CurrentCharacter == char(13))%% enter
                    title('Beendet!')

                    break;
                end

                children = get(gca, 'children');
                delete(children(1));
                delete(children(2));
            end

        end
        
        
    end

end
