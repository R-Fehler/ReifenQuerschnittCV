classdef DoubleWire < Wire
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        
    end

    properties (Dependent = true)
                % numerical vectors

        PositionOfDoubleHelix
        DistanceToNextDoubleHelix
    end

    methods
        %% Constructor
        %Copy Constructor

        function obj = DoubleWire(wire)
            obj@Wire();
            obj.DistanceThresholdTuningValue=50;

            if (nargin ~= 0)

                if (class(wire) == class(Wire))
                    obj = wire.copyObject(obj);
                end

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
        

        function out = get.DistanceToNextDoubleHelix(obj)
            out = DistanceToNextWire;
            %         VectorsPx
            %         VectorsMM
            %         MedianVector
            %         MedianNorm
            %         MeanVector
            %         MeanNorm
            srt_cntrs = sortrows(obj.PositionOfDoubleHelix);
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

        function out = get.PositionOfDoubleHelix(obj)
            centers = obj.PositionInImage;
            D_s_upper_avg = mean(obj.Radius * 2, 'omitnan');
            avgCenters = zeros(size(centers, 1), 2);

            for nn = 1:size(centers, 1)

                for mm = 1:size(centers, 1)

                    if (norm(centers(nn) - centers(mm)) < 1.5 * D_s_upper_avg && mm ~= nn)

                        avgCenters(nn, 1) = (centers(nn, 1) + centers(mm, 1)) / 2;
                        avgCenters(nn, 2) = (centers(nn, 2) + centers(mm, 2)) / 2;

                    end

                end

                if avgCenters(nn, 1) == 0%% wenn nur ein kreis erkannt wird setzte diesen als  Mittelpunkt
                    avgCenters(nn, 1) = centers(nn, 1);
                    avgCenters(nn, 2) = centers(nn, 2);
                end

            end

            out = avgCenters;
        end
        
        function figurehandle=plotDoubleWire(obj)
             figurehandle=figure;
            imshow(obj.ImageOriginal);
            title(sprintf('Plot of %s: recognized wires(%f) and distances(%f)', obj.Name,obj.RadiusMedian, obj.DistanceToNextDoubleHelix.MedianNorm));


            hold on;
            plot(obj.PositionOfDoubleHelix(:, 1), obj.PositionOfDoubleHelix(:, 2), 'o', 'LineWidth', 2, 'XDataSource', 'obj.PositionOfDoubleHelix(:, 1)', 'YDataSource', 'obj.PositionOfDoubleHelix(:, 2)');
            viscircles(obj.PositionInImage,obj.Radius);
            obj.quiverPlotDoubleWire();
            hold off;
        end

    end
    
    methods(Access=private)
         function fh = quiverPlotDoubleWire(obj)
            srt_cntrs = sortrows(obj.PositionOfDoubleHelix);
            cntrs_dst = obj.DistanceToNextDoubleHelix.VectorsPx;
            hold on
            title(sprintf('Plot of %s: recognized DoubleWires and distances', obj.Name));
            fh = quiver(srt_cntrs(1:end - 1, 1), srt_cntrs(1:end - 1, 2), cntrs_dst(:, 1), cntrs_dst(:, 2), 0);
            hold off
        end
    end

end
