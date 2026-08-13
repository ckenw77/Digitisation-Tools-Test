clear; clc; close all

%% LOAD DATA

methodFiles = { ...
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

methodNames = { ...
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

attemptNames = { ...
    'Attempt1'
    'Attempt2'
    'Attempt3'
    'Attempt4'
    'Attempt5'
    'Attempt6'
    'Attempt7'
    'Attempt8'
    'Attempt9'
    };


%% LOAD REFERENCE

M = load('01_Manual.mat');
ManualData = M.MethodData;
dtRef = ManualData.Attempt1_Datetime;
yRef  = ManualData.Attempt1_WaterLevel;
yRef = str2double(string(yRef));
goodRef = ~isnat(dtRef) & isfinite(yRef);
dtRef = dtRef(goodRef);
yRef  = yRef(goodRef);
[dtRef, idxRef] = sort(dtRef);
yRef = yRef(idxRef);

%% CALCULATE RMSE

nMethods  = numel(methodFiles);
nAttempts = numel(attemptNames);
rmse_per = nan(nAttempts, nMethods);
n_per = zeros(nAttempts, nMethods);

for m = 1:nMethods

    % Load current method
    A = load(methodFiles{m});
    MethodData = A.MethodData;

    fprintf('\n%s\n', methodNames{m});
    fprintf('-----------------------------\n');

    for a = 1:nAttempts

        dtField = [attemptNames{a} '_Datetime'];
        wlField = [attemptNames{a} '_WaterLevel'];
        if ~ismember(dtField, MethodData.Properties.VariableNames) || ...
           ~ismember(wlField, MethodData.Properties.VariableNames)
            fprintf('Attempt %d: missing\n', a);
            continue
        end


        % Extract data
        dtA = MethodData.(dtField);
        yA  = MethodData.(wlField);
        yA = str2double(string(yA));
        goodA = ~isnat(dtA) & isfinite(yA);
        dtA = dtA(goodA);
        yA  = yA(goodA);
        if numel(dtA) < 2
            continue
        end
        % Sort chronologically
        [dtA, idxA] = sort(dtA);
        yA = yA(idxA);

       
        % RMSE
        nCompare = min(numel(yRef), numel(yA));
        if nCompare < 5
            continue
        end
        yRef_compare = yRef(1:nCompare);
        yA_compare   = yA(1:nCompare);
        valid = isfinite(yRef_compare) & isfinite(yA_compare);
        if sum(valid) < 5
            continue
        end
        yRef_compare = yRef_compare(valid);
        yA_compare   = yA_compare(valid);
        err = yA_compare - yRef_compare;
        rmse_per(a,m) = sqrt(mean(err.^2));
        n_per(a,m) = numel(err);

        % Print result
        fprintf( ...
            'Attempt %d: N = %d | RMSE = %.4f ft\n', ...
            a, ...
            n_per(a,m), ...
            rmse_per(a,m));
    end

end

%% MEAN AND MEDIAN RMSE

MeanRMSE = mean( ...
    rmse_per, ...
    1, ...
    'omitnan')';
MedianRMSE = median( ...
    rmse_per, ...
    1, ...
    'omitnan')';
ValidAttempts = sum( ...
    ~isnan(rmse_per), ...
    1)';

%% SUMMARY TABLE

MethodID   = (1:nMethods)';
MethodName = string(methodNames(:));

Summary = table( ...
    MethodID, ...
    MethodName, ...
    ValidAttempts, ...
    MeanRMSE, ...
    MedianRMSE);

Summary.Properties.VariableNames = { ...
    'MethodID', ...
    'MethodName', ...
    'ValidAttempts', ...
    'MeanRMSE', ...
    'MedianRMSE'};


%% RANK METHODS BY MEDIAN RMSE

Summary = sortrows( ...
    Summary, ...
    'MedianRMSE', ...
    'ascend');

disp(Summary)

%% REORDER RMSE MATRIX BASED ON MEDIAN RMSE RANKING

[~, idxOrd] = ismember( ...
    Summary.MethodID, ...
    MethodID);

rmseBox = rmse_per(:, idxOrd);

labels = Summary.MethodName;

%% RMSE BOXPLOT FIGURE (for checking)

figure

boxplot( ...
    rmseBox, ...
    'Labels', cellstr(labels), ...
    'Whisker', 1.5)

title('RMSE Distribution Across Attempts')
xlabel('Digitisation Tool')
ylabel('RMSE (feet)')

xtickangle(35)

grid on
box on

ylim([0 inf])

%% SAVE ACCURACY RESULTS

save( ...
    'Accuracy_Summary.mat', ...
    'rmse_per', ...
    'n_per', ...
    'MeanRMSE', ...
    'MedianRMSE', ...
    'methodNames', ...
    'attemptNames', ...
    'Summary');