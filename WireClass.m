%% Class of round wires with respect to dpi value

classdef WireClass

    properties (Constant = true)
        DPI = 600%default value is 600dpi
    end

    properties
        % strings
        Material
        %scalars
        % metrics: numerical Vectors
        PositionInImage% X,Y Coordinate
        DistanceToNextWire
        Radius
    end

    properties (Dependent = true)
        CrosssectionArea%depends on CS Length
    end

    methods

        function wp = WirePlyClass(material, position, distanceToNext, radius, dpi)

            if nargin > 0

                Material = material;
                PositionInImage = position;
                DistanceToNextWire = distanceToNext;
                Radius = radius;
                DPI = dpi;
            end

        end

        function crossSectionArea = get.CrosssectionArea(obj)
            crosssectionArea = pi * radius.^2;
        end

        function = set.CrosssectionArea(obj)
            error('cannot set CrosssectionArea because its dependent on radius');
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

            if (checkDimension(positionInImage))
                obj.PositionInImage = positionInImage;
            end

        end

        function obj = set.DistanceToNextWire(obj, distanceToNext)

            if (checkDimension(distanceToNext))
                obj.DistanceToNextWire = distanceToNext;
            end

        end

        function string = toString(obj)
            string = '';

        end

        function  = disp(obj)
            % Overload disp() for formatting
            disp(obj)
        end

        function [position, radius, diameter, crosssectionArea, distanceToNextWire] = metricsInMilimeter(obj)
            mmPerPx = 25.4 / obj.DPI;
            position = obj.Position .* mmPerPx;
            radius = obj.Radius .* mmPerPx;
            diameter = radius .* 2;
            crosssectionArea = obj.CrosssectionArea .* mmPerPx;
            distanceToNextWire = obj.DistanceToNextWire .* mmPerPx;

        end

        function [isValid] = checkDimension(input)

            isValid = (isnumeric(input) || size(input, 2) == 2)

        end

    end

end
