clear
clc
close all

%% SETTINGS

runID = 1;

methodFiles = {
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
    '12_GetData Graph Digitizer.mat'
    '13_Gemini_3Pro.mat'
    '14_ChatGPT5.mat'
    };

methodNames = {
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
    'GetData Graph Digitizer'
    'Gemini 3.1Pro'
    'ChatGPT 5.5'
    };

%% LOAD MANUAL REFERENCE

S = load(methodFiles{1});
ManualData = S.MethodData;

%% LOAD TOOL

S = load(methodFiles{runID});
ToolData = S.MethodData;
refTime = timeofday(ManualData.Attempt1_Datetime);
refWL   = ManualData.Attempt1_WaterLevel;
idx = ~isnan(refWL);
refTime = refTime(idx);
refWL   = refWL(idx);
[refTime, refWL] = breakMidnight(refTime, refWL);

%% PLOT ALL ATTEMPTS — 3 VERTICAL TILES PER FIGURE

for i = 1:9

    if mod(i-1,3) == 0
        figure('WindowState','maximized')
        tiledlayout(3,1,'TileSpacing','compact','Padding','compact')
    end
toolDT = ToolData.(sprintf('Attempt%d_Datetime',i));
toolWL = ToolData.(sprintf('Attempt%d_WaterLevel',i));
idx = ~isnan(toolWL);
toolDT = toolDT(idx);
toolWL = toolWL(idx);
[toolDT, sortIdx] = sort(toolDT);
toolWL = toolWL(sortIdx);
toolTime = timeofday(toolDT);
[toolTime, toolWL] = breakAtDateChange(toolDT, toolTime, toolWL);
    nexttile
    hold on
    plot(refTime, refWL, 'k', 'LineWidth',2)
    plot(toolTime, toolWL, 'r', 'LineWidth',1.5)
    title(sprintf('%s - Attempt %d', methodNames{runID}, i), ...
        'FontSize',18, ...
        'FontWeight','bold')
    ylabel('Water Level (ft)', ...
        'FontSize',13, ...
        'FontWeight','bold')
    xlim([hours(0) hours(24)])
    xticks(hours(0):hours(2):hours(24))
    xtickformat('hh:mm')
    ylim([4 26])
    grid on
    box on
    set(gca,'FontSize',12,'FontWeight','bold')
    if mod(i-1,3) == 0
        lgd = legend({'Manual Reference',methodNames{runID}}, ...
    'Location','northeast');
drawnow
ax = gca;
ax.Units  = 'normalized';
lgd.Units = 'normalized';
axPos  = ax.Position;
lgdPos = lgd.Position;
lgdPos(1) = axPos(1) + axPos(3) - lgdPos(3);
lgdPos(2) = axPos(2) + axPos(4) - lgdPos(4);
lgd.Position = lgdPos;
    end
    if mod(i,3) == 0
        xlabel('Time','FontSize',13,'FontWeight','bold')
    end
    hold off
end


%% FUNCTIONS
function [t,wl] = breakMidnight(t,wl)
    t  = t(:);
    wl = wl(:);
    idx = find(diff(t) < seconds(0));
    for k = numel(idx):-1:1
        t  = [t(1:idx(k)); seconds(NaN); t(idx(k)+1:end)];
        wl = [wl(1:idx(k)); NaN;          wl(idx(k)+1:end)];
    end
end

function [t,wl] = breakBadJumps(t,wl)
    t  = t(:);
    wl = wl(:);
    dt = diff(t);
    badJump = dt < seconds(0) | dt > minutes(30);
    idx = find(badJump);
    for k = numel(idx):-1:1
        t  = [t(1:idx(k)); seconds(NaN); t(idx(k)+1:end)];
        wl = [wl(1:idx(k)); NaN;          wl(idx(k)+1:end)];
    end
end

function [t,wl] = breakMidnightContinuous(t,wl)

    t  = t(:);
    wl = wl(:);
    dayNumber = floor(days(t));
    breaks = find(diff(dayNumber) > 0);
    for k = numel(breaks):-1:1
        t  = [t(1:breaks(k)); seconds(NaN); t(breaks(k)+1:end)];
        wl = [wl(1:breaks(k)); NaN;          wl(breaks(k)+1:end)];
    end
end

function [t,wl] = breakAtDateChange(dt,t,wl)
    dt = dt(:);
    t  = t(:);
    wl = wl(:);
    dateOnly = dateshift(dt,'start','day');
    breaks = find(diff(dateOnly) > days(0));
    for k = numel(breaks):-1:1
        t  = [t(1:breaks(k)); seconds(NaN); t(breaks(k)+1:end)];
        wl = [wl(1:breaks(k)); NaN;          wl(breaks(k)+1:end)];
    end
end