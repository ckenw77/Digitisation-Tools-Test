clear; clc; close all

%% 1. LOAD THE TIME AND RMSE DATA

load TIME.mat
load Accuracy_Summary.mat

%% 2. BUILD TABLES

TimeMatrix = [ ...
    ManualT
    NUNIEAUT
    WebplotdigitiserT
    DigitGraphT
    GRABITT
    DagraT
    DigitiseItT
    EngaugedigitiserT
    OriginLabT
    PlotdigitiserT
    GraphGrabberT
    GetDataT
    GeminiT
    ChatGPTT
    Gemini_ProT
    ChatGPTNEWT
];

TimeTable = array2table(TimeMatrix, ...
    'VariableNames', attemptNames, ...
    'RowNames', methodNames);

RMSEMatrix = rmse_per';
RMSEMatrix(1,1) = NaN;

RMSETable = array2table(RMSEMatrix, ...
    'VariableNames', attemptNames, ...
    'RowNames', methodNames);

clearvars -except TimeTable RMSETable

%% 3. CATEGORY DEFINITIONS

categoryNames = ["Manual", "Trace", "Point & Click", "LLM"];
categoryLabels = categoryNames;

traceMethods = ["NUNIEAU", "WebPlotDigitizer", "Plot Digitizer", "DigitGraph"];
traceLabels  = traceMethods;

pointClickMethods = ["GetData", "Engauge Digitizer", "DigitizeIt", ...
                     "GRABIT", "GraphGrabber", "Dagra", "OriginLab"];

pointClickLabels = ["GetData Graph Digitizer", "Engauge Digitizer", "DigitizeIt", ...
                    "GRABIT", "GraphGrabber", "Dagra", "OriginLab"];

llmMethods = ["ChatGPT", "Gemini", "ChatGPT 5.5", "Gemini Pro" ];
llmLabels  = llmMethods;

RMSE = str2double(string(RMSETable{:,:}));
Time = str2double(string(TimeTable{:,:}));

methodList = string(RMSETable.Properties.RowNames);
attemptList = string(RMSETable.Properties.VariableNames);

methodList(methodList == "Webplotdigitiser") = "WebPlotDigitizer";
methodList(methodList == "Plotdigitiser")   = "Plot Digitizer";

%% 4. CATEGORY MATRICES

RMSE_Category = nan(numel(attemptList), numel(categoryNames));
Time_Category = nan(numel(attemptList), numel(categoryNames));

for a = 1:numel(attemptList)

    idx = methodList == "Manual";
    RMSE_Category(a,1) = mean(RMSE(idx,a), 'omitnan');
    Time_Category(a,1) = mean(Time(idx,a), 'omitnan');

    idx = ismember(methodList, traceMethods);
    RMSE_Category(a,2) = mean(RMSE(idx,a), 'omitnan');
    Time_Category(a,2) = mean(Time(idx,a), 'omitnan');

    idx = ismember(methodList, pointClickMethods);
    RMSE_Category(a,3) = mean(RMSE(idx,a), 'omitnan');
    Time_Category(a,3) = mean(Time(idx,a), 'omitnan');

    idx = ismember(methodList, llmMethods);
    RMSE_Category(a,4) = mean(RMSE(idx,a), 'omitnan');
    Time_Category(a,4) = mean(Time(idx,a), 'omitnan');

end

validRMSEAttempts = all(isfinite(RMSE_Category), 2);
validTimeAttempts = all(isfinite(Time_Category), 2);

RMSE_Category_Clean = RMSE_Category(validRMSEAttempts, :);
Time_Category_Clean = Time_Category(validTimeAttempts, :);

%% 5. FRIEDMAN TESTS

[p_cat_rmse, tbl_cat_rmse] = friedman(RMSE_Category_Clean, 1, 'off');
[p_cat_time, tbl_cat_time] = friedman(Time_Category_Clean, 1, 'off');

W_cat_rmse = friedmanKendallsW(tbl_cat_rmse, ...
    size(RMSE_Category_Clean,1), size(RMSE_Category_Clean,2));

W_cat_time = friedmanKendallsW(tbl_cat_time, ...
    size(Time_Category_Clean,1), size(Time_Category_Clean,2));

Category_Friedman_Table = table( ...
    ["RMSE"; "Time"], ...
    [p_cat_rmse; p_cat_time], ...
    [W_cat_rmse; W_cat_time], ...
    [size(RMSE_Category_Clean,1); size(Time_Category_Clean,1)], ...
    'VariableNames', {'Metric','Friedman_p','Kendall_W','N_Attempts'});

disp(Category_Friedman_Table)

%% 6. POSTHOC TESTS BETWEEN CATEGORIES

Category_Posthoc_RMSE = runCategoryPosthoc(categoryNames, RMSE_Category_Clean);
Category_Posthoc_Time = runCategoryPosthoc(categoryNames, Time_Category_Clean);

disp('CATEGORY RMSE POSTHOC TESTS')
disp(Category_Posthoc_RMSE)

disp('CATEGORY TIME POSTHOC TESTS')
disp(Category_Posthoc_Time)

%% 7. WITHIN-CATEGORY TESTS

categoriesToTest = ["Trace", "Point & Click", "LLM"];

WithinGroup_Friedman = table();
WithinGroup_Posthoc_RMSE = table();
WithinGroup_Posthoc_Time = table();

for c = 1:numel(categoriesToTest)

    thisCategory = categoriesToTest(c);

    switch thisCategory
        case "Trace"
            methodsInCategory = traceMethods;
        case "Point & Click"
            methodsInCategory = pointClickMethods;
        case "LLM"
            methodsInCategory = llmMethods;
    end

    idx = ismember(methodList, methodsInCategory);

    RMSE_Group = RMSE(idx,:)';
    Time_Group = Time(idx,:)';

    if size(RMSE_Group,2) > 2
        [p_rmse, tbl_rmse] = friedman(RMSE_Group, 1, 'off');
        W_rmse = friedmanKendallsW(tbl_rmse, ...
            size(RMSE_Group,1), size(RMSE_Group,2));
    else
        p_rmse = signrank(RMSE_Group(:,1), RMSE_Group(:,2));
        W_rmse = NaN;
    end

    if size(Time_Group,2) > 2
        [p_time, tbl_time] = friedman(Time_Group, 1, 'off');
        W_time = friedmanKendallsW(tbl_time, ...
            size(Time_Group,1), size(Time_Group,2));
    else
        p_time = signrank(Time_Group(:,1), Time_Group(:,2));
        W_time = NaN;
    end

    tempSummary = table( ...
        [thisCategory; thisCategory], ...
        ["RMSE"; "Time"], ...
        [p_rmse; p_time], ...
        [W_rmse; W_time], ...
        'VariableNames', {'Category','Metric','P_value','Kendall_W'});

    WithinGroup_Friedman = [WithinGroup_Friedman; tempSummary];

    tempRMSE = runWithinPosthoc(thisCategory, methodsInCategory, RMSE_Group);
    tempTime = runWithinPosthoc(thisCategory, methodsInCategory, Time_Group);

    WithinGroup_Posthoc_RMSE = [WithinGroup_Posthoc_RMSE; tempRMSE];
    WithinGroup_Posthoc_Time = [WithinGroup_Posthoc_Time; tempTime];

end

disp('WITHIN-GROUP FRIEDMAN TESTS')
disp(WithinGroup_Friedman)

disp('WITHIN-GROUP RMSE POSTHOC TESTS')
disp(WithinGroup_Posthoc_RMSE)

disp('WITHIN-GROUP TIME POSTHOC TESTS')
disp(WithinGroup_Posthoc_Time)

%% 8. PREPARE PLOT TABLES

traceTimeTable = WithinGroup_Posthoc_Time(WithinGroup_Posthoc_Time.Category == "Trace", :);
pointTimeTable = WithinGroup_Posthoc_Time(WithinGroup_Posthoc_Time.Category == "Point & Click", :);
llmTimeTable   = WithinGroup_Posthoc_Time(WithinGroup_Posthoc_Time.Category == "LLM", :);

traceRMSETable = WithinGroup_Posthoc_RMSE(WithinGroup_Posthoc_RMSE.Category == "Trace", :);
pointRMSETable = WithinGroup_Posthoc_RMSE(WithinGroup_Posthoc_RMSE.Category == "Point & Click", :);
llmRMSETable   = WithinGroup_Posthoc_RMSE(WithinGroup_Posthoc_RMSE.Category == "LLM", :);

RMSE_Trace = RMSE(ismember(methodList, traceMethods), :)';
RMSE_Point = RMSE(ismember(methodList, pointClickMethods), :)';
RMSE_LLM   = RMSE(ismember(methodList, llmMethods), :)';

Time_Trace = Time(ismember(methodList, traceMethods), :)';
Time_Point = Time(ismember(methodList, pointClickMethods), :)';
Time_LLM   = Time(ismember(methodList, llmMethods), :)';

rmseCLim = getGlobalDifferenceLimit(RMSE_Category_Clean, RMSE_Trace, RMSE_Point, RMSE_LLM);
timeCLim = getGlobalDifferenceLimit(Time_Category_Clean, Time_Trace, Time_Point, Time_LLM);

%% 9. P-VALUE MATRICES — EFFICIENCY

figure
plotPairwiseMatrixLower(categoryNames, categoryLabels, Category_Posthoc_Time, ...
    'Pairwise Comparisons of Efficiency Among Categories')

figure
plotPairwiseMatrixLower(traceMethods, traceLabels, traceTimeTable, ...
    'Pairwise Comparisons of Efficiency Among Trace Tools')

figure
plotPairwiseMatrixLower(pointClickMethods, pointClickLabels, pointTimeTable, ...
    'Pairwise Comparisons of Efficiency Among Point-and-Click Tools')

figure
plotPairwiseMatrixLower(llmMethods, llmLabels, llmTimeTable, ...
    'Pairwise Comparisons of Efficiency Among LLMs')

%% 10. P-VALUE MATRICES — ACCURACY

figure
plotPairwiseMatrixLower(categoryNames, categoryLabels, Category_Posthoc_RMSE, ...
    'Pairwise Comparisons of Accuracy Among Categories')

figure
plotPairwiseMatrixLower(traceMethods, traceLabels, traceRMSETable, ...
    'Pairwise Comparisons of Accuracy Among Trace Tools')

figure
plotPairwiseMatrixLower(pointClickMethods, pointClickLabels, pointRMSETable, ...
    'Pairwise Comparisons of Accuracy Among Point-and-Click Tools')

figure
plotPairwiseMatrixLower(llmMethods, llmLabels, llmRMSETable, ...
    'Pairwise Comparisons of Accuracy Among LLMs')

%% 11. MEAN DIFFERENCE MATRICES — RMSE

figure
plotMeanDifferenceMatrixLower(categoryNames, categoryLabels, RMSE_Category_Clean, ...
    'Mean RMSE Difference Between Categories', ...
    'Mean RMSE Difference (ft)', rmseCLim)

figure
plotMeanDifferenceMatrixLower(traceMethods, traceLabels, RMSE_Trace, ...
    'Mean RMSE Difference Between Trace Tools', ...
    'Mean RMSE Difference (ft)', rmseCLim)

figure
plotMeanDifferenceMatrixLower(pointClickMethods, pointClickLabels, RMSE_Point, ...
    'Mean RMSE Difference Between Point-and-Click Tools', ...
    'Mean RMSE Difference (ft)', rmseCLim)

figure
plotMeanDifferenceMatrixLower(llmMethods, llmLabels, RMSE_LLM, ...
    'Mean RMSE Difference Between LLMs', ...
    'Mean RMSE Difference (ft)', rmseCLim)

%% 12. MEAN DIFFERENCE MATRICES — TIME

figure
plotMeanDifferenceMatrixLower(categoryNames, categoryLabels, Time_Category_Clean, ...
    'Mean Time Difference Between Categories', ...
    'Mean Time Difference (min)', timeCLim)

figure
plotMeanDifferenceMatrixLower(traceMethods, traceLabels, Time_Trace, ...
    'Mean Time Difference Between Trace Tools', ...
    'Mean Time Difference (min)', timeCLim)

figure
plotMeanDifferenceMatrixLower(pointClickMethods, pointClickLabels, Time_Point, ...
    'Mean Time Difference Between Point-and-Click Tools', ...
    'Mean Time Difference (min)', timeCLim)

figure
plotMeanDifferenceMatrixLower(llmMethods, llmLabels, Time_LLM, ...
    'Mean Time Difference Between LLMs', ...
    'Mean Time Difference (min)', timeCLim)

%% HELPER FUNCTIONS

function W = friedmanKendallsW(tbl,n,k)

    chi2 = tbl{2,5};
    W = chi2/(n*(k-1));

end

function PosthocTable = runCategoryPosthoc(categoryNames,CategoryMatrix)

    Method_A = strings(0,1);
    Method_B = strings(0,1);
    Mean_A = nan(0,1);
    Mean_B = nan(0,1);
    MeanDiff_AminusB = nan(0,1);
    P_raw = nan(0,1);

    count = 0;

    for i = 1:numel(categoryNames)-1
        for j = i+1:numel(categoryNames)

            x1 = CategoryMatrix(:,i);
            x2 = CategoryMatrix(:,j);

            valid = isfinite(x1) & isfinite(x2);
            x1 = x1(valid);
            x2 = x2(valid);

            p = signrank(x1,x2);

            count = count + 1;

            Method_A(count,1) = categoryNames(i);
            Method_B(count,1) = categoryNames(j);

            Mean_A(count,1) = mean(x1,'omitnan');
            Mean_B(count,1) = mean(x2,'omitnan');
            MeanDiff_AminusB(count,1) = mean(x1 - x2,'omitnan');

            P_raw(count,1) = p;
        end
    end

    P_bonferroni = min(P_raw*numel(P_raw),1);

    PosthocTable = table( ...
        Method_A, Method_B, Mean_A, Mean_B, ...
        MeanDiff_AminusB, P_raw, P_bonferroni);

end

function PosthocTable = runWithinPosthoc(categoryName,methodsInCategory,GroupMatrix)

    methodsInCategory = methodsInCategory(1:size(GroupMatrix,2));

    Category = strings(0,1);
    Method_A = strings(0,1);
    Method_B = strings(0,1);
    Mean_A = nan(0,1);
    Mean_B = nan(0,1);
    MeanDiff_AminusB = nan(0,1);
    P_raw = nan(0,1);

    count = 0;

    for i = 1:numel(methodsInCategory)-1
        for j = i+1:numel(methodsInCategory)

            x1 = GroupMatrix(:,i);
            x2 = GroupMatrix(:,j);

            valid = isfinite(x1) & isfinite(x2);
            x1 = x1(valid);
            x2 = x2(valid);

            p = signrank(x1,x2);

            count = count + 1;

            Category(count,1) = categoryName;
            Method_A(count,1) = methodsInCategory(i);
            Method_B(count,1) = methodsInCategory(j);

            Mean_A(count,1) = mean(x1,'omitnan');
            Mean_B(count,1) = mean(x2,'omitnan');
            MeanDiff_AminusB(count,1) = mean(x1 - x2,'omitnan');

            P_raw(count,1) = p;
        end
    end

    P_bonferroni = min(P_raw*numel(P_raw),1);

    PosthocTable = table( ...
        Category, Method_A, Method_B, Mean_A, Mean_B, ...
        MeanDiff_AminusB, P_raw, P_bonferroni);

end

function plotPairwiseMatrixLower(labels,displayLabels,posthocTable,plotTitle)

    labels = string(labels);
    displayLabels = string(displayLabels);
    n = numel(labels);

    PMatrix = nan(n);

    for i = 1:n
        PMatrix(i,i) = 0;
    end

    for k = 1:height(posthocTable)

        a = find(labels == posthocTable.Method_A(k));
        b = find(labels == posthocTable.Method_B(k));

        if isempty(a) || isempty(b)
            continue
        end

        PMatrix(a,b) = posthocTable.P_bonferroni(k);
        PMatrix(b,a) = posthocTable.P_bonferroni(k);
    end

    for i = 1:n
        for j = i+1:n
            PMatrix(i,j) = NaN;
        end
    end

    SigMatrix = nan(size(PMatrix));
    SigMatrix(PMatrix >= 0.05) = 0;
    SigMatrix(PMatrix < 0.05)  = 1;

    hold on

    h = imagesc(1:n,1:n,SigMatrix);
    set(h,'AlphaData',~isnan(SigMatrix))

    xlim([0.5 n+0.5])
    ylim([0.5 n+0.5])
    set(gca,'YDir','normal')

cmap = [
    0.85 0.25 0.25    % red = not significant
    0.20 0.70 0.20    % green = significant
];

colormap(gca,cmap)
clim([0 1])
    axis square

    for i = 1:n
        for j = 1:n
            if j >= i
                rectangle( ...
                    'Position',[j-0.5 i-0.5 1 1], ...
                    'FaceColor',[0.8 0.8 0.8], ...
                    'EdgeColor','k', ...
                    'LineWidth',1.2);
            end
        end
    end

    xticks(1:n)
    yticks(1:n)
    xticklabels(displayLabels)
    yticklabels(displayLabels)
    xtickangle(45)

    title(['(a) ' plotTitle], ...
        'FontSize',30, ...
        'FontWeight','bold')

    set(gca, ...
        'FontWeight','bold', ...
        'FontSize',18, ...
        'LineWidth',1.5, ...
        'TickLength',[0 0])

    for g = 1.5:1:n-0.5
        xline(g,'k','LineWidth',1.2)
        yline(g,'k','LineWidth',1.2)
    end

    for i = 1:n
        for j = 1:n

            if j > i
                continue
            end

            if i == j

                text(j,i,'-', ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',18, ...
                    'FontWeight','bold');

            else

pval = PMatrix(i,j);

text(j,i,sprintf('p=%.3f',pval), ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','middle', ...
    'FontSize',14, ...
    'FontWeight','bold');
            end
        end
    end


    cb.TickLabels = {'Not Significant','Significant'};
    cb.Label.String = 'Bonferroni-adjusted significance';
    cb.FontWeight = 'bold';
    cb.FontSize = 18;

    hold off

end

function plotMeanDifferenceMatrixLower(labels,displayLabels,dataMatrix,plotTitle,cbLabel,commonCLim)

    labels = string(labels);
    displayLabels = string(displayLabels);
    n = numel(labels);

    DiffMatrix = nan(n);

    for i = 1:n
        for j = 1:n

            if j <= i

                x1 = dataMatrix(:,i);
                x2 = dataMatrix(:,j);

                valid = isfinite(x1) & isfinite(x2);

                if i == j
                    DiffMatrix(i,j) = 0;
                elseif any(valid)
                    DiffMatrix(i,j) = mean(x2(valid)-x1(valid),'omitnan');
                end
            end
        end
    end

    hold on

    h = imagesc(1:n,1:n,DiffMatrix);
    set(h,'AlphaData',~isnan(DiffMatrix))

    xlim([0.5 n+0.5])
    ylim([0.5 n+0.5])
    set(gca,'YDir','normal')

    colormap(gca,blueWhiteRed(256))
    clim([-commonCLim commonCLim])
    axis square

    for i = 1:n
        for j = 1:n
            if j >= i
                rectangle( ...
                    'Position',[j-0.5 i-0.5 1 1], ...
                    'FaceColor',[0.8 0.8 0.8], ...
                    'EdgeColor','k', ...
                    'LineWidth',1.2);
            end
        end
    end

    xticks(1:n)
    yticks(1:n)
    xticklabels(displayLabels)
    yticklabels(displayLabels)
    xtickangle(45)

    title(['(b) ' plotTitle], ...
        'FontSize',30, ...
        'FontWeight','bold')

    set(gca, ...
        'FontWeight','bold', ...
        'FontSize',18, ...
        'LineWidth',1.5, ...
        'TickLength',[0 0])

    for g = 1.5:1:n-0.5
        xline(g,'k','LineWidth',1.2)
        yline(g,'k','LineWidth',1.2)
    end

    for i = 1:n
        for j = 1:n

            if j > i
                continue
            end

            if i == j
                text(j,i,'-', ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',18, ...
                    'FontWeight','bold');
            else
                text(j,i,sprintf('%.3f',DiffMatrix(i,j)), ...
                    'HorizontalAlignment','center', ...
                    'VerticalAlignment','middle', ...
                    'FontSize',14, ...
                    'FontWeight','bold');
            end
        end
    end

    cb = colorbar;
    cb.Label.String = {cbLabel; '(X-axis Method - Y-axis Method)'};
    cb.FontWeight = 'bold';
    cb.FontSize = 18;

    hold off

end

function globalLim = getGlobalDifferenceLimit(varargin)

    globalLim = 0;

    for k = 1:nargin

        X = varargin{k};
        n = size(X,2);

        for i = 1:n-1
            for j = i+1:n

                x1 = X(:,i);
                x2 = X(:,j);

                valid = isfinite(x1) & isfinite(x2);

                if any(valid)
                    d = mean(x1(valid)-x2(valid),'omitnan');
                    globalLim = max(globalLim,abs(d));
                end
            end
        end
    end

    if globalLim == 0 || isnan(globalLim)
        globalLim = 1;
    end

end

function cmap = blueWhiteRed(m)

    if nargin < 1
        m = 256;
    end

    bottom = [0 0 1];
    middle = [1 1 1];
    top = [1 0 0];

    m1 = floor(m/2);
    m2 = m - m1;

    r = [linspace(bottom(1),middle(1),m1), ...
         linspace(middle(1),top(1),m2)]';

    g = [linspace(bottom(2),middle(2),m1), ...
         linspace(middle(2),top(2),m2)]';

    b = [linspace(bottom(3),middle(3),m1), ...
         linspace(middle(3),top(3),m2)]';

    cmap = [r g b];

end