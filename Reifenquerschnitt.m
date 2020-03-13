%% Reifenquerschnittsauswertung: Stahl und Cap Ply
% Skript um den Querschnitt zu analysieren

function [] = Reifenquerschnitt()

    clearvars;
    close all; clc;

    use_denoise_CNN = false;
    use_old_spline = true;
    doPlotDistribution = true;

    %% Runtime Parameter
    %% Einlesen der Bilder
    [path, cancelled] = uigetimagefile();
    [filepath, name, ext] = fileparts(path);

    if (cancelled)
        error('kein Image gew�hlt');
    end

    %% look ahead / behind und groups dann brauch ich kein split mehr.
    dpi_string = regexp(name, '(?<=_)\d*(?=dpi)', 'match', 'once'); %lookaround regex
    %     regexp('bla_600dpi', '(?<=_)\d*(?=dpi)', 'match', 'once') % ans='600'
    if isempty(dpi_string)
        error('Name keine korrekte DPI angabe');
    end

    dpi_value = str2num(dpi_string);
    img = imread(path);

    cap=WireClass;
    uSteel=WireClass;
    lSteel=WireClass;
    cap.Material='polymer';
    uSteel.Material='steel';
    lSteel.Material='steel';
    cap.Image=img;
    uSteel.Image=img;
    lSteel.Image=img;
    cap.Name=regexp(name, '.*(?=_\d*dpi)', 'match', 'once');
    uSteel.Name=cap.Name;
    lSteel.Name=cap.Name;
    
    cap.DPI=dpi_value;
    
    findCapPly(img, name);

    figHandle = figure('keypressfcn', @functionHandle_KeyPressFcn), imshow(img);

    sensitivity = 0.95;
    maxN_Circles = 450;
    minRad = 3; %% bei 96 dpi
    maxRad = 7; %% bei 96 dpi
    delta = 0;

    %% Kreise Segmentieren (Stahl)
    [BW, maskedImg, centers, radii] = segmentImageCircles(img, sensitivity, maxRad, minRad, maxN_Circles);

    imshow(BW);
    hold on
    plot(centers(:, 1), centers(:, 2), 'o', 'LineWidth', 2); %% hier kann im Plot falsche Daten mit Tool -->brusch +link entfernt werden
    %% Polynom mit den Kreismittelpunkten fitten
    p = polyfit(centers(:, 1), centers(:, 2), 2);
    n = length(img(1, :));
    x1 = linspace(0, length(img(1, :)), n);
    y1 = polyval(p, x1);

    plot(x1, y1, 'LineWidth', 2, 'Color', 'green');

    %% eine manuelle ROI ausw�hlen (Delta Kriterium in |y| )
    plotEinhuellende(figHandle, x1, y1);
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

    img_masked_withPolyROI = img;
    img_masked_withPolyROI(~mask) = 0;

    figHandle = figure, imshow(img_masked_withPolyROI);
    hold on

    %% neuer Polyfit mit deg=6 diesmal ohne Outliers
    p = polyfit(new_centers(:, 1), new_centers(:, 2), 6);
    n = length(img(1, :));
    x1 = linspace(0, length(img(1, :)), n);
    y1 = polyval(p, x1);

    %% linked brushing funktioniert nur im breakpoint/keyboard modus!! Daten
    title('L�sche ungewollte Mittelpunkte mit Link und Brush Tool bei Bedarf,Press Debug Continue,Press Done');
    plot(new_centers(:, 1), new_centers(:, 2), 'o', 'LineWidth', 2, ...
        'XDataSource', 'new_centers(:,1)', 'YDataSource', 'new_centers(:,2)', 'ZDataSource', 'new_radii');
    warndlg('L�schen von Outliern nur mit Rechtsclick --> Remove (im Debug Mode)');
    linkdata on;
    brush on;

    doneHandle = uicontrol('String', 'Done', 'Callback', {@evaluateSteelPlyData}');
    keyboard
    %% ENTER dbcont in K>> console

    function [] = evaluateSteelPlyData(src, evt)

        %% Kreise in oberhalb und unterhalb des Polynoms einteilen

        linkdata off;
        brush off;
        delete(doneHandle)
        plot(x1, y1, 'LineWidth', 2, 'Color', 'green');

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

        imshow(img_masked_withPolyROI);
        hold on;

        plot(upper_centers(:, 1), upper_centers(:, 2), 'x', 'LineWidth', 2);
        waitforbuttonpress;
        plot(lower_centers(:, 1), lower_centers(:, 2), 'x', 'LineWidth', 2);

        %% Berechnen der A und D Werte
        A_s_upper = pi * upper_radii.^2;
        A_s_upper_avg = mean(A_s_upper, 'omitnan')
        A_s_upper_avg_mm = mean(A_s_upper, 'omitnan') * mm_per_pixel * mm_per_pixel
        A_s_upper_median = median(A_s_upper, 'omitnan')
        A_s_upper_median_mm = median(A_s_upper, 'omitnan') * mm_per_pixel * mm_per_pixel
        D_s_upper = upper_radii * 2;
        D_s_upper_avg = mean(D_s_upper);

        A_s_lower = pi * lower_radii.^2;
        A_s_lower_avg = mean(A_s_lower, 'omitnan')
        A_s_lower_avg_mm = mean(A_s_lower, 'omitnan') * mm_per_pixel * mm_per_pixel
        A_s_lower_median = median(A_s_lower, 'omitnan')
        A_s_lower_median_mm = median(A_s_lower, 'omitnan') * mm_per_pixel * mm_per_pixel
        D_s_lower = lower_radii * 2;
        D_s_lower_avg = mean(D_s_lower);

        upper_avg_centers = zeros(size(upper_centers, 1), 2);
        lower_avg_centers = zeros(size(upper_centers, 1), 2);

        %% mittelpunkte upper stahl � zwischen beiden Draehten
        for nn = 1:size(upper_centers, 1)

            for mm = 1:size(upper_centers, 1)

                if (norm(upper_centers(nn) - upper_centers(mm)) < 1.5 * D_s_upper_avg && mm ~= nn)

                    upper_avg_centers(nn, 1) = (upper_centers(nn, 1) + upper_centers(mm, 1)) / 2;
                    upper_avg_centers(nn, 2) = (upper_centers(nn, 2) + upper_centers(mm, 2)) / 2;

                end

            end

            if upper_avg_centers(nn, 1) == 0%% wenn nur ein kreis erkannt wird setzte diesen als  Mittelpunkt
                upper_avg_centers(nn, 1) = upper_centers(nn, 1);
                upper_avg_centers(nn, 2) = upper_centers(nn, 2);
            end

        end

        %% abst�nde upper stahl  � zwischen beiden Draehten
        sorted_upper_avg_centers = sortrows(upper_avg_centers);

        for nn = 1:(size(upper_avg_centers, 1) - 1)

            upper_avg_centers_dst(nn, 1) = sorted_upper_avg_centers(nn + 1, 1) - sorted_upper_avg_centers(nn, 1);
            upper_avg_centers_dst(nn, 2) = sorted_upper_avg_centers(nn + 1, 2) - sorted_upper_avg_centers(nn, 2);

        end

        %% mittelpunkte lower stahl  � zwischen beiden Draehten
        for nn = 1:size(lower_centers, 1)

            for mm = 1:size(lower_centers, 1)

                if (norm(lower_centers(nn) - lower_centers(mm)) < 1.5 * D_s_upper_avg && mm ~= nn)

                    lower_avg_centers(nn, 1) = (lower_centers(nn, 1) + lower_centers(mm, 1)) / 2;
                    lower_avg_centers(nn, 2) = (lower_centers(nn, 2) + lower_centers(mm, 2)) / 2;

                end

            end

            if lower_avg_centers(nn, 1) == 0%% wenn nur ein kreis erkannt wird setzte diesen als  Mittelpunkt
                lower_avg_centers(nn, 1) = lower_centers(nn, 1);
                lower_avg_centers(nn, 2) = lower_centers(nn, 2);
            end

        end

        %% abst�nde lower stahl  � zwischen beiden Draehten
        sorted_lower_avg_centers = sortrows(lower_avg_centers);

        for nn = 1:(size(lower_avg_centers, 1) - 1)

            lower_avg_centers_dst(nn, 1) = sorted_lower_avg_centers(nn + 1, 1) - sorted_lower_avg_centers(nn, 1);
            lower_avg_centers_dst(nn, 2) = sorted_lower_avg_centers(nn + 1, 2) - sorted_lower_avg_centers(nn, 2);

        end

        plot(upper_avg_centers(:, 1), upper_avg_centers(:, 2), 'x', 'LineWidth', 2);
        plot(lower_avg_centers(:, 1), lower_avg_centers(:, 2), 'x', 'LineWidth', 2);
        waitforbuttonpress;

        p_upper = sorted_upper_avg_centers;
        dp_upper = upper_avg_centers_dst;
        quiver(p_upper(1:end - 1, 1), p_upper(1:end - 1, 2), dp_upper(:, 1), dp_upper(:, 2), 0)

        % norm() call instead
        distanceUpper = sqrt((mean(nonzeros(dp_upper(:, 1))))^2 + (mean(nonzeros(dp_upper(:, 2))))^2)
        distanceUpper_mm = sqrt((mean(nonzeros(dp_upper(:, 1))))^2 + (mean(nonzeros(dp_upper(:, 2))))^2) * mm_per_pixel

        p_lower = sorted_lower_avg_centers;
        dp_lower = lower_avg_centers_dst;
        quiver(p_lower(1:end - 1, 1), p_lower(1:end - 1, 2), dp_lower(:, 1), dp_lower(:, 2), 0)
        distanceLower = sqrt((mean(nonzeros(dp_lower(:, 1))))^2 + (mean(nonzeros(dp_lower(:, 2))))^2)
        distanceLower_mm = sqrt((mean(nonzeros(dp_lower(:, 1))))^2 + (mean(nonzeros(dp_lower(:, 2))))^2) * mm_per_pixel

        waitforbuttonpress;
        viscircles(upper_centers, upper_radii, 'EdgeColor', 'r');

        viscircles(lower_centers, lower_radii, 'EdgeColor', 'b');

        %% plotte die Abstände zwischen Stahldrahten
        figure;
        sgtitle('Abstandsverteilung der Stahldraehte ueber X Koordinate in [mm]');
        subplot(1, 2, 1), plot(p_upper(1:end - 1, 1) * mm_per_pixel, dp_upper(:, 1) * mm_per_pixel, '.');
        title('Upper Layer');
        subplot(1, 2, 2), plot(p_lower(1:end - 1, 1) * mm_per_pixel, dp_lower(:, 1) * mm_per_pixel, '.');
        title('Lower Layer');

        if (doPlotDistribution == true)
            plotDistribution(dp_upper, dp_lower, distanceUpper, distanceLower)
        end

        keyboard;

    end

    function [] = plotDistribution(dp_upper, dp_lower, distanceUpper, distanceLower)
        figure;
        %% Plotte die Distributionen der Abstände mit Zwischenabstand
        sgtitle('Distributionen der Abstaende SteelPly')
        subplot(2, 2, 1), histo_upper_complete = histogram(nonzeros(dp_upper) * mm_per_pixel, 100, 'Normalization', 'pdf');
        title('Histogram Upper Layer With Neighbouring Steelwires');
        hold on
        y = nonzeros(dp_upper) * mm_per_pixel;
        y(y < 10) = NaN;
        y = sort(y);
        mu = distanceUpper * mm_per_pixel;
        sigma = 4;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5)
        hold off
        subplot(2, 2, 2), histo_lower_complete = histogram(nonzeros(dp_lower) * mm_per_pixel, 100, 'Normalization', 'pdf');
        title('Histogram Lower Layer With Neighbouring Steelwires');
        hold on
        y = nonzeros(dp_lower) * mm_per_pixel;
        y(y < 10) = NaN;
        y = sort(y);
        mu = distanceLower * mm_per_pixel;
        sigma = 4;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5)
        hold off

        %% Plotte die Distributionen der Abstände
        dp_upper(dp_upper < 11) = NaN;
        dp_lower(dp_lower < 11) = NaN;

        subplot(2, 2, 3), histo_A_upper = histogram(nonzeros(dp_upper) * mm_per_pixel, 100, 'Normalization', 'pdf');
        title('without Neighbour Wire Distance');
        hold on
        y = nonzeros(dp_upper) * mm_per_pixel;
        y(y < 10) = NaN;
        y = sort(y);
        mu = distanceUpper * mm_per_pixel;
        sigma = 4;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5)
        hold off
        subplot(2, 2, 4), histo_A_lower = histogram(nonzeros(dp_lower) * mm_per_pixel, 100, 'Normalization', 'pdf');
        title('without Neighbour Wire Distance');
        hold on
        y = nonzeros(dp_lower) * mm_per_pixel;
        y(y < 10) = NaN;
        y = sort(y);
        mu = distanceLower * mm_per_pixel;
        sigma = 4;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5)
        hold off

    end

    %% manuelles Ausw�hlen von Punkten im Bild. Dient der Polynom Regression um ROI zu bestimmen
    function [x, y] = selectPoints(figurehandle)

        while (true)
            title('w�hle die Kreuze aus mit linker Maustaste! Return/Eingabe um zu best�tigen');

            [x_buff, y_buff] = ginput;
            x = [];
            y = [];
            x = cat(1, x, x_buff);
            y = cat(1, y, y_buff);

            title(' pan und dr�cke Space. q f�r quit / beenden');

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

    %% Plottet den Bereich der als ROI in Frage kommt
    function [] = plotEinhuellende(figurehandle, x1, y1)
        delta = 0;

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

    %% function der als callback in figure den ROI (mithilfe delta) anpasst mit arrow up/down
    function [] = functionHandle_KeyPressFcn(H, E)
        % Figure keypressfcn
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

    function [centers, radii] = findCapPly(img, name)
        % Stahl Lage entfernen (helle Werte >60)
        steel_grayvalue = 60;
        img(img > steel_grayvalue) = 30;
        thresh_img = img;

        if (use_denoise_CNN)
            mkdir('denoised')

            % check ob CNN schonmal denoised hat
            if (~isfile(fullfile('denoised', [name '.mat'])))
                net = denoisingNetwork('DnCNN');
                denoised_img = denoiseImage(thresh_img, net);
                save(fullfile('denoised', name), 'denoised_img')
            else
                load(fullfile('denoised', [name '.mat']), 'denoised_img')

            end

        else
            denoised_img = thresh_img;
        end

        figure, imshowpair(thresh_img, denoised_img, 'montage');
        title('Original Image (left) and Denoised (right)');

        contrast_img = adapthisteq(denoised_img, 'clipLimit', 0.5, 'Distribution', 'rayleigh');
        figure, imshowpair(denoised_img, contrast_img, 'montage');
        title('Original Image (left) and Contrast Enhanced Image (right)');

        [BW_Mask_afterThreshold, masked_contrast_img] = segmentImageAdaptiveThreshold(contrast_img);
        figure, imshowpair(BW_Mask_afterThreshold, masked_contrast_img, 'montage');
        title('BW_Mask_afterThreshold (left) and masked_contrast_img (right)');

        close all

        %% ROI Spline auswaehlen
        figureHandle = figure('keypressfcn', @functionHandle_KeyPressFcn);
        imshow(img);
        figureHandle.WindowState = 'fullscreen';
        axis manual;
        axis([0 length(img(1, :)) 0 length(img(1, :)) / 1.6]);

        ph = pan(figureHandle);

        mkdir('selectedPoints');

        if (isfile(fullfile('selectedPoints', [name '.mat'])) && use_old_spline)
            load(fullfile('selectedPoints', [name '.mat']), 'X', 'Y')
        else
            title(' Zoome und drcke Enter');
            zoom on;
            waitfor(gcf, 'CurrentCharacter', char(13))
            zoom reset
            zoom off
            [X, Y] = selectPoints(figureHandle);
            save(fullfile('selectedPoints', name), 'X', 'Y')
        end

        xgrid = 1:1:length(img(1, :));
        yspline = spline(X, Y, xgrid);
        hold on;
        plot(X, Y, 'o', xgrid, yspline);

        plotEinhuellende(figureHandle, xgrid, yspline);
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

        sensitivityLvL = 0.95;
        maxNoOfCircles = 60;
        minimumRadius = 6; %% bei 96 dpi
        maximumRadius = 10; %% bei 96 dpi

        [BW_Circles, maskedImg_Circles, centers, radii] = segmentImageCircles(bw_img_masked_withSplineROI_Opened, ...
            sensitivityLvL, maximumRadius, minimumRadius, maxNoOfCircles);
        close all;
        figure, imshow(img);

        %% Kreise Segmentieren (Stahl)

        hold on
        plot(centers(:, 1), centers(:, 2), '.', 'LineWidth', 2, 'XDataSource', 'centers(:,1)', 'YDataSource', 'centers(:,2)', 'ZDataSource', 'radii');
        %% hier kann im Plot falsche Daten mit Tool -->brusch +link entfernt werden
        title('Loesche ungewollte Mittelpunkte mit Link und Brush Tool bei Bedarf ACHTUNG: Rechtsklick und Remove! ');
        warndlg('L�schen von Outliern nur mit Rechtsclick --> Remove (im Debug Mode)');

        linkdata on;
        brush on;

        %% da brushing nur im debug modus funktioniert.

        % nachdem continue gedrückt wurde sollte die Variable bearbeitet worden sein.?

        % !!! uiwait
        % Debug Cont.
        doneHandle = uicontrol('String', 'Done', 'Callback', {@evaluateCapPlyData}');

        keyboard;

        function [] = evaluateCapPlyData(src, evt)
            viscircles(centers, radii, 'EdgeColor', 'g', 'LineWidth', 1);
            cap.Radius=radii;
            cap.PositionInImage=centers;
           
            
            cap.quiverPlot();
            save('test','cap');
     
            
         
            
%             quiver(sorted_centers(1:end - 1, 1), sorted_centers(1:end - 1, 2), centers_dst(:, 1), centers_dst(:, 2), 0);
%             
%             distance_threshold = 30%[px]
%             centers_dst_filtered = centers_dst;
%             centers_dst_filtered(abs(centers_dst_filtered) > distance_threshold) = NaN;
% 
%             
%             distance_cap_median = median(centers_dst_filtered, 'omitnan')
%             distance_cap_median_mm = distance_cap_median * mm_per_pixel
% 
%             distance_cap_mean = mean(centers_dst_filtered, 'omitnan')
%             distance_cap_mean_mm = distance_cap_mean * mm_per_pixel
% 
%             euklid_norm_median = norm(distance_cap_median)
%             euklid_norm_median_mm = euklid_norm_median * mm_per_pixel
%             euklid_norm_mean = norm(distance_cap_mean)
%             euklid_norm_mean_mm = euklid_norm_mean * mm_per_pixel
% 
%             Area = pi * radii.^2;
%             Area_mm = Area * Area * mm_per_pixel * mm_per_pixel;
%             Area_mean = mean(Area, 'omitnan')
%             Area_mean_mm = Area_mean * Area_mean * mm_per_pixel * mm_per_pixel
%             Area_median = median(Area, 'omitnan')
%             Area_median_mm = Area_median * Area_median * mm_per_pixel * mm_per_pixel
%             quiver(sorted_centers(1:end - 1, 1), sorted_centers(1:end - 1, 2), centers_dst_filtered(:, 1), centers_dst_filtered(:, 2), 0, 'Color', 'b');
%             title(['Blue are filtered distances with threshold: ' sprintf('%d', distance_threshold)]);
% 
%             if (doPlotDistribution == true)
%                 plotDistributionCapPly(centers_dst_filtered, distance_cap_mean, Area, Area_mean, Area_median)
%             end

            keyboard;
        end

    end

    function [] = plotDistributionCapPly(centers_dst_filtered, distance_cap_mean, Area, Area_mean, Area_median)
        figure;
        subplot(2, 2, 1), histo_dist_X = histogram(nonzeros(centers_dst_filtered(:, 1)) * mm_per_pixel, 50, 'Normalization', 'pdf');
        hold on
        y = nonzeros(centers_dst_filtered(:, 1) * mm_per_pixel);
        y = sort(y);
        mu = distance_cap_mean(1);
        sigma = 4;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5)
        title('Histogram der gefilterten Abstaende in X Richtung');
        hold off

        subplot(2, 2, 2), histo_dist_X = histogram(nonzeros(centers_dst_filtered(:, 2)) * mm_per_pixel, 50, 'Normalization', 'pdf');
        hold on
        y = nonzeros(centers_dst_filtered(:, 2) * mm_per_pixel);
        y = sort(y);
        mu = distance_cap_mean(2);
        sigma = 8;
        f = exp(-(y - mu).^2 ./ (2 * sigma^2)) ./ (sigma * sqrt(2 * pi));
        plot(y, f, 'LineWidth', 1.5);
        title('Histogram der gefilterten Abstaende in Y Richtung');
        hold off

        subplot(2, 2, 4), histo_Area = histogram(nonzeros(Area), 50, 'Normalization', 'pdf');
        title(sprintf('Mean: %f Median: %f', Area_mean, Area_median));

    end

end
