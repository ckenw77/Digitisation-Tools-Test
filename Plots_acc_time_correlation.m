clear; clc; close all

%% USER SETTINGS

dataRange_ft = 13.5;
goodRMSE_ft = 0.01 * dataRange_ft;
timeScale = 60;

%% LOAD DATA

TIMERAW = load('TIME.mat');
ACC = load('Accuracy_Summary.mat');
methodNames  = string(ACC.methodNames(:));
attemptNames = string(ACC.attemptNames(:))';
rmse_per  = ACC.rmse_per;
n_per     = ACC.n_per;
MeanRMSE  = ACC.MeanRMSE;
MedianRMSE = ACC.MedianRMSE;
AccuracySummary = ACC.Summary;
nMethods  = numel(methodNames);
nAttempts = numel(attemptNames);

fprintf('\nLoaded %d methods and %d attempts.\n', ...
    nMethods, nAttempts);

%% LLM METHODS

llmMethods = [ ...
    "Gemini 3.1Pro"
    "ChatGPT5.5"
    ];

%% TIME DATA

timeMethodNames = [ ...
    "Manual"
    "NUNIEAU"
    "WebPlotDigitizer"
    "DigitGraph"
    "GRABIT"
    "Dagra"
    "DigitizeIt"
    "Engauge Digitizer"
    "OriginLab"
    "Plot Digitizer"
    "GraphGrabber"
    "GetData"
    "Gemini 3.1Pro"
    "ChatGPT5.5"
    ];

timeVars = { ...
    'ManualT'
    'NUNIEAUT'
    'WebplotdigitiserT'
    'DigitGraphT'
    'GRABITT'
    'DagraT'
    'DigitiseItT'
    'EngaugedigitiserT'
    'OriginLabT'
    'PlotdigitiserT'
    'GraphGrabberT'
    'GetDataT'
    'Gemini_3ProT'
    'ChatGPT5T'
    };

TimeMatrix = nan(numel(timeMethodNames), nAttempts);
for k = 1:numel(timeVars)
    thisVar = timeVars{k};
    if ~isfield(TIMERAW, thisVar)
        error('TIME.mat is missing variable: %s', thisVar);
    end
    TimeMatrix(k,:) = forceRowNumeric( ...
        TIMERAW.(thisVar), ...
        nAttempts, ...
        thisVar);
end
TimeTable = array2table( ...
    TimeMatrix, ...
    'VariableNames', cellstr(attemptNames), ...
    'RowNames', cellstr(timeMethodNames));

%% RMSE DATA

if size(rmse_per,1) ~= nAttempts || ...
        size(rmse_per,2) ~= nMethods
    error(['rmse_per should be %d x %d, but is %d x %d.'], ...
        nAttempts, ...
        nMethods, ...
        size(rmse_per,1), ...
        size(rmse_per,2));
end
RMSEMatrix = rmse_per';
RMSETable = array2table( ...
    RMSEMatrix, ...
    'VariableNames', cellstr(attemptNames), ...
    'RowNames', cellstr(methodNames));

%% ALIGN TIME AND RMSE METHODS

missingTime = setdiff(methodNames, timeMethodNames);
if ~isempty(missingTime)
    error('Methods missing from TIME.mat: %s', ...
        strjoin(missingTime, ', '));
end
TimeTable = TimeTable(cellstr(methodNames), :);

%% BUILD PLOT TABLE

nRows = nMethods * nAttempts;
Attempt = strings(nRows,1);
Method  = strings(nRows,1);
RMSE    = nan(nRows,1);
Time    = nan(nRows,1);
row = 0;
for m = 1:nMethods
    for a = 1:nAttempts
        row = row + 1;
        Attempt(row) = attemptNames(a);
        Method(row)  = methodNames(m);
        RMSE(row) = RMSETable{m,a};
        Time(row) = TimeTable{m,a} / timeScale;
    end
end

NRMSE_percent = (RMSE ./ dataRange_ft) * 100;
PlotTable = table( ...
    Attempt, ...
    Method, ...
    RMSE, ...
    NRMSE_percent, ...
    Time);

PlotTableRMSE = PlotTable( ...
    isfinite(PlotTable.RMSE), :);
PlotTableBoth = PlotTable( ...
    isfinite(PlotTable.RMSE) & ...
    isfinite(PlotTable.Time), :);

%% RMSE ORDER

plotMethodOrder = string(AccuracySummary.MethodName);
fprintf('\nPlotting order by median RMSE:\n');
for k = 1:numel(plotMethodOrder)
    idx = PlotTableRMSE.Method == plotMethodOrder(k);
    vals = PlotTableRMSE.RMSE(idx);
    fprintf('%02d %-25s Median RMSE = %.6f ft\n', ...
        k, ...
        prettyMethodName(plotMethodOrder(k)), ...
        median(vals,'omitnan'));
end

%% LLM CHECK

fprintf('\nLLM RMSE check:\n');
for k = 1:numel(llmMethods)
    idx = PlotTableRMSE.Method == llmMethods(k);
    if any(idx)
        vals = PlotTableRMSE.RMSE(idx);
        fprintf(['%-15s Mean RMSE = %.4f ft | ' ...
            'Median RMSE = %.4f ft | n = %d\n'], ...
            prettyMethodName(llmMethods(k)), ...
            mean(vals,'omitnan'), ...
            median(vals,'omitnan'), ...
            numel(vals));
    end
end

fprintf('\nGood RMSE threshold = %.4f ft = %.2f%% of %.1f ft range.\n', ...
    goodRMSE_ft, ...
    goodRMSE_ft / dataRange_ft * 100, ...
    dataRange_ft);


%% FIGURE 1a — RMSE, LOG SCALE

    plotBoxByMethod( ...
        PlotTableRMSE, ...
        plotMethodOrder, ...
        "RMSE", ...
        true, ...
        'Log RMSE (feet)', ...
        '(a) Comparison of accuracy', ...
        goodRMSE_ft);
    ylim([10^(-1.5) 20])

%% FIGURE 1b — TIME

    plotBoxByMethod( ...
        PlotTableBoth, ...
        plotMethodOrder, ...
        "Time", ...
        false, ...
        'Time (hours)', ...
        '(b) Comparison of efficiency', ...
        []);


%% FIGURE 2 — RMSE VS TIME, LOG SCALE

    figure
    hold on
    set(gca, 'YScale', 'log')
    [colManual, colTrace, colPoint, colLLM] = methodColours();
    hManual = patch( ...
        nan, nan, colManual, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colManual, ...
        'LineWidth', 1.8);
    hTrace = patch( ...
        nan, nan, colTrace, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colTrace, ...
        'LineWidth', 1.8);
    hPoint = patch( ...
        nan, nan, colPoint, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colPoint, ...
        'LineWidth', 1.8);
    hLLM = patch( ...
        nan, nan, colLLM, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colLLM, ...
        'LineWidth', 1.8);
    for k = 1:numel(plotMethodOrder)
        idx = PlotTableBoth.Method == plotMethodOrder(k);
        if any(idx)
            col = getMethodColour(plotMethodOrder(k));
            x = PlotTableBoth.Time(idx);
            y = PlotTableBoth.RMSE(idx);
            valid = isfinite(x) & isfinite(y) & y > 0;
            drawPolygonGroup(gca, x(valid), y(valid), col);
        end
    end
    
    xRect = [0, 5/60, 5/60, 0];
    yRect = [10^(-1.5), 10^(-1.5), 0.135, 0.135];
    hRedBox = patch( ...
        xRect, ...
        yRect, ...
        'r', ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', 'r', ...
        'LineStyle', '--', ...
        'LineWidth', 2);
    xlabel('Time (hours)', ...
        'FontSize', 25, ...
        'FontWeight', 'bold');
    ylabel('Log RMSE (feet)', ...
        'FontSize', 25, ...
        'FontWeight', 'bold');
    title('Relationship Between Accuracy and Efficiency', ...
        'FontSize', 40, ...
        'FontWeight', 'bold');
    grid on
    box on
    ylim([10^(-1.5) 20])
    xlim([0 3.75])
    xticks(0:0.5:3.5)
    set(gca, 'FontSize', 24)
    hold off

%% RMSE VS TIME CORRELATION
    
    figure
    tiledlayout(1, 2)

    nexttile
    TcorrAll = PlotTableBoth;
    plotCorrelationPanel( ...
        TcorrAll, ...
        '(a) Correlation between RMSE and Time');
    nexttile
    TcorrNoLLM = PlotTableBoth( ...
        ~ismember(PlotTableBoth.Method, llmMethods), :);
    plotCorrelationPanel( ...
        TcorrNoLLM, ...
        '(b) Correlation between RMSE and Time without LLM');

 %% RMSE vs TIME (100YR RECORD)
    
    targetRecordYears = 100;
    yearsPerAttempt = 1/52;
    workingHoursPerDay = 8;
    workingDaysPerYear = 260;
    workingHoursPerYear = ...
        workingHoursPerDay * workingDaysPerYear;
    PlotTable.Time100yr_hours = ...
        PlotTable.Time .* ...
        (targetRecordYears ./ yearsPerAttempt);
    PlotTable.Time100yr_workingYears = ...
        PlotTable.Time100yr_hours ./ workingHoursPerYear;
    PlotTableRMSE = PlotTable( ...
        isfinite(PlotTable.RMSE), :);
    PlotTableBoth = PlotTable( ...
        isfinite(PlotTable.RMSE) & ...
        isfinite(PlotTable.Time) & ...
        isfinite(PlotTable.Time100yr_workingYears), :);
    fprintf('\n100-year record conversion assumptions:\n');
    fprintf('Each attempt represents %.6f record-years.\n', ...
        yearsPerAttempt);
    fprintf('Working year = %d hours.\n', ...
        workingHoursPerYear);
    
    disp(PlotTable(1:min(20, height(PlotTable)), ...
        {'Attempt', 'Method', 'NRMSE_percent', ...
         'Time', 'Time100yr_workingYears'}));

    figure
    hold on
    set(gca, 'YScale', 'log')
    [colManual, colTrace, colPoint, colLLM] = methodColours();
    hManual = patch( ...
        nan, nan, colManual, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colManual, ...
        'LineWidth', 1.8);
    hTrace = patch( ...
        nan, nan, colTrace, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colTrace, ...
        'LineWidth', 1.8);
    hPoint = patch( ...
        nan, nan, colPoint, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colPoint, ...
        'LineWidth', 1.8);
    hLLM = patch( ...
        nan, nan, colLLM, ...
        'FaceAlpha', 0.25, ...
        'EdgeColor', colLLM, ...
        'LineWidth', 1.8);
   
    for k = 1:numel(plotMethodOrder)
    
        idx = PlotTableBoth.Method == plotMethodOrder(k);
    
        if any(idx)
    
            col = getMethodColour(plotMethodOrder(k));
    
            x = PlotTableBoth.Time100yr_workingYears(idx);
            y = PlotTableBoth.NRMSE_percent(idx);
    
            valid = ...
                isfinite(x) & ...
                isfinite(y) & ...
                x >= 0 & ...
                y > 0;
    
            drawPolygonGroup( ...
                gca, ...
                x(valid), ...
                y(valid), ...
                col);
    
        end
    
    end

    hThreshold = yline(1,'r--','LineWidth', 2.5);
       xlabel( ...
        'Years required to recover 100-year record', ...
        'FontSize', 20, ...
        'FontWeight', 'bold');
    ylabel( ...
        'RMSE (% of marigram range)', ...
        'FontSize', 20, ...
        'FontWeight', 'bold');
    title( ...
        'Comparison of all digitisation tools', ...
        'FontSize', 30, ...
        'FontWeight', 'bold');
    grid on
    box on
    ax = gca;
    ax.FontSize = 24;
    ax.FontWeight = 'bold';
    allX = PlotTableBoth.Time100yr_workingYears;
    allY = PlotTableBoth.NRMSE_percent;
    allX = allX(isfinite(allX) & allX >= 0);
    allY = allY(isfinite(allY) & allY > 0);
    xlim([0,10])
    if ~isempty(allY)
        yMinimum = min(allY);
        yMaximum = max(allY);
        yMinimum = min(yMinimum, 1);
        yMaximum = max(yMaximum, 1);
        ylim([ ...
            10^(floor(log10(yMinimum))), ...
            10^(ceil(log10(yMaximum))) ...
            ]);
    end


%% HELPER FUNCTIONS

    
    function rowOut = forceRowNumeric(x, nExpected, varName)
    
        if isduration(x)
    
            rowOut = minutes(x(:))';
    
        elseif isnumeric(x) || islogical(x)
    
            rowOut = double(x(:))';
    
        else
    
            rowOut = str2double(string(x(:)))';
    
        end
    
        if numel(rowOut) ~= nExpected
    
            error('%s has %d values, but expected %d attempts.', ...
                varName, ...
                numel(rowOut), ...
                nExpected);
    
        end
    
    end
    
    function sortedMethods = sortMethodsByMedianRMSE(T, methodsToSort)
    
        medVals = nan(numel(methodsToSort), 1);
    
        for k = 1:numel(methodsToSort)
    
            idx = T.Method == methodsToSort(k);
    
            if any(idx)
    
                vals = T.RMSE(idx);
                vals = vals(isfinite(vals));
    
                if ~isempty(vals)
                    medVals(k) = median(vals, 'omitnan');
                end
    
            end
    
        end
    
        [~, sortIdx] = sort( ...
            medVals, ...
            'ascend', ...
            'MissingPlacement', 'last');
    
        sortedMethods = methodsToSort(sortIdx);
        medValsSorted = medVals(sortIdx);
    
        sortedMethods = sortedMethods(isfinite(medValsSorted));
    
    end
    
    function plotBoxByMethod(T, methodOrder, varName, useLogScale, yLab, figTitle, thresholdVal)
    
        varName = char(varName);
    
        figure
        hold on
    
        if useLogScale
            set(gca, 'YScale', 'log')
        end
    
        [colManual, colTrace, colPoint, colLLM] = methodColours();
    
        % Dummy handles for legend
        hManual = scatter(nan, nan, 80, colManual, 'filled');
        hTrace  = scatter(nan, nan, 80, colTrace,  'filled');
        hPoint  = scatter(nan, nan, 80, colPoint,  'filled');
        hLLM    = scatter(nan, nan, 80, colLLM,    'filled');
    
        for k = 1:numel(methodOrder)
    
            idx = T.Method == methodOrder(k);
            vals = T.(varName)(idx);
    
            vals = vals(isfinite(vals));
    
            if useLogScale
                vals = vals(vals > 0);
            end
    
            if isempty(vals)
                continue
            end
    
            col = getMethodColour(methodOrder(k));
    
            drawColouredBox(k, vals, col);
    
        end
    
        % Only add threshold line if thresholdVal is supplied.
        % Plot 1 passes [], so no red line appears there.
        hThreshold = [];
    
        if ~isempty(thresholdVal) && isfinite(thresholdVal)
    
            hThreshold = yline( ...
                thresholdVal, ...
                'r--', ...
                'LineWidth', 2);
    
        end
    
        xlim([0.5 numel(methodOrder) + 0.5])
    
        xticks(1:numel(methodOrder))
        xticklabels(prettyMethodLabels(methodOrder))
        xtickangle(45)
    
        ylabel(yLab, ...
            'FontSize', 25, ...
            'FontWeight', 'bold');
    
        title(figTitle, ...
            'FontSize', 40, ...
            'FontWeight', 'bold');
    
        ax = gca;
        ax.FontSize = 18;
        ax.FontWeight = 'bold';
    
        % Legend labels with coloured text
        legendHandles = [hManual hTrace hPoint hLLM];
    
        legendLabels = { ...
            colouredLegendLabel('Manual', colManual), ...
            colouredLegendLabel('Trace', colTrace), ...
            colouredLegendLabel('Point & Click', colPoint), ...
            colouredLegendLabel('LLM', colLLM)};
    
        % Add threshold key only when the red dashed line exists
        if ~isempty(hThreshold) && isgraphics(hThreshold)
    
            legendHandles = [legendHandles hThreshold];
    
            legendLabels = [legendLabels, ...
                {colouredLegendLabel('1% of marigram range', [1 0 0])}];
    
        end
    
        legend( ...
            legendHandles, ...
            legendLabels, ...
            'Interpreter', 'tex', ...
            'FontSize', 15, ...
            'Location', 'bestoutside');
    
        grid on
        box on
        hold off
    
    end
    
    
    function nameOut = prettyMethodName(methodName)
    
        methodName = string(methodName);
    
        if methodName == "Gemini Pro"
    
            nameOut = "Gemini 3.1 Pro";
    
        else
    
            nameOut = methodName;
    
        end
    
    end
    
    function labels = prettyMethodLabels(methodOrder)
    
        labels = cellstr(methodOrder);
    
        labels(strcmp(labels, 'GetData')) = {'GetData Graph Digitizer'};
        labels(strcmp(labels, 'Gemini Pro')) = {'Gemini 3.1 Pro'};
    
    end
    
    function drawColouredBox(x0, vals, faceCol)
    
        vals = vals(:);
        vals = vals(isfinite(vals));
    
        if isempty(vals)
            return
        end
    
        % Boxplot statistics in original data units
    
        q1 = prctile(vals, 25);
        q2 = median(vals, 'omitnan');
        q3 = prctile(vals, 75);
    
        iqrVal = q3 - q1;
    
        lowerFence = q1 - 3 * iqrVal;
        upperFence = q3 + 3 * iqrVal;
    
        isOutlier = vals < lowerFence | vals > upperFence;
    
        nonOutlierVals = vals(~isOutlier);
        outlierVals    = vals(isOutlier);
    
        if isempty(nonOutlierVals)
            lowerWhisker = min(vals);
            upperWhisker = max(vals);
        else
            lowerWhisker = min(nonOutlierVals);
            upperWhisker = max(nonOutlierVals);
        end
    
        % Safety: make sure whiskers cannot appear inside the box
        lowerWhisker = min(lowerWhisker, q1);
        upperWhisker = max(upperWhisker, q3);
    
        % Draw box
    
        boxWidth = 0.45;
    
        patch( ...
            [x0 - boxWidth/2, x0 + boxWidth/2, ...
             x0 + boxWidth/2, x0 - boxWidth/2], ...
            [q1, q1, q3, q3], ...
            faceCol, ...
            'FaceAlpha', 0.45, ...
            'EdgeColor', faceCol, ...
            'LineWidth', 1.6);
    
        % Draw median
    
        plot( ...
            [x0 - boxWidth/2, x0 + boxWidth/2], ...
            [q2, q2], ...
            'Color', 'k', ...
            'LineWidth', 1.6);
    
        % Draw whiskers
    
        plot( ...
            [x0, x0], ...
            [lowerWhisker, q1], ...
            'Color', faceCol, ...
            'LineWidth', 1.4);
    
        plot( ...
            [x0, x0], ...
            [q3, upperWhisker], ...
            'Color', faceCol, ...
            'LineWidth', 1.4);
    
        capWidth = 0.25;
    
        plot( ...
            [x0 - capWidth/2, x0 + capWidth/2], ...
            [lowerWhisker, lowerWhisker], ...
            'Color', faceCol, ...
            'LineWidth', 1.4);
    
        plot( ...
            [x0 - capWidth/2, x0 + capWidth/2], ...
            [upperWhisker, upperWhisker], ...
            'Color', faceCol, ...
            'LineWidth', 1.4);
    
        % Draw outliers as crosses
    
        if ~isempty(outlierVals)
    
            % Deterministic jitter so overlapping crosses can be seen
            if numel(outlierVals) == 1
                jitter = 0;
            else
                jitter = linspace(-0.08, 0.08, numel(outlierVals))';
            end
    
            plot( ...
                x0 + jitter, ...
                outlierVals, ...
                'x', ...
                'Color', faceCol, ...
                'MarkerSize', 9, ...
                'LineWidth', 2.0);
    
        end
    
    end
    
    function c = getMethodColour(methodName)
    
        methodName = string(methodName);
    
        tracingMethods = [ ...
            "DigitGraph"
            "WebPlotDigitizer"
            "Plot Digitizer"
            "NUNIEAU"
            ];
    
        pointMethods = [ ...
            "Dagra"
            "GraphGrabber"
            "OriginLab"
            "DigitizeIt"
            "GetData"
            "GRABIT"
            "Engauge Digitizer"
            ];
    
        llmMethods = [ ...
            "ChatGPT5.5"
            "Gemini 3.1Pro"
            ];
    
        [colManual, colTrace, colPoint, colLLM] = methodColours();
    
        if methodName == "Manual"
    
            c = colManual;
    
        elseif any(methodName == tracingMethods)
    
            c = colTrace;
    
        elseif any(methodName == pointMethods)
    
            c = colPoint;
    
        elseif any(methodName == llmMethods)
    
            c = colLLM;
    
        else
    
            c = [0 0 0];
    
        end
    
    end
    
    function [colManual, colTrace, colPoint, colLLM] = methodColours()
    
        colManual = [0.00 0.60 0.50];
        colTrace = [0.00 0.45 0.70];
        colPoint = [0.90 0.60 0.00];
        colLLM = [0.80 0.00 0.50];
    
    end
    
    function h = drawPolygonGroup(ax, x, y, faceCol)
    
        x = x(:);
        y = y(:);
    
        good = isfinite(x) & isfinite(y);
    
        x = x(good);
        y = y(good);
    
        if isempty(x)
    
            h = gobjects(1);
            return
    
        end
    
        if numel(x) < 3
    
            h = plot( ...
                ax, ...
                x, ...
                y, ...
                '-', ...
                'Color', faceCol, ...
                'LineWidth', 2);
    
            return
    
        end
    
        XY = unique([x y], 'rows');
    
        x = XY(:, 1);
        y = XY(:, 2);
    
        if size(XY, 1) < 3
    
            h = plot( ...
                ax, ...
                x, ...
                y, ...
                '-', ...
                'Color', faceCol, ...
                'LineWidth', 2);
    
            return
    
        end
    
        try
    
            K = convhull(x, y);
    
            h = patch( ...
                ax, ...
                x(K), ...
                y(K), ...
                faceCol, ...
                'FaceAlpha', 0.25, ...
                'EdgeColor', faceCol, ...
                'LineWidth', 1.8);
    
        catch
    
            [xSort, idx] = sort(x);
            ySort = y(idx);
    
            h = plot( ...
                ax, ...
                xSort, ...
                ySort, ...
                '-', ...
                'Color', faceCol, ...
                'LineWidth', 2);
    
        end
    
    end
    
    function plotCorrelationPanel(T, panelTitle)
    
        hold on
    
        T = T(isfinite(T.Time) & isfinite(T.RMSE), :);
    
        scatter( ...
            T.Time, ...
            T.RMSE, ...
            55, ...
            'filled', ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.6);
    
        if height(T) >= 3
    
            [rhoVal, pVal] = corr( ...
                T.Time, ...
                T.RMSE, ...
                'Type', 'Spearman', ...
                'Rows', 'complete');
    
        else
    
            rhoVal = NaN;
            pVal = NaN;
    
        end
    
        if height(T) >= 2 && range(T.Time) > 0
    
            pFit = polyfit(T.Time, T.RMSE, 1);
    
            xFit = linspace( ...
                min(T.Time), ...
                max(T.Time), ...
                200);
    
            yFit = polyval(pFit, xFit);
    
            plot( ...
                xFit, ...
                yFit, ...
                'r-', ...
                'LineWidth', 2.5);
    
        end
    
        xlabel('Time (hours)', ...
            'FontSize', 14, ...
            'FontWeight', 'bold');
    
        ylabel('RMSE (feet)', ...
            'FontSize', 14, ...
            'FontWeight', 'bold');
    
        title(panelTitle, ...
            'FontSize', 18, ...
            'FontWeight', 'bold');
    
        txt = sprintf( ...
            'Spearman \\rho = %.3f\np = %.3g', ...
            rhoVal, ...
            pVal);
    
        text( ...
            0.95, ...
            0.95, ...
            txt, ...
            'Units', 'normalized', ...
            'HorizontalAlignment', 'right', ...
            'VerticalAlignment', 'top', ...
            'FontSize', 13, ...
            'FontWeight', 'bold', ...
            'BackgroundColor', 'w', ...
            'EdgeColor', 'k');
    
        grid on
        box on
        set(gca, 'FontWeight', 'bold')
    
        hold off
    
    end
    
    
    function s = colouredLegendLabel(labelText, rgbColour)
    
        s = sprintf( ...
            '\\color[rgb]{%.3f %.3f %.3f}%s', ...
            rgbColour(1), ...
            rgbColour(2), ...
            rgbColour(3), ...
            labelText);
    
    end