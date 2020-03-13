%% Class of round wires with respect to dpi value

classdef WireClass

    properties
        % strings
        Material
        Name
        %scalars
        DPI = 600%default value is 600dpi
        DistanceThreshold = 30%[px] threshold to ignore neighbouring wires
        % numerical Vectors in [px]
        PositionInImage% X,Y Coordinate
        Radius
        % matrices
        Image

    end

    properties (Dependent = true)
        MMPerPx
        CrossSectionA
        DistanceToNextW

    end

    methods

        function obj = WirePlyClass(image, material, name, dpi)

            if nargin == 4
                obj.Image = image;
                obj.Material = material;
                obj.DPI = dpi;
                obj.Name = name;

            else
                error('image,material, name, dpi not in constructor call');
            end

        end

        function out = get.MMPerPx(obj)
            out = 25.4 / obj.DPI;
        end

        function crossSectionArea = get.CrossSectionA(obj)
            crossSectionArea = CrosssectionArea;
            crossSectionArea.Px = pi * obj.Radius.^2; % number of pixels in cicle
            crossSectionArea.MM = crossSectionArea.Px * obj.MMPerPx.^2; % px*mm/px*mm/px with px^2=px
            crossSectionArea.MeanMM = mean(crossSectionArea.MM, 'omitnan');
            crossSectionArea.MedianMM = median(crossSectionArea.MM, 'omitnan');
        end

        function obj = set.Material(obj, material)

            if (strcmpi(material, 'steel') || ...
                    strcmpi(material, 'polymer'))

                obj.Material = material;
            else
                error('Invalid Material')
            end

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

        % plots quivers on top of original image
        function fh = quiverPlot(obj)
            sorted_centers = sortrows(obj.PositionInImage);
            centers_dst_filtered = obj.DistanceToNextW.VectorsPx;
            %             figure;
            %             hold on
            title(sprintf('QuiverPlot of %s: recognized wires and distances', obj.Name));
            fh = quiver(sorted_centers(1:end - 1, 1), sorted_centers(1:end - 1, 2), centers_dst_filtered(:, 1), centers_dst_filtered(:, 2), 0, 'Color', 'b');
            hold off
        end

    end

end
