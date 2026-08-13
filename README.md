Load_and_interpolate.m: loads the data from the excel file into mat files and interpolates to 15-minute intervals the tests where a 15-minute resolution was not the default.

Accuracy.m: Calculates the RMSE for each tool and each attempt

Example_comparisons.m: Plots attempt 4 for Engauge Digitizer, WebPlotDigitizer, ChatGPT and Gemini against the Manual reference dataset. The differences of Engauge Digitizer and WebPlotDigitizer are also included.

Plots_acc_time_correlation: Plots the accuracy and speed of digitisation box plots. Additionally plots the accuracy and speed comparison plot. Correlation calculations and plots are also made

Stats.m: Calculates the Friedman test and post-hoc Wilcoxon tests with Bonferroni correction and plots the results

Plotted_against_reference.m: Plots the test data against the reference data
