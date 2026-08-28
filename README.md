# Predictive-Claim-Costs-in-Auto-Insurance-
This analysis develops a model to predict bodily injury claim costs. It cleans and explores the data, identifies important predictors, tests multiple GLM distributions and link functions, adds an interaction between sex and age, and compares the best GLM with a decision tree to select the most accurate and interpretable model.
Summary of the Injury Claims Analysis
Overview

The purpose of this analysis is to develop a statistical model that predicts Bodily Injury claim costs using characteristics of the policyholder, vehicle, and driving behavior. The analysis compares several Generalized Linear Models (GLMs) with different distributions and link functions and then compares the best GLM against a Decision Tree. The final goal is to select a model that provides accurate predictions while also being reasonably interpretable.

1. Exploring and Cleaning the Data

The analysis begins by importing the injury_claims.csv dataset and examining its overall structure using summary() and table(). The variables include information such as year, credit rating, sex, marital status, mileage, years the vehicle has been owned, car age, number of drivers, age, vehicle value, number of claims, and bodily injury cost.

The initial exploration suggests that there are no missing values. Some variables contain zero values, but these are not necessarily problematic. For example, owning a vehicle for zero years or having a vehicle with an age of zero can be reasonable.

The analysis focuses on predicting BodilyInjury, so observations where BodilyInjury is zero are removed. Observations where Claims is zero are also removed. There are 4,070 observations where both the claim amount and bodily injury cost are zero, as well as 28 observations with a positive bodily injury cost but zero claims. These observations are removed because they do not provide useful information for predicting the positive claim amounts being studied.

The Claims variable is then removed because it would not be available when making a prediction in advance. In other words, using Claims as a predictor would introduce information that would only be known after the event being predicted.

2. Exploring the Distribution of the Data

Histograms are created for BodilyInjury, Value, and Miles. Additional histograms of the logarithms of BodilyInjury and Value are also examined.

The BodilyInjury variable is highly right-skewed, meaning that most claims are relatively small while a smaller number of claims are very large. Taking the logarithm of BodilyInjury makes its distribution more suitable for statistical modeling.

A logarithmic version of BodilyInjury, called LogBI, is therefore created. A logarithmic version of vehicle value, LogValue, is also initially created.

The analysis then examines the relationship between the potential predictor variables and LogBI using boxplots and scatterplots. These plots are used to identify variables that appear to have meaningful relationships with injury claim costs.

3. Identifying Important Predictors

The analysis examines how the average bodily injury cost changes across different predictor variables.

Several variables appear to have useful relationships with claim costs:

Year: Claim costs generally increase over time.
Credit: Higher credit categories tend to be associated with higher costs. Because the relationship is generally increasing, credit is converted to a numeric scale from 1 to 8.
Sex: Males have a higher average claim cost than females.
Marital Status: Claim costs differ depending on marital status.
Miles: Claim costs tend to decrease as mileage increases.
Years Owned: Claim costs increase as the number of years the vehicle has been owned increases.
Car Age: Older vehicles tend to have higher claim costs.
Drivers: Claim costs increase as the number of drivers increases.

Vehicle Value does not show a sufficiently clear relationship with the response variable, so it is removed from the eventual model.

Age

Age requires special treatment. When average claim cost is plotted against age, there appears to be a nonlinear pattern. Claim costs decrease up to approximately age 27 and then begin increasing.

A standard GLM would have difficulty representing this change in direction with a single linear age coefficient. To address this, two new variables are created:

AgeLow, which represents age up to 27.
AgeHigh, which represents age above 27.

This allows the model to estimate different slopes for the two portions of the age relationship.

4. Splitting the Data

The cleaned dataset is divided into three portions:

Training data: approximately 70% of the observations.
Test data: approximately 20% of the observations.
Holdout data: approximately 10% of the observations.

The training data is used to build the models, the test data is used to compare model performance, and the holdout data provides a final independent check of the selected model.

A random seed of 1000 is used so that the same data split can be reproduced.

5. Comparing GLM Specifications

Several GLMs are considered because bodily injury costs are positive, skewed, and potentially heteroskedastic.

Model 1: Normal Distribution with Identity Link

The first model uses a normal distribution and identity link. Variables are progressively evaluated using likelihood-ratio tests to determine whether they can be removed.

Credit and YearsOwned are initially identified as variables that can be dropped. The resulting model uses the remaining predictors.

The model produces an RMSE of approximately 13,383 on the test data.

Diagnostic plots show problems with the residual distribution, suggesting that the normal distribution with an identity link is not an ideal choice.

Model 2: Normal Distribution with Log Link

The second model retains the normal distribution but uses a log link. This produces an improvement in prediction, although the residual diagnostics still indicate that the model is not completely appropriate.

Again, Credit and YearsOwned are removed.

Model 3: Gamma Distribution with Log Link

A Gamma GLM with a log link is then tested. This is a more natural choice for positive, right-skewed cost data.

The model performs similarly to the previous model, although there is still some skewness in the residuals.

Model 3A: Inverse Gaussian Distribution with Log Link

An inverse Gaussian GLM with a log link is then fitted. This model performs slightly better than the previous GLMs and provides the lowest RMSE at this stage.

The model also handles the positive and skewed nature of bodily injury costs more appropriately.

This model becomes the leading candidate.

Model 4: Linear Regression on Log(BodilyInjury)

Finally, an ordinary linear regression model is fitted to LogBI rather than directly to BodilyInjury.

Because the model predicts the logarithm of the claim amount, the predictions must be transformed back to the original dollar scale. A variance adjustment is included when exponentiating the predictions.

Although the diagnostic plots for this model look good, its test-set RMSE is slightly worse than that of the inverse Gaussian GLM. Therefore, it is not selected as the final model.

6. Selecting the Final Model and Testing Interactions

After selecting the inverse Gaussian GLM with a log link as the best basic model, interaction terms are investigated.

The add1() function is used to examine whether interactions between predictors could improve the model. The most notable interaction is between Sex and AgeLow.

This interaction means that the relationship between age and injury claim cost for younger individuals differs between males and females.

The interaction is added to the model:

Sex:AgeLow

The resulting model has a test-set RMSE of approximately 13,365, which is slightly better than the original inverse Gaussian model.

The final model therefore uses:

Year
Sex
Marital Status
Miles
CarAge
Drivers
AgeLow
AgeHigh
Sex × AgeLow interaction

Credit and YearsOwned are excluded because they were consistently identified as the least useful predictors during model selection.

7. Holdout Validation

The final model is then applied to the holdout dataset, which was not used during the model-building process.

The resulting RMSE is approximately the same as the test-set RMSE. This is important because it suggests that the model's performance is relatively stable on unseen data.

The similar test and holdout errors also provide evidence that the model has not substantially overfit the training data.

8. Comparing the GLM with a Decision Tree

A Decision Tree is also developed using the training data. The tree initially allows many possible splits, but it is subsequently pruned using the complexity parameter that minimizes cross-validation error.

The best Decision Tree uses only a small number of variables, primarily:

Age
CarAge
Sex

Its test-set RMSE is approximately 13,429.

The final GLM has an RMSE of approximately 13,365, which is slightly lower than the Decision Tree's RMSE of approximately 13,429.

Therefore, the Decision Tree does not improve prediction compared with the GLM. Although the tree has the advantage of using fewer variables and being visually intuitive, the GLM provides slightly better predictive performance and more useful coefficient-based interpretations.

9. Interpretation of the Final Model

Because the final GLM uses a log link, its coefficients are interpreted by exponentiating them. This converts the coefficients into percentage changes in expected bodily injury cost.

The model suggests the following relationships, holding the other variables constant:

Year: Each additional calendar year is associated with approximately a 5.32% increase in expected claim cost.
Marital Status: Compared with divorced policyholders, married policyholders have approximately 2.62% lower expected costs, while single policyholders have approximately 0.01% higher costs and widowed policyholders have approximately 0.95% lower costs.
Miles: Each additional 1,000 miles driven is associated with approximately a 0.62% decrease in expected claim cost.
Car Age: Each additional year of vehicle age is associated with approximately a 2.24% increase in expected claim cost.
Number of Drivers: Each additional driver is associated with approximately a 7.41% increase in expected claim cost.
Age: After age 27, expected claim costs increase by approximately 0.24% per additional year.
Sex and Age Interaction

The most interesting relationship is the interaction between Sex and AgeLow.

For individuals younger than 27, the relationship between age and claim cost differs between males and females. The model indicates that younger males have substantially higher expected claim costs than younger females, but this difference becomes much smaller as age approaches 27.

At age 17, males are estimated to have approximately 109.66% higher expected claims than females, all else being equal. By age 27, the difference falls to approximately 15.09%.

The final graph of average claim cost by age and sex is used to visually demonstrate this relationship.

Conclusion

The analysis follows a complete modeling process: the data is explored and cleaned, inappropriate observations and predictors are removed, transformations are considered, several GLM specifications are tested, model diagnostics are examined, interactions are investigated, and the final model is validated using both test and holdout data.

The inverse Gaussian GLM with a log link and a Sex × AgeLow interaction is selected as the best model. It produces an RMSE of approximately 13,365, slightly outperforming the Decision Tree's RMSE of approximately 13,429.

The final model indicates that injury claim costs are influenced by year, sex, marital status, mileage, vehicle age, number of drivers, and age. In particular, the interaction between sex and age for younger drivers is important: the difference in expected claim costs between males and females is much larger at younger ages and becomes considerably smaller by age 27.

Overall, the GLM is preferred because it provides slightly better predictive accuracy than the Decision Tree while also allowing the effects of the predictors to be quantified and interpreted directly.
