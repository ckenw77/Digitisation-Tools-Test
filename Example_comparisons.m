clear
clc
close all

%% DATA

S = load("01_Manual.mat");
ManualData = S.MethodData;
RefDT = ManualData.Attempt1_Datetime;
RefWL = ManualData.Attempt1_WaterLevel;
RefT  = timeofday(RefDT);

manualRawDT = ManualData.Attempt4_Datetime;
manualWL    = ManualData.Attempt4_WaterLevel;
manualDT    = timeofday(manualRawDT);

S = load("08_Engauge Digitizer.mat");
EngaugeData = S.MethodData;
engaugeRawDT = EngaugeData.Attempt4_Datetime;
engaugeWL    = EngaugeData.Attempt4_WaterLevel;
engaugeDT    = timeofday(engaugeRawDT);

S = load("03_WebPlotDigitizer.mat");
WebPlotData = S.MethodData;
webPlotRawDT = WebPlotData.Attempt4_Datetime;
webPlotWL    = WebPlotData.Attempt4_WaterLevel;
webPlotDT    = timeofday(webPlotRawDT);

S = load("13_Gemini_3Pro.mat");
GeminiData = S.MethodData;
geminiRawDT = GeminiData.Attempt4_Datetime;
geminiWL    = GeminiData.Attempt4_WaterLevel;
geminiDT    = timeofday(geminiRawDT);

S = load("14_ChatGPT5.mat");
ChatGPTData = S.MethodData;
chatGPTRawDT = ChatGPTData.Attempt4_Datetime;
chatGPTWL    = ChatGPTData.Attempt4_WaterLevel;
chatGPTDT    = timeofday(chatGPTRawDT);

%% PLOTTING COPIES

[RefTPlot, RefWLPlot] = breakAtDateChange( ...
    RefDT, RefT, RefWL);

[manualDTPlot, manualWLPlot] = breakAtDateChange( ...
    manualRawDT, manualDT, manualWL);

[engaugeDTPlot, engaugeWLPlot] = breakAtDateChange( ...
    engaugeRawDT, engaugeDT, engaugeWL);

[webPlotDTPlot, webPlotWLPlot] = breakAtDateChange( ...
    webPlotRawDT, webPlotDT, webPlotWL);

[geminiDTPlot, geminiWLPlot] = breakAtDateChange( ...
    geminiRawDT, geminiDT, geminiWL);

[chatGPTDTPlot, chatGPTWLPlot] = breakAtDateChange( ...
    chatGPTRawDT, chatGPTDT, chatGPTWL);

%% COLOURS

colManual = [0.00 0.60 0.50];
colTrace  = [0.00 0.45 0.70];
colPoint  = [0.90 0.60 0.00];
colLLM    = [0.80 0.00 0.50];

%% Differences

PC_diff = RefWL-engaugeWL;
Trace_diff = RefWL-webPlotWL;
Chat_diff = RefWL - chatGPTWL;
Gemini_diff = RefWL - geminiWL;

%% PLOTTING SETTINGS

tickFontSize   = 14;
labelFontSize  = 16;
titleFontSize  = 16;
legendFontSize = 13;

sharedDateLimits = [ ...
    datetime(1910,11,28,11,15,0), ...
    datetime(1910,12,5,10,45,0)];

waterLevelLimits = [-1 20];
differenceLimits = [-9 9];


%% FIGURE 1: ENGAUGE DIGITIZER

waterLevelLimits = [4 20];
differenceLimits = [-0.6 0.6];

figure
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% (a) Water levels
ax1 = nexttile;
hold on
plot(RefDT,RefWL,'k-','LineWidth',4);
plot(engaugeRawDT,engaugeWL,'-','Color',colPoint,'LineWidth',2);
xlim(sharedDateLimits)
ylim(waterLevelLimits)
xlabel('Date','FontSize',labelFontSize,'FontWeight','bold','Color','k')
ylabel('Water level (ft)','FontSize',labelFontSize,'FontWeight','bold','Color','k')
title('(a) Engauge Digitizer - Attempt 4','FontSize',titleFontSize,'FontWeight','bold','Color','k')
legend('Reference Data','Engauge Digitizer','Location','best',...
    'FontSize',legendFontSize,'FontWeight','bold','TextColor','k')
grid on
box on
set(ax1,'FontSize',tickFontSize,'FontWeight','bold','XColor','k','YColor','k')

% (b) Difference
ax2 = nexttile;
plot(RefDT,PC_diff,'r-','LineWidth',2);
hold on
yline(0,'k-','LineWidth',1);
xlim(sharedDateLimits)
ylim(differenceLimits)
xlabel('Date','FontSize',labelFontSize,'FontWeight','bold','Color','k')
ylabel('Difference (ft)','FontSize',labelFontSize,'FontWeight','bold','Color','k')
title('(b) Engauge Digitizer - Water-level difference',...
    'FontSize',titleFontSize,'FontWeight','bold','Color','k')
grid on
box on
set(ax2,'FontSize',tickFontSize,'FontWeight','bold','XColor','k','YColor','k')
linkaxes([ax1 ax2],'x');


%% FIGURE 2: WEBPLOTDIGITIZER

figure
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% (c) Water levels
ax3 = nexttile;
hold on
plot(RefDT,RefWL,'k-','LineWidth',4);
plot(webPlotRawDT,webPlotWL,'-','Color',colTrace,'LineWidth',2);
xlim(sharedDateLimits)
ylim(waterLevelLimits)
xlabel('Date','FontSize',labelFontSize,'FontWeight','bold','Color','k')
ylabel('Water level (ft)','FontSize',labelFontSize,'FontWeight','bold','Color','k')
title('(c) WebPlotDigitizer - Attempt 4','FontSize',titleFontSize,'FontWeight','bold','Color','k')
legend('Reference Data','WebPlotDigitizer','Location','best',...
    'FontSize',legendFontSize,'FontWeight','bold','TextColor','k')
grid on
box on
set(ax3,'FontSize',tickFontSize,'FontWeight','bold','XColor','k','YColor','k')

% (d) Difference
ax4 = nexttile;
plot(RefDT,Trace_diff,'r-','LineWidth',2);
hold on
yline(0,'k-','LineWidth',1);
xlim(sharedDateLimits)
ylim(differenceLimits)
xlabel('Date','FontSize',labelFontSize,'FontWeight','bold','Color','k')
ylabel('Difference (ft)','FontSize',labelFontSize,'FontWeight','bold','Color','k')
title('(d) WebPlotDigitizer - Water-level difference',...
    'FontSize',titleFontSize,'FontWeight','bold','Color','k')
grid on
box on
set(ax4,'FontSize',tickFontSize,'FontWeight','bold','XColor','k','YColor','k')
linkaxes([ax3 ax4],'x');

%% FIGURES 3 AND 4 LLMS

figure
tiledlayout(2,1)
nexttile
hold on
plot(RefDT, RefWL, ...
    'k', ...
    'LineWidth',4)
plot(chatGPTRawDT, chatGPTWL, ...
    'Color',colLLM, ...
    'LineWidth',2)
xlabel('Date', ...
    'FontSize',labelFontSize, ...
    'FontWeight','bold')
ylabel('Water level (ft)', ...
    'FontSize',labelFontSize, ...
    'FontWeight','bold')
title('(e) ChatGPT - Attempt 4', ...
    'FontSize',titleFontSize, ...
    'FontWeight','bold')
xlim(sharedDateLimits)
ylim(waterLevelLimits)
box on
grid on
legend('Reference Data','ChatGPT 5.5')
ax = gca;
ax.FontSize = tickFontSize;
ax.FontWeight = 'bold';
nexttile
hold on
plot(RefDT, RefWL, ...
    'k', ...
    'LineWidth',4)
plot(geminiRawDT, geminiWL, ...
    'Color',colLLM, ...
    'LineWidth',2)
xlabel('Date', ...
    'FontSize',labelFontSize, ...
    'FontWeight','bold')
ylabel('Water level (ft)', ...
    'FontSize',labelFontSize, ...
    'FontWeight','bold')
title('(f) Gemini - Attempt 4', ...
    'FontSize',titleFontSize, ...
    'FontWeight','bold')
xlim(sharedDateLimits)
ylim(waterLevelLimits)
box on
grid on
legend('Reference Data','Gemini 3.1Pro')
ax = gca;
ax.FontSize = tickFontSize;
ax.FontWeight = 'bold';

%% FUNCTIONS
function [t,wl] = breakAtDateChange(dt,t,wl)

    dt = dt(:);
    t  = t(:);
    wl = wl(:);

    dateOnly = dateshift(dt,'start','day');

    % Break only when two consecutive observations belong
    % to different calendar dates.
    idx = find(dateOnly(2:end) ~= dateOnly(1:end-1));

    for k = numel(idx):-1:1

        t = [
            t(1:idx(k))
            seconds(NaN)
            t(idx(k)+1:end)
        ];

        wl = [
            wl(1:idx(k))
            NaN
            wl(idx(k)+1:end)
        ];

    end

end