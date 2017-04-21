/*Importing Dataset 1*/
PROC IMPORT OUT=FAA1 DATAFILE="/folders/myfolders/sasuser.v94/FAA1" DBMS="xls"
REPLACE;
GETNAMES=YES;
RUN;
PROC PRINT;
RUN;
/*Importing Dataset 2*/
PROC IMPORT OUT=FAA2 DATAFILE="/folders/myfolders/sasuser.v94/FAA2" DBMS="xls"
REPLACE;
GETNAMES=YES;
RUN;
PROC PRINT;
RUN;

/* Combining the two datasets */
DATA COMBINED;
SET FAA1 FAA2;
RUN;
PROC PRINT;
RUN;

/* Remove duplicate rows */
PROC SORT DATA=COMBINED;
BY AIRCRAFT NO_PASG SPEED_GROUND SPEED_AIR HEIGHT PITCH DISTANCE DESCENDING DURATION;
RUN;
PROC SORT DATA=COMBINED NODUPKEY;
BY NO_PASG SPEED_GROUND SPEED_AIR HEIGHT PITCH DISTANCE;
RUN;
PROC PRINT;
RUN;

/* a. Removing the rows with all NULL values */
DATA COMBINED;
SET COMBINED;
IF COMPRESS(CATS(OF _ALL_), '.')=' ' THEN
DELETE;
RUN;
PROC PRINT;
RUN;

/* b. Missing values to total observations in each column */
/*For the continuous variables */
PROC MEANS DATA=COMBINED N NMISS;
VAR _NUMERIC_;
RUN;
/* For the discrete variable- aircraft */
PROC FREQ DATA = COMBINED;
TABLES AIRCRAFT;
RUN;

/* c. Removing columns with >40% missing values, i.e. speed_air */
DATA COMBINED;
SET COMBINED;
DROP SPEED_AIR;
RUN;
PROC PRINT;
RUN;

/* d. Treating missing observations in columns with <20% missing values */
/* To check if mean can be used to replace values */
PROC MEANS DATA=COMBINED MEAN MEDIAN;
RUN;
/*Replacing missing values in duration column with mean of the column */
DATA COMBINED;
SET COMBINED;
IF DURATION='.' THEN DURATION=154.0065385;
RUN;
PROC PRINT;
RUN;

/*Remove observations using the conditions mentioned */
DATA COMBINED;
SET COMBINED;
IF DURATION<40 THEN GOOD_DATA=”NO”;
IF SPEED_GROUND<30 THEN GOOD_DATA=”NO”;
IF SPEED_GROUND>140 THEN GOOD_DATA=”NO”;
IF HEIGHT<6 THEN GOOD_DATA=”NO”;
IF DISTANCE>6000 THEN GOOD_DATA=”NO”;
RUN;
PROC PRINT;
RUN;
DATA COMBINED;
SET COMBINED;
IF GOOD_DATA=”NO” THEN DELETE;
DROP GOOD_DATA;
RUN;
PROC PRINT;
RUN;

PROC FREQ DATA=COMBINED;
VAR AIRCRAFT;
RUN;
PROC UNIVARIATE DATA=COMBINED NORMAL PLOT;
RUN;

/* Creating plots*/
PROC CHART DATA=COMBINED;
VBAR DISTANCE / SUBGROUP=AIRCRAFT;
RUN;
PROC PLOT DATA=COMBINED;
PLOT DISTANCE*DURATION;
RUN;
PROC PLOT DATA=COMBINED;
PLOT DISTANCE*NO_PASG;
RUN;
PROC PLOT DATA=COMBINED;
PLOT DISTANCE*SPEED_GROUND;
RUN;
PROC PLOT DATA=COMBINED;
PLOT DISTANCE*HEIGHT;
RUN;
PROC PLOT DATA=COMBINED;
PLOT DISTANCE*PITCH;
RUN;

/* Creating simple statistics*/
PROC CORR DATA=COMBINED;
VAR DURATION NO_PASG SPEED_GROUND HEIGHT PITCH;
WITH DISTANCE;
RUN;
PROC CORR DATA=COMBINED;
VAR DURATION NO_PASG SPEED_GROUND HEIGHT PITCH;
RUN;

/* Linear Regression */
/*For AIRCRAFT variable, we need to convert it into a binary variable called BOEING with value 1 if it is
BOING or 0 if it is AIRBUS*/
DATA MODEL_DATA;
SET COMBINED;
IF AIRCRAFT="boeing" THEN boeing=1;
ELSE boeing=0;
DROP AIRCRAFT;
RUN;
PROC PRINT;
RUN;

PROC REG DATA=MODEL_DATA;
MODEL DISTANCE= BOEING DURATION NO_PASG SPEED_GROUND HEIGHT PITCH;
OUTPUT OUT=DIAGNOSTICS R=RESIDUAL;
TITLE Regression Analysis of the Cleaned Dataset;
RUN;

PROC REG DATA=MODEL_DATA;
MODEL DISTANCE= BOEING SPEED_GROUND HEIGHT;
OUTPUT OUT=DIAGNOSTICS1 R=RESIDUAL;
TITLE Regression Analysis of the Cleaned Dataset;
RUN;

PROC CHART DATA=DIAGNOSTICS;
VBAR RESIDUAL;
PROC PLOT DATA=DIAGNOSTICS;
PLOT DISTANCE*RESIDUAL;
RUN;
PROC UNIVARIATE DATA=DIAGNOSTICS NORMAL;
VAR RESIDUAL;
RUN;

