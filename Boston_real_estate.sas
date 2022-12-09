*INTERNAL DATASET NAME Election;
DATA boston;
PROC IMPORT datafile="boston1.csv" out=boston replace;
delimiter=',';*GAP - TAB;
getname=YES;
run;
*data startsfrom the second row;

PROC PRINT;
RUN;



*HISTOGRAM;
TITLE "Histogram";
PROC UNIVARIATE normal;
VAR medv;
histogram / normal (mu = est sigma = est);
RUN;

*DESCRIPITIVES;
TITLE "Descriptives";
PROC MEANS min mean median q1 q3 max;
VAR medv crime zn indus nox rm age dis rad tax ptratio minor lstat;
RUN;

PROC SORT;*sort the variable;
BY chas;
RUN;
*CREATE BOCPLOT;
PROC BOXPLOT;
PLOT medv*chas;
RUN;

*FREQUENCY TABLE FOR GENDER;
TITLE "FREQUENCY TABLE FOR chas Tract bounds river";
PROC FREQ;
TABLES chas;
RUN;


TITLE "GPLOT PLOT";
*Individual scattering plot;
PROC GPLOT;
PLOT  medv*(crime zn indus chas nox rm age dis rad tax ptratio minor lstat) ;
RUN;


PROC SGSCATTER;
*Matrix Scattering Plot;
TITLE"Scattering plot";
PLOT medv*(crime zn indus chas nox rm age dis rad tax ptratio minor lstat);
RUN;

PROC SGSCATTER;
*Matrix Scattering Plot;
TITLE"Scattering plot for matrixt";
matrix medv crime zn indus chas nox rm age dis rad tax ptratio minor lstat;
RUN;


PROC CORR;
TITLE "correlation";
VAR medv crime zn indus chas nox rm age dis rad tax ptratio minor lstat;
RUN;



*SPLITTING DATA INTO TRAINING & TESTING;
PROC SURVEYSELECT data = boston
OUT = boston_div seed = 45123
SAMPRATE = 0.75 outall;
RUN;

* create new variable medv_y = medv for training set, and = NA for testing set;
data train_boston;
set boston_div;
if selected then medv_y=medv;
run;
proc print data=train_boston;
run;

PROC REG;
TITLE"REGRESSION Analysis";
*Regression analysis;
Model medv = crime zn indus chas nox rm age dis rad tax ptratio minor lstat/vif stb ;
run;
*residual plot full model;
plot student.*(crime zn indus chas nox rm age dis rad tax ptratio minor lstat predicted.);
plot npp.*student.;*Normal Probability plot;
RUN;


PROC REG data=train_boston;
TITLE"REGRESSION Analysis";
*Regression analysis;
Model medv_y = crime zn indus chas nox rm age dis rad tax ptratio minor lstat/vif stb ;
*residual plot full model;
plot student.*(crime zn indus chas nox rm age dis rad tax ptratio minor lstat predicted.);
plot npp.*student.;*Normal Probability plot;
RUN;
run;



*model selection;
PROC REG;
TITLE"Back ward model selection";
*Regression analysis;
Model medv_y = crime zn indus chas nox rm age dis rad tax ptratio minor lstat/selection = backward;
run;


PROC REG;
TITLE"cp selection method";
*Regression analysis;
Model medv_y = crime zn indus chas nox rm age dis rad tax ptratio minor lstat/selection = cp ;
run;

PROC REG data = train_boston;
TITLE"finding OUTLIERS";
model medv_y = crime zn nox rm dis rad tax ptratio minor lstat/vif stb influence r ;
run;

*REMOVING OUTLIERS & INFLUENTIAL POINTS;
DATA train_boston1;
set train_boston;
if _n_ in (255,334,337) then delete;
RUN;
PROC REG data = train_boston1;
title "Final Model";
model medv_y = crime zn nox rm dis rad tax ptratio minor lstat /influence r;
RUN;
*203,335;


DATA train_boston2;
set train_boston1;
if _n_ in (203,335) then delete;
RUN;
PROC REG data = train_boston2;
title "Final Model(removed outliers)";
model medv_y = crime zn nox rm dis rad tax ptratio minor lstat /influence r;
RUN;
*332;


PROC REG data = train_boston2;
title "Final_Model";
model medv_y = crime zn nox rm dis rad tax ptratio minor lstat /vif stb;
plot student.*(crime zn nox rm dis rad tax ptratio minor lstat predicted.);
plot npp.*student.;
RUN;

DATA city;
input crime zn nox rm dis rad tax ptratio minor lstat;
datalines;
0.0644 0 0.443 7.216 3.4333 2 306 18 386.9 4.19  
0.0465 80 0.473 6.565 7.6564 3 452 17 496.9 6.56  
;
PROC PRINT;
RUN;

*joining dataset;
DATA boston_city;
set city train_boston2 ;
RUN;
PROC PRINT data = boston_city;
RUN;



*predicting analysis;
PROC REG data = boston_city;
title "Predicting";
model medv_y = crime zn nox rm dis rad tax ptratio minor lstat / p clm cli;
RUN;


 /* get predicted values for the missing new_y in test set for 2 models*/
title "Test Set";
proc reg data=train_boston2; * MODEL1;
model medv_y = crime zn nox rm dis rad tax ptratio minor lstat; *out=outm1 defines dataset containing Model1 predicted values for test set;
output out=outm1(where=(medv_y=.)) p=yhat;
run;


title "Difference between Observed and Predicted";
data outm1_diff;
set outm1;
diff=medv-yhat;
*diff is the difference between observed and predicted values in test set;
absd=abs(diff);
run; /* computes predictive statistics: root mean square error (rmse) and mean absolute error (mae)*/

proc summary data=outm1_diff;
var diff absd;
output out=outm1_st std(diff)=rmse mean(absd)=mae ;
run;
proc print data=outm1_st;
run;

title 'Validation for Model';
run; *computes correlation of observed and predicted values in test set;
proc corr data=outm1;
var medv yhat;
run;


