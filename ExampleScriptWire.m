    %% Einlesen der Bilder
    close all;
    clear vars;
    %% Runtime Variablen%%%%%
    spline_already_selected=true;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%
    
    [path, cancelled] = uigetimagefile();
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
    [steelPly,upperSteelPly,lowerSteelPly]=steelPly.splitSteelLayers();
    upperSteelPly.Name='upperSteelPly';
    lowerSteelPly.Name='lowerSteelPly';
    %% Save and Display Results
    capPly.plot();
    savefig('capPly');
    upperSteelPly.plotDoubleWire();
    lowerSteelPly.plotDoubleWire();
    save('resultsOfExampleScript','capPly','upperSteelPly','lowerSteelPly');
    

    

    