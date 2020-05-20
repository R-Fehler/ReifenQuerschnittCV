classdef WireTest < matlab.unittest.TestCase
    % TESTCLASS FOR WIRE AND DOUBLEWIRE ALGORITHMS
    %   testCase instance is called 'it' and is always first parameter in methods
    % actual values are prefixed with test* expected values have no prefi
    
    properties
        Img
        Dpi
        Filename
        Name
        WireMaterial
        
        testCapPly
        capPlyDelta
        
        capPly %expected
        
        TestSteelPly
        TestUpperSteelPly
        TestLowerSteelPly
        steelPlyDelta
        
        steelPly % expected
        upperSteelPly% expected
        lowerSteelPly% expected
    end
    
    methods (TestClassSetup)
        function addPath(it)
            p = path;
            it.addTeardown(@path,p);
            addpath('Classes');
        end
        function loadData(it)
            impath='ExampleImage/test_600dpi.png';
            
            %% expected values
            load('testData.mat','capPly');
            load('testData_steel.mat','steelPly','upperSteelPly','lowerSteelPly');
            it.capPly=capPly;
            it.steelPly=steelPly;
            it.upperSteelPly=upperSteelPly;
            it.lowerSteelPly=lowerSteelPly;
            [filepath, name, ext] = fileparts(impath);
            
            it.Filename=name;
            it.Img=imread(impath);
            it.Dpi=600;
            it.Name='coinTestTire';
            it.WireMaterial=Material.Steel;
            it.testCapPly=Wire(it.Img,it.Dpi,it.Filename,'capPly',Material.Polymer);
            it.testCapPly.UseOldSpline=true;
            it.capPlyDelta=16;
            %% run the Algorithm, init data
            it.testCapPly=it.testCapPly.findCapPly(it.capPlyDelta);
            
            it.TestSteelPly=Wire(it.Img,it.Dpi,it.Filename,'steelPly',Material.Steel);
            it.steelPlyDelta=72;
            % run the Algorithm, init data
            [it.TestSteelPly,it.TestUpperSteelPly,it.TestLowerSteelPly]=...
                it.TestSteelPly.findWiresAndSplitSteelLayers(it.steelPlyDelta);
            it.TestUpperSteelPly.Name='upperSteelPly';
            it.TestLowerSteelPly.Name='lowerSteelPly';
            
            
        end
    end
    
    methods (Test)
        function testConstructor(it)
            wire=Wire(it.Img,it.Dpi,...
                it.Filename,it.Name,it.WireMaterial);
            it.verifyClass(wire,'Wire')
            it.verifyEqual(wire.ImageOriginal,it.Img);
            it.verifyEqual(wire.DPI,it.Dpi);
            it.verifyEqual(wire.FileName,it.Filename);
            it.verifyEqual(wire.Name,it.Name);
            it.verifyEqual(wire.WireMaterial,it.WireMaterial);
            
        end
        
        
        % verify correct Image Input
        function testImageInput(it)
            isSameOriginalImage=~any(~it.testCapPly.ImageOriginal==it.capPly.ImageOriginal,'all');
            it.verifyTrue(isSameOriginalImage,'Not Same Original Image CapPly');
            
            isSameOriginalImage=~any(~it.TestSteelPly.ImageOriginal==it.steelPly.ImageOriginal,'all');
            it.verifyTrue(isSameOriginalImage,'Not Same Original Image SteelPly');
        end
        % verify same Input for imfindcircles() / Hough Transform. Algorithm
        function testProcessedImage(it)
            isSameCVImage=~any(~it.testCapPly.ImageUsedForCV==it.capPly.ImageUsedForCV,'all');
            it.verifyTrue(isSameCVImage,'Not Same CV Image Output Cap');
            
            isSameCVImage=~any(~it.TestSteelPly.ImageUsedForCV==it.steelPly.ImageUsedForCV,'all');
            it.verifyTrue(isSameCVImage,'Not Same CV Image Output Steel');
        end
        
        % allow controlled deviance of Input for imfindcircles() / Hough Transf. Algorithm
        function testProcessedImageTolerated(it)
            maxDifferenceAllowed=20; %% CVImage is a boolean matrix, only 20 px difference allowed
            differenceOfCVImage=(sum(abs(it.testCapPly.ImageUsedForCV-it.capPly.ImageUsedForCV),'all'));
            it.verifyTrue(differenceOfCVImage < maxDifferenceAllowed,'CV Image Differs too much Cap');
            
            differenceOfCVImage=(sum(abs(it.TestSteelPly.ImageUsedForCV-it.steelPly.ImageUsedForCV),'all'));
            it.verifyTrue(differenceOfCVImage < maxDifferenceAllowed,'CV Image Differs too much Steel');
            
        end
        
        % verify Number of recognized Wires is in tolerance
        function testNumberOfRecognizedWires(it)
                        import matlab.unittest.constraints.*

            toleranceNoOfWiresObj=AbsoluteTolerance(10) & RelativeTolerance(0.1);
            expectedNoOfWires=length(it.capPly.PositionInImage);
            it.verifyThat(length(it.testCapPly.PositionInImage),IsEqualTo(expectedNoOfWires, ...
                'Within',toleranceNoOfWiresObj));
            
            expectedNoOfWires=length(it.steelPly.PositionInImage);
            it.verifyThat(length(it.TestSteelPly.PositionInImage),IsEqualTo(expectedNoOfWires, ...
                'Within',toleranceNoOfWiresObj));
        end
        % distance median to next wire in mm
        function testDistanceToNextWire(it)
                        import matlab.unittest.constraints.*

            toleranceDistanceObj=AbsoluteTolerance(2) & RelativeTolerance(0.05);
            expectedDistance=it.capPly.DistanceToNextW.MedianNorm;
            it.verifyThat(it.testCapPly.DistanceToNextW.MedianNorm,IsEqualTo(expectedDistance, ...
                'Within',toleranceDistanceObj));
            
            toleranceDistanceObj=AbsoluteTolerance(2) & RelativeTolerance(0.05);
            expectedDistance=it.steelPly.DistanceToNextW.MedianNorm;
            it.verifyThat(it.TestSteelPly.DistanceToNextW.MedianNorm,IsEqualTo(expectedDistance, ...
                'Within',toleranceDistanceObj));
        end
        
        % diameter median of wires in px
        function testDiameterOfWire(it)
                        import matlab.unittest.constraints.*

            toleranceDiameterObj=AbsoluteTolerance(0.5) & RelativeTolerance(0.05);
            expectedDiameter=it.capPly.DiameterMedian;
            it.verifyThat(it.testCapPly.DiameterMedian,IsEqualTo(expectedDiameter, ...
                'Within',toleranceDiameterObj));
            
            toleranceDiameterObj=AbsoluteTolerance(0.5) & RelativeTolerance(0.05);
            expectedDiameter=it.steelPly.DiameterMedian;
            it.verifyThat(it.TestSteelPly.DiameterMedian,IsEqualTo(expectedDiameter, ...
                'Within',toleranceDiameterObj));
        end
        %
        
        % test if output equals exactly that of Matlab R2018b under Win10 with ImPro,
        % CV Toolbox with source from last git commit:
        %                 commit 3312fbcd281f5fde29cf6008ee5cfa1a79f5704f (HEAD -> master, origin/master, origin/HEAD)
        %                 Author: Richard Fehler <timblezero@gmail.com>
        %                 Date:   Wed Apr 8 16:29:15 2020 +0200
        function testExactlyEqualCap(it)
            it.verifyEqual(it.capPly,it.testCapPly,...
                'output equals not exactly R2018b');
        end
        
        
        %% Test the splitted output, DoubleWire objects
        
        
        % Test if upper and lower Number of Wires differ dramatically
        % eg. when split polynom was not splitting correctly
        function testSplitFunctionality(it)
                        import matlab.unittest.constraints.*

            toleranceDifferUpperLower=AbsoluteTolerance(10) & RelativeTolerance(0.05);
            upperNoOfWires=length(it.TestUpperSteelPly.PositionInImage);
            lowerNoOfWires=length(it.TestLowerSteelPly.PositionInImage);
            % upper layer misses roughly 20 wires and lower has 5 false positive
            expectedUpperNoOfWires=upperNoOfWires+20+5;
            it.verifyThat(expectedUpperNoOfWires,IsEqualTo(lowerNoOfWires, ...
                'Within',toleranceDifferUpperLower));
            
            % verify that no Wires are lost in splitting
            totalNoOfWires=length(it.TestSteelPly.PositionInImage);
            sumOfUpperLowerWires=upperNoOfWires+lowerNoOfWires;
            it.verifyEqual(totalNoOfWires,sumOfUpperLowerWires);
        end
        
        % test if output equals exactly that of Matlab R2018b under Win10 with ImPro,
        % CV Toolbox with source code from last git commit:
        %                 commit 3312fbcd281f5fde29cf6008ee5cfa1a79f5704f (HEAD -> master, origin/master, origin/HEAD)
        %                 Author: Richard Fehler <timblezero@gmail.com>
        %                 Date:   Wed Apr 8 16:29:15 2020 +0200
        function testExactlyEqualSteel(it)
            it.verifyEqual(it.TestSteelPly,it.steelPly);
            it.verifyEqual(it.TestUpperSteelPly,it.upperSteelPly);
            it.verifyEqual(it.TestLowerSteelPly,it.lowerSteelPly);
        end
        
    end
end

