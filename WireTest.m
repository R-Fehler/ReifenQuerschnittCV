classdef WireTest < matlab.unittest.TestCase
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Img
        Dpi
        Filename
        Name
        WireMaterial
        
    end
    
    methods (TestClassSetup)
        function addPath(testCase)
               p = path;
            testCase.addTeardown(@path,p);
            addpath('Classes');
        end
        function loadData(testCase)
            impath='ExampleImage/test_600dpi.png';
            [filepath, name, ext] = fileparts(impath);

            testCase.Filename=name;
            testCase.Img=imread(impath);
            testCase.Dpi=600;
            testCase.Name='coinTestTire';
            testCase.WireMaterial=Material.Steel;
           
            
        end
    end
    
    methods (Test)
        function testConstructor(testCase)
           wire=Wire(testCase.Img,testCase.Dpi,...
               testCase.Filename,testCase.Name,testCase.WireMaterial);
           testCase.verifyClass(wire,'Wire')
           testCase.verifyEqual(wire.ImageOriginal,testCase.Img);
           testCase.verifyEqual(wire.DPI,testCase.Dpi);
           testCase.verifyEqual(wire.FileName,testCase.Filename);
           testCase.verifyEqual(wire.Name,testCase.Name);
           testCase.verifyEqual(wire.WireMaterial,testCase.WireMaterial);
          
        end
        
        %% wie soll das getested werden. die Funktion muss
        % ohne UI input funktionieren
        % also am besten UI Input in function call: delta, 
        
        % was ist sinnvoll zu testen? output in erwarterter Range,
        % Exception die sowieso getrowt werden.
        
        function testWirePolymer_findCapPly(testCase)
                load('testData.mat','capPly');
                testCapPly=Wire(testCase.Img,testCase.Dpi,testCase.Filename,'capPly',Material.Polymer);
                testCapPly.UseOldSpline=true;
                delta=16;
                testCapPly=testCapPly.findCapPly(delta);
                minNoOfWires=40;
                testCase.verifyGreaterThan(length(testCapPly.PositionInImage),minNoOfWires);
                testCase.verifyGreaterThan(length(testCapPly.PositionInImage),minNoOfWires);
                testCase.verifyGreaterThan(testCapPly.DistanceToNextW.MedianNorm,0)
                testCase.verifyLessThan(testCapPly.DistanceToNextW.MedianNorm,2)% 2 mm max
                testCase.verifyEqual(capPly,testCapPly,...
                    'Wire.findCapPly() was probably changed, capPly and testcapPly not equal');
                clear capPly
        end
        
        function testDoubleWire_splitSteelLayers(testCase)
                 load('testData_steel.mat','steelPly','upperSteelPly','lowerSteelPly');
                TestSteelPly=Wire(testCase.Img,testCase.Dpi,testCase.Filename,'steelPly',Material.Steel);
                delta=72;
                [TestSteelPly,TestUpperSteelPly,TestLowerSteelPly]=TestSteelPly.splitSteelLayers(delta);
                TestUpperSteelPly.Name='upperSteelPly';
                TestLowerSteelPly.Name='lowerSteelPly';
%                 save('testData_steel','steelPly','upperSteelPly','lowerSteelPly');
                
                testCase.verifyEqual(TestSteelPly,steelPly);
                testCase.verifyEqual(TestUpperSteelPly,upperSteelPly);
                testCase.verifyEqual(TestLowerSteelPly,lowerSteelPly);
        end
        
    end
end

