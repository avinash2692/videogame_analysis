/* Stat 448 project*/
/*Avinash Balakrishnan*/
/*Discriminant Analysis : StarCraft Data*/

/*Formats and Data input*/
ods results;clear
options nodate nonumber;
title ;
*ods rtf file='new latest proj.rtf' nogtitle;
ods pdf file='Avinash Balakrishnan_output.pdf';
*ods noproctitle;
proc format ;
	value leagueindex_fmt 1 = 'Bronze'
						  2 = 'Silver'
						  3 = 'Gold'
						  4 = 'Platinum'
						  5 = 'Diamond'
						  6 = 'Master'
						  7 = 'GrandMaster'
						  8 = 'Professional';
run;


data project;
	*infile '/folders/myfolders/proj_448/skillcraft.csv' dsd missover truncover firstobs=2;
	infile 'skillcraft.csv' dsd missover truncover firstobs=2;
	input GameID LeagueIndex Age HoursPerWeek TotalHours APM
	SelectByHotkeys AssignToHotKeys UniqueHotkeys MinimapAttacks
	MinimapRightClicks NumberOfPACs GapBetweenPACs ActionLatency
	ActionsInPAC TotalMApExplored WorkersMade UniqueUnitMade 
	ComplexUnitsMade ComplexAbilitiesUsed;
format LeagueIndex leagueindex_fmt.;
*N+1;
run;

* Sort Data by League Index;

proc sort data=project;
		by leagueindex;
run;

*Basic Descriptive statistics of variables that should affect expertise based on Original study;

			proc tabulate data=project ;
				class leagueindex;
				var apm ;
				table leagueindex all, apm*(mean);
				format apm 8.3;
				run;
			
			proc tabulate data=project;
				class leagueindex;
				var  actionlatency;
				table leagueindex all, actionlatency*(mean);
				format actionlatency 8.3;
				run;

			proc boxplot data=project;
				plot apm*leagueindex;
				plot numberofpacs*leagueindex;
				plot actionlatency*leagueindex;
				run;

																										
/*Sampling Training and test data*/


			proc surveyselect data=project method=srs samprate=0.7 out=train_project noprint;
			strata leagueindex;
			run;
																										
			proc sort data=project;
					by gameid;
			run;

			proc sort data=train_project;
			by gameid;
			run;

data test_project;
	merge project(in=in_project) train_project(in=in_train);
	by GameID;
	if not in_train and in_project;
run;
/*Frequency Statistics For the master and Training Data to show constant proportions */

			proc freq data=project;
			tables Leagueindex / nocum;
			format leagueindex leagueindex_fmt.;
			run;

			proc freq data=train_project;
			tables Leagueindex / nocum;
			format leagueindex leagueindex_fmt.;
			run;

/*Discriminant Analysis*/
/*Discriminant Analysis with all Predictors:
		Though, form the MANOVA tables, all predictors have a significant F value(P values < 0.01)
it would be appropriate to do a stepwise selection and extract the highly significant predictors*/
			proc discrim data=project method=normal pool=test manova;
				class leagueindex;
				var APM--ComplexAbilitiesUsed;
				priors proportional;
				ods select multstat chisq;
			run;

			/*Stepwise selection based on the total population*/

			proc stepdisc data=project sle=.15 sls=.15;
			   	class leagueindex;
			   	var APM--ComplexAbilitiesUsed;
				ods select Summary;
			run;


/*Discriminant Analysis with most significant variables, proportional priors*/
			proc discrim data=train_project method=normal outstat=calib_project pool=test manova;
			   class leagueindex;
			   var APM--ComplexUnitsMade;
			   	priors proportional;
				ods select ErrorResub ClassifiedResub;
			   
				format leagueindex leagueindex_fmt.;
			run;
			/*Testing data*/
			proc discrim data=calib_project testdata=test_project testout=tout ;
			   class leagueindex;
			   var APM--ComplexUnitsMade;
			   ods select ErrorTestClass ClassifiedTestClass ;
			   	
			   	ods select ErrorTestClass  ClassifiedTestClass ;
			run;


/*Sub grouping to get a better error rate by making a new VAriable called GPIndex*/

data project;
 set project;
 if leagueindex <=3 then gpindex=1;
else if leagueindex > 3 and leagueindex <=5 then gpindex=2;
else if leagueindex > 5 and leagueindex <=8 then gpindex=3;

run; 
/*Sampling Training and test data*/

				proc sort data=project;
				by leagueindex;

				proc surveyselect data=project method=srs samprate=0.7 out=gptrain_project noprint;
				strata leagueindex;
				run;
																														
				proc sort data=project;
						by gameid;
				run;

				proc sort data=gptrain_project;
				by gameid;
				run;

data gptest_project;
	merge project(in=in_project) gptrain_project(in=in_gptrain);
	by GameID;
	if not in_gptrain and in_project;
run;


/*Training and testing the groupwise split data*/ 

				proc discrim data=gptrain_project method=normal outstat=gpcalib_project pool=test manova;
				   class gpindex;
				   var APM--ComplexUnitsMade;
				   	priors proportional;
						ods select ErrorResub ClassifiedResub Levels;
				   ods select ClassifiedCrossVal ErrorCrossVal;
				run;

				proc discrim data=gpcalib_project testdata=gptest_project testout=gptout ;
				   class gpindex;
				   var APM--ComplexUnitsMade;
				   ods select ErrorTestClass ClassifiedTestClass ;
				   
				run;

ods pdf close;
ods rtf close;
