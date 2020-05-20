    close all;
    clear vars;
    %% Runtime Variablen%%%%%
    spline_already_selected=true;
    addpath('Classes');

    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    [path, cancelled] = imgetfile();
    [filepath, name, ext] = fileparts(path);

    if (cancelled)
        error('kein Image gewaehlt');
    end
    %% Get DPI Value
    dpi_string = regexp(name, '(?<=_)\d*(?=dpi)', 'match', 'once'); %lookaround regex
    %     regexp('bla_600dpi', '(?<=_)\d*(?=dpi)', 'match', 'once') % ans='600'
    if isempty(dpi_string)
        error('Name keine korrekte DPI angabe');
    end

    dpi = str2num(dpi_string);
    img = imread(path);
    file=name;
    
    %% Construct Wire Objects
    capPly=Wire(img,dpi,file,'capPly',Material.Polymer);
    steelPly=Wire(img,dpi,file,'steelPly',Material.Steel);
    if(spline_already_selected)
        capPly.UseOldSpline=true;
    end
    
    %% Run Algorithm
    capPly=capPly.findCapPly();
    
    % returns [Wire,DoubleWire,DoubleWire]
    [steelPly,upperSteelPly,lowerSteelPly]=steelPly.findWiresAndSplitSteelLayers();
    upperSteelPly.Name='upperSteelPly';
    lowerSteelPly.Name='lowerSteelPly';
    %% Display Results
    capPly.plot();
    upperSteelPly.plotDoubleWire();
    lowerSteelPly.plotDoubleWire();
    %% Save Results
    resultspath='Results';
    datetimeString=char(datetime);
    pathName=replace(datetimeString,":","-"); % Windows does not support : in filenames
    mkdir (resultspath, pathName);
    resultFolderPath=fullfile(resultspath,pathName);
    cd(resultFolderPath);
    save(['results_', name],'capPly','upperSteelPly','lowerSteelPly');
 %% write and display summarized results
    fileID = fopen(['results_', name,'.txt'],'w');

    fprintf(fileID,['Ergebnisse unter: ',fullfile(resultFolderPath,['results_', name])]);
    fprintf(fileID,'Alle Ergebnisse in mm \n');
    
    fprintf(fileID,['%s : \n DiameterMedian:%f \n',...
        ' AreaMedian:%f \n DistanceMedian:%f \n'],...
        upperSteelPly.Name,upperSteelPly.DiameterMedian,...
        upperSteelPly.CrossSectionA.MedianMM,...
        upperSteelPly.DistanceToNextDoubleHelix.MedianNorm);
    
   fprintf(fileID,['%s : \n DiameterMedian:%f \n',...
        ' AreaMedian:%f \n DistanceMedian:%f \n'],...
        lowerSteelPly.Name,lowerSteelPly.DiameterMedian,...
        lowerSteelPly.CrossSectionA.MedianMM,...
        lowerSteelPly.DistanceToNextDoubleHelix.MedianNorm);
    
    fprintf(fileID,['%s : \n DiameterMedian:%f \n',...
        ' AreaMedian:%f \n DistanceMedian:%f \n'],...
        capPly.Name,capPly.DiameterMedian,...
        capPly.CrossSectionA.MedianMM,...
        capPly.DistanceToNextW.MedianNorm);
    fclose(fileID);
    fileID = fopen(['results_', name,'.txt'],'r');
    while ~feof(fileID)
        tline = fgetl(fileID);
        disp(tline)
    end
        fclose(fileID);
        
%% copy Image to Resultfolder
    copyfile(path,[name,ext]);
%%  cd back to root    
    
    cd(fullfile('..','..'));

    

    