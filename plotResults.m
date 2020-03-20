clear vars;
close all;
[filename,path]=uigetfile('*.mat');

addpath('Classes');
load(fullfile(path,filename));
capPly.plot();
upperSteelPly.plotDoubleWire();
lowerSteelPly.plotDoubleWire();