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
        
        function testCapPly(testCase)
                capPly=Wire(testCase.Img,testCase.Dpi,testCase.Filename,'capPly',Material.Polymer);
                capPly.UseOldSpline=true;
                delta=16;
                capPly=capPly.findCapPly(delta);
                minNoOfWires=40;
                testCase.verifyGreaterThan(length(capPly.PositionInImage),minNoOfWires);
                testCase.verifyGreaterThan(length(capPly.PositionInImage),minNoOfWires);
                testCase.verifyGreaterThan(capPly.DistanceToNextW.MedianNorm,0)
                testCase.verifyLessThan(capPly.DistanceToNextW.MedianNorm,2)% 2 mm max
                
                    

        end
        
        
        
        
    end
end

