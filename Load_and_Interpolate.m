clear; clc; close all;

%% LOAD TIMES

filein = '../DATA/Digitisation_tools_test_data.xlsx';

TIME = readcell(filein, 'Sheet', 'TIMES');

ManualT             = TIME(2,2:10);
NUNIEAUT            = TIME(3,2:10);
WebplotdigitiserT   = TIME(4,2:10);
DigitGraphT         = TIME(5,2:10);
GRABITT             = TIME(6,2:10);
DagraT              = TIME(7,2:10);
DigitiseItT         = TIME(8,2:10);
EngaugedigitiserT   = TIME(9,2:10);
OriginLabT          = TIME(10,2:10);
PlotdigitiserT      = TIME(11,2:10);
GraphGrabberT       = TIME(12,2:10);
GetDataT            = TIME(13,2:10);
Gemini_3ProT        = TIME(14,2:10);
ChatGPT5T           = TIME(15,2:10);

save('TIME.mat', ...
    'ManualT', ...
    'NUNIEAUT', ...
    'WebplotdigitiserT', ...
    'DigitGraphT', ...
    'GRABITT', ...
    'DagraT', ...
    'DigitiseItT', ...
    'EngaugedigitiserT', ...
    'OriginLabT', ...
    'PlotdigitiserT', ...
    'GraphGrabberT', ...
    'GetDataT', ...
    'Gemini_3ProT', ...
    "ChatGPT5T");

clearvars -except filein


%% LOAD RAW DATA

sheetNames = { ...
    'Manual'
    'NUNIEAU'
    'WebPlotDigitizer'
    'DigitGraph'
    'GRABIT'
    'Dagra'
    'DigitizeIt'
    'Engauge Digitizer'
    'OriginLab'
    'Plot Digitizer'
    'GraphGrabber'
    'GetData'
    'Gemini 3.1Pro'
    'ChatGPT5.5'
    };

saveNames = { ...
    '01_Manual.mat'
    '02_NUNIEAU.mat'
    '03_WebPlotDigitizer.mat'
    '04_DigitGraph.mat'
    '05_GRABIT.mat'
    '06_Dagra.mat'
    '07_DigitizeIt.mat'
    '08_Engauge Digitizer.mat'
    '09_OriginLab.mat'
    '10_Plot Digitizer.mat'
    '11_GraphGrabber.mat'
    '12_GetData.mat'
    '13_Gemini_3Pro.mat'
    '14_ChatGPT5.mat'
    };

for m = 1:length(sheetNames)

    Sheet = readcell(filein, 'Sheet', sheetNames{m});
    MethodData = table();

    for i = 1:9

        baseCol = (i-1)*4;
        dateCol  = baseCol + 2;
        timeCol  = baseCol + 3;
        levelCol = baseCol + 4;
        Date = [Sheet{2:end,dateCol}]';
        Level = str2double(string(Sheet(2:end,levelCol)));

        % Different time formats (11:15 rather than 11.25)
        if strcmp(sheetNames{m},'Manual') || strcmp(sheetNames{m},'NUNIEAU')|| strcmp(sheetNames{m},'Gemini 3.1Pro') || strcmp(sheetNames{m},'ChatGPT5.5')

            Time = str2double(string(Sheet(2:end,timeCol)));
            Datetime = Date + days(Time);

        else

            TimeDecimal = str2double(string(Sheet(2:end,timeCol)));
            H = floor(TimeDecimal);
            M = round((TimeDecimal - H) * 60);
            Time = hours(H) + minutes(M);
            Datetime = Date + Time;

        end

        Datetime.Format = 'dd-MMM-yyyy HH:mm:ss';
        MethodData.(['Attempt' num2str(i) '_Datetime']) = Datetime;
        MethodData.(['Attempt' num2str(i) '_WaterLevel']) = Level;

    end
    save(saveNames{m}, 'MethodData')

end

clearvars -except filein TIME
clc
close all

%% Interpolate

load('02_NUNIEAU.mat')
NUNIEAU_Interp = table();
for i = 1:9

    dt = MethodData.(['Attempt' num2str(i) '_Datetime']);
    wl = MethodData.(['Attempt' num2str(i) '_WaterLevel']);
    wl = str2double(string(wl));
    wl = wl + 12.19; %add offset (NUNIEAU takes into account the datum but no other tools do)
    good = ~isnat(dt) & isfinite(wl);
    dt = dt(good);
    wl = wl(good);
    startDT = datetime(1910,11,28,11,15,0);
    endDT   = datetime(1910,12,5,10,45,0);
    dt15 = (startDT:minutes(15):endDT)';
    dt15.Format = 'dd-MMM-yyyy HH:mm:ss';
    x = datenum(dt);
    xq = datenum(dt15);
    [x, idx] = sort(x);
    wl = wl(idx);
    [xU, ~, g] = unique(x);
    wlU = accumarray(g, wl, [], @mean);
    wl15 = interp1(xU, wlU, xq, 'linear');

    NUNIEAU_Interp.(['Attempt' num2str(i) '_Datetime']) = dt15;
    NUNIEAU_Interp.(['Attempt' num2str(i) '_WaterLevel']) = wl15;

end

MethodData = NUNIEAU_Interp;
save('02_NUNIEAU.mat', 'MethodData')


load('03_WebPlotDigitizer.mat')
Webplotdigitiser_Interp = table();
for i = 1:9
    dt = MethodData.(['Attempt' num2str(i) '_Datetime']);
    wl = MethodData.(['Attempt' num2str(i) '_WaterLevel']);
    wl = str2double(string(wl));
    good = ~isnat(dt) & isfinite(wl);
    dt = dt(good);
    wl = wl(good);
    startDT = datetime(1910,11,28,11,15,0);
    endDT   = datetime(1910,12,5,10,45,0);
    dt15 = (startDT:minutes(15):endDT)';
    dt15.Format = 'dd-MMM-yyyy HH:mm:ss';
    x = datenum(dt);
    xq = datenum(dt15);
    [x, idx] = sort(x);
    wl = wl(idx);
    [xU, ~, g] = unique(x);
    wlU = accumarray(g, wl, [], @mean);
    wl15 = interp1(xU, wlU, xq, 'linear');
    Webplotdigitiser_Interp.(['Attempt' num2str(i) '_Datetime']) = dt15;
    Webplotdigitiser_Interp.(['Attempt' num2str(i) '_WaterLevel']) = wl15;
end

MethodData = Webplotdigitiser_Interp;
save('03_WebPlotDigitizer.mat', 'MethodData')


load('04_DigitGraph.mat')
DigitGraph_Interp = table();
for i = 1:9
    dt = MethodData.(['Attempt' num2str(i) '_Datetime']);
    wl = MethodData.(['Attempt' num2str(i) '_WaterLevel']);
    wl = str2double(string(wl));
    good = ~isnat(dt) & isfinite(wl);
    dt = dt(good);
    wl = wl(good);
    startDT = datetime(1910,11,28,11,15,0);
    endDT   = datetime(1910,12,5,10,45,0);
    dt15 = (startDT:minutes(15):endDT)';
    dt15.Format = 'dd-MMM-yyyy HH:mm:ss';
    x = datenum(dt);
    xq = datenum(dt15);
    [x, idx] = sort(x);
    wl = wl(idx);
    [xU, ~, g] = unique(x);
    wlU = accumarray(g, wl, [], @mean);
    wl15 = interp1(xU, wlU, xq, 'linear');
    DigitGraph_Interp.(['Attempt' num2str(i) '_Datetime']) = dt15;
    DigitGraph_Interp.(['Attempt' num2str(i) '_WaterLevel']) = wl15;
end

MethodData = DigitGraph_Interp;
save('04_DigitGraph.mat', 'MethodData')


load('10_Plot Digitizer.mat')
Plotdigitiser_Interp = table();
for i = 1:9
    dt = MethodData.(['Attempt' num2str(i) '_Datetime']);
    wl = MethodData.(['Attempt' num2str(i) '_WaterLevel']);
    wl = str2double(string(wl));
    good = ~isnat(dt) & isfinite(wl);
    dt = dt(good);
    wl = wl(good);
    startDT = datetime(1910,11,28,11,15,0);
    endDT   = datetime(1910,12,5,10,45,0);
    dt15 = (startDT:minutes(15):endDT)';
    dt15.Format = 'dd-MMM-yyyy HH:mm:ss';
    x = datenum(dt);
    xq = datenum(dt15);
    [x, idx] = sort(x);
    wl = wl(idx);
    [xU, ~, g] = unique(x);
    wlU = accumarray(g, wl, [], @mean);
    wl15 = interp1(xU, wlU, xq, 'linear');
    Plotdigitiser_Interp.(['Attempt' num2str(i) '_Datetime']) = dt15;
    Plotdigitiser_Interp.(['Attempt' num2str(i) '_WaterLevel']) = wl15;
end

MethodData = Plotdigitiser_Interp;
save('10_Plot Digitizer.mat', 'MethodData')
