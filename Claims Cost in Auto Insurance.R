#Exploring the Data 
BI = read.csv('injury_claims.csv', stringsAsFactors = TRUE)

summary(BI)
table(BI$Credit)

# There appears to be no missing values in the Data.
# YearsOwned and CarAge can be zero, but owning the car for less than a complete year is possible
# Claims and BodilyInjury have zero values, not serving our purpose. They do not serve our purpose
# and thus will be removed
# CarAge and BodilyInjury have some high values, but both are plausible so without further reason
# they will remain in the dataset

#Checking for Zero Cost or Zero Claims 
ZeroCost <- ifelse(BI$BodilyInjury == 0, 0, 1)
ZeroClaim <- ifelse(BI$Claims == 0, 0, 1) 
table(ZeroCost, ZeroClaim)
rm(ZeroCost)
rm(ZeroClaim)

# There are 4070 cases where both the cost and claim amount are zero. We will remove these from our
# study. There are also 28 cases where we have a positive amount on Cost but have zero claims. Since we
# are unsure of which of the two values is incorrect, we will also remove these fron our study

# Since we are predicting our claim amounts, having the claim variable is a problem. Since the number
# of claims will never be known ahead of time. 

BI <- BI[BI$BodilyInjury != 0, ]
BI <- BI[BI$Claims != 0, ]
BI$Claims <- NULL

summary(BI)


#Creating Histograms for Variables of Interest.
library(ggplot2)

ggplot(BI, aes(x =BodilyInjury)) +
  geom_histogram()
ggplot(BI, aes(x = log(BodilyInjury))) + 
  geom_histogram()

ggplot(BI, aes(x = Value)) +
  geom_histogram()
ggplot(BI, aes(x = log(Value))) +
  geom_histogram()

ggplot(BI, aes(x = Miles)) + 
  geom_histogram()

# Applying a log transform to our BodilyInjury and Value is useful. Will add columns to our BI 
BI$LogBI <- log(BI$BodilyInjury)
BI$LogValue <- log(BI$Value)


# Exploring relationships of predictor variables of the target 
ggplot(BI, aes(x=as.factor(Year), y=LogBI)) + 
  geom_boxplot()
ggplot(BI, aes(x=Credit, y=LogBI)) +
  geom_boxplot()
ggplot(BI, aes(x=Sex, y=LogBI)) +
  geom_boxplot()
ggplot(BI, aes(x=MaritalStatus, y=LogBI)) +
  geom_boxplot()
ggplot(BI, aes(x=as.factor(Miles/1000), y=LogBI)) +
  geom_boxplot()
ggplot(BI, aes(x=as.factor(YearsOwned), y=LogBI)) +
  geom_boxplot()
ggplot(BI, aes(x=as.factor(Drivers), y=LogBI)) +
  geom_boxplot()

ggplot(BI, aes(x=LogValue, y=LogBI)) +
  geom_point()
ggplot(BI, aes(x=Age, y=LogBI)) +
  geom_point()

#Average Cost by predictor 
library(dplyr)
BI |>
  group_by(Year) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
    )
BI |>
  group_by(Credit) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(Sex) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(MaritalStatus) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(Miles / 1000) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(YearsOwned) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(CarAge) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(Drivers) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )

#Bin Values for Age and Values 
BI$AgeCut <- cut(BI$Age, 10)
BI$LVCut <- cut(BI$LogValue, 10)

BI |>
  group_by(AgeCut) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI |>
  group_by(LVCut) |>
  summarise(
    mean = mean(BodilyInjury), 
    n = n()
  )
BI$LVCut <- NULL
BI$AgeCut <- NULL

# Upward trend by year, keep for model
# Credit score shows an upward trend, though it’s not perfect. Using it directly may lower predicted values for those with poorer credit. 
# To address this, we’ll convert it to numeric values from 1 to 8 to ensure a consistent increase
# Men have a higher mean, keep for model
# Marital Status can change mean by $300, keep for model 
# Costs decrease with more miles driven, keep for model
# Costs increase the more the car is owned, keep for model. 
# Costs increase with the age of the car, keep for model
# Costs increase when the number of drivers increase, keep for model
# High start for age, then a drop followed by an increase. 
#No clean pattern for logValue, will NOT keep for model 

# Plot for Age Means 
AgeMeans <- BI |>
  group_by(Age) |> 
  summarise(mean = mean(BodilyInjury)) |> 
  as.data.frame()
AgeMeans
ggplot(data = AgeMeans, aes(x = Age, y = mean)) +
  geom_point()
# There is a linear decrease until 27 then a linear increase after that. While a decision tree can capture
# non-linear relationships, a GLM cannot. To address this we will create new variables AgeLow = Age <= 27
# AgeHigh else  


#Altering our data based on results 
BI$Value <- NULL 
BI$LogValue <- NULL 

BI$AgeLow <- ifelse(BI$Age < 27, BI$Age, 27)
BI$AgeHigh <- ifelse(BI$Age > 27, BI$Age, 27)
summary(lm(data=BI, LogBI~ AgeLow + AgeHigh))

BI$CreditNum <- as.numeric(BI$Credit) # Sets A = 1, B = 2, etc.
BI$Credit <- NULL
summary(BI)

# Selecting an Initial Model 
# When considering which model approach to use, two methods came to mind. A GLM and a Decision Tree(DT)
# Our goal is to extract the most important features. A DT would handle this for us, in that the tree
# automatically excludes features that are least used. For GLM, the same can be achieved through hypothesis testing. 

# However when using a DT with numerous numerical data, many partitions can arise and each brings their own 
# interval. Making for a deep tree and could lead to over fitting

# GLMs may be a bit more difficult to understand, but interpreting their coefficients is straightforward.
# GLM is recommended. It is likely to make better predictions, allows for feature selection, and is easy to explain.

# Fitting the Best Model 
# Split the data into Train and Test
library(caret)
set.seed(1000)
train.indices <- createDataPartition(BI$BodilyInjury, p = 0.7, list = FALSE)
BI.train <- BI[train.indices, ]
BI.test <- BI[-train.indices, ]
test.indices <- createDataPartition(BI.test$BodilyInjury, p = 2 / 3, list = FALSE)
BI.hold <- BI.test[-test.indices, ]
BI.test <- BI.test[test.indices, ]
rm(train.indices)
rm(test.indices)

# Model 1- Normal Distribution, identity
# For this test BI is the target and all variables will be use except Age and LogBI 
glm1 <- glm(BodilyInjury ~ . -Age - LogBI, data = BI.train, family = gaussian(link = "identity"))
d <- drop1(glm1, test = "LRT")
d
d[which.max(d[, 5]), ]

# Remove CreditNum 
glm1 <- glm(BodilyInjury ~ . -Age - LogBI -CreditNum, data = BI.train, family = gaussian(link = "identity"))
d <- drop1(glm1, test = "LRT")
d
d[which.max(d[, 5]), ]

# Remove YearsOwned
glm1 <- glm(BodilyInjury ~ . -Age - LogBI -CreditNum -YearsOwned, data = BI.train, family = gaussian(link = "identity"))
d <- drop1(glm1, test = "LRT")
d
d[which.max(d[, 5]), ]
#All variables are significant. Use as Model 1 

predict.test <- predict(glm1, newdata = BI.test, type = "response")
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

ggplot() +
  geom_point(aes(x = glm1$fitted.values, y = residuals(glm1)))

plotData <- data.frame(residuals = residuals(glm1), fitted = glm1$fitted.values)

library(gridExtra)

p1 <- ggplot(data = plotData, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line()
p2 <- ggplot(data = plotData, aes(residuals, ..density..)) +
  geom_histogram()
grid.arrange(p1, p2, ncol = 2)
# The plots indicate an inappropriate choice of distribution and link. The RMSE is 13,382.64.

#Model 2- Normal Distribution, log 
glm2 <- glm(BodilyInjury ~ . - LogBI - Age, data = BI.train, family = gaussian(link = "log"))
d <- drop1(glm2, test = "LRT")
d
d[which.max(d[, 5]), ]

# CreditNum is again the first to be dropped.

glm2 <- glm(BodilyInjury ~ . - LogBI - Age - CreditNum, data = BI.train, family = gaussian(link = "log"))
d <- drop1(glm2, test = "LRT")
d
d[which.max(d[, 5]), ]

# And YearsOwned is the second to be dropped.

glm2 <- glm(BodilyInjury ~ . - LogBI - Age - CreditNum - YearsOwned, data = BI.train, family = gaussian(link = "log"))
d <- drop1(glm2, test = "LRT")
d
d[which.max(d[, 5]), ]
# All are significant 

predict.test <- predict(glm2, newdata = BI.test, type = "response")
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

ggplot() +
  geom_point(aes(x = glm2$fitted.values, y = residuals(glm2)))

plotData <- data.frame(residuals = residuals(glm2), fitted = glm2$fitted.values)

library(gridExtra)

p1 <- ggplot(data = plotData, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line()
p2 <- ggplot(data = plotData, aes(residuals, ..density..)) +
  geom_histogram()
grid.arrange(p1, p2, ncol = 2)
# An improvement but not enough

# Model 3- Inverse Gamma, log 
glm3 <- glm(BodilyInjury ~ . - LogBI - Age, data = BI.train, family = Gamma(link = "log"))
d <- drop1(glm3, test = "LRT")
d
d[which.max(d[, 5]), ]

# CreditNum is again the first to be dropped.

glm3 <- glm(BodilyInjury ~ . - LogBI - Age - CreditNum, data = BI.train, family = Gamma(link = "log"))
d <- drop1(glm3, test = "LRT")
d
d[which.max(d[, 5]), ]

# And YearsOwned is the second to be dropped.

glm3 <- glm(BodilyInjury ~ . - LogBI - Age - CreditNum - YearsOwned, data = BI.train, family = Gamma(link = "log"))
d <- drop1(glm3, test = "LRT")
d
d[which.max(d[, 5]), ]
#All significant 

predict.test <- predict(glm3, newdata = BI.test, type = "response")
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

ggplot() +
  geom_point(aes(x = glm3$fitted.values, y = residuals(glm3)))

plotData <- data.frame(residuals = residuals(glm3), fitted = glm3$fitted.values)

library(gridExtra)

p1 <- ggplot(data = plotData, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line()
p2 <- ggplot(data = plotData, aes(residuals, ..density..)) +
  geom_histogram()
grid.arrange(p1, p2, ncol = 2)

# Performance is about the same, but still some skewness. 
# Try the inverse Gaussian with log link. At this point it seems safe to work with the two dropped variables we have seen before.

# Model 3A- inverse Gaussian, log

glm3a <- glm(BodilyInjury ~ . - LogBI - Age - CreditNum - YearsOwned, data = BI.train, family = inverse.gaussian(link = "log"))
d <- drop1(glm3a, test = "LRT")
d
d[which.max(d[, 5]), ]

predict.test <- predict(glm3a, newdata = BI.test, type = "response")
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

ggplot() +
  geom_point(aes(x = glm3a$fitted.values, y = residuals(glm3a)))

plotData <- data.frame(residuals = residuals(glm3a), fitted = glm3a$fitted.values)

library(gridExtra)

p1 <- ggplot(data = plotData, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line()
p2 <- ggplot(data = plotData, aes(residuals, ..density..)) +
  geom_histogram()
grid.arrange(p1, p2, ncol = 2)

# Slightly over corrected, but is the best thus far. Try one more model.

#Model 4- Normal, identity, but predicting the log of the target
glm4 <- lm(LogBI ~ . - BodilyInjury - Age, data = BI.train)
d <- drop1(glm4, test = "Chisq") # Chisq is the same as LRT for an ordinary linear model
d
d[which.max(d[, 5]), ]

# Drop CreditNum

glm4 <- lm(LogBI ~ . - BodilyInjury - Age - CreditNum, data = BI.train)
d <- drop1(glm4, test = "Chisq")
d
d[which.max(d[, 5]), ]

# Drop YearsOwned

glm4 <- lm(LogBI ~ . - BodilyInjury - Age - CreditNum - YearsOwned, data = BI.train)
d <- drop1(glm4, test = "Chisq")
d
d[which.max(d[, 5]), ]
#All significant 

# Note: The predictions are now the logarithm of the target, so predicted values need to be exponentiated with the variance added. 

predict.test <- exp(predict(glm4, newdata = BI.test) + 0.5 * (summary(glm4)$sigma)^2)
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

ggplot() +
  geom_point(aes(x = glm4$fitted.values, y = residuals(glm4)))

plotData <- data.frame(residuals = residuals(glm4), fitted = glm4$fitted.values)

library(gridExtra)

p1 <- ggplot(data = plotData, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line()
p2 <- ggplot(data = plotData, aes(residuals, ..density..)) +
  geom_histogram()
grid.arrange(p1, p2, ncol = 2)

# The diagnostic results look good, but the RMSE against the test set is slightly worse. 
# Model 3A (inverse Gaussian and log link) is the winner.


#Determining the interaction term that improved model the most 
add1(glm3a, ~ .^2, test = "LRT")
## The most notable interaction is between Sex and AgeLow. If exists, it implies that for those under 27, the impact of an additional year of age varies between males and females. 

#This interaction is incorporated into the model, which is then evaluated.
glm3a.int <- glm(BodilyInjury ~ . - LogBI - Age - CreditNum - YearsOwned + Sex:AgeLow, data = BI.train, family = inverse.gaussian(link = "log"))
predict.test <- predict(glm3a.int, newdata = BI.test, type = "response")
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

ggplot() +
  geom_point(aes(x = glm3a.int$fitted.values, y = residuals(glm3a.int)))

plotData <- data.frame(residuals = residuals(glm3a.int), fitted = glm3a.int$fitted.values)

library(gridExtra)

p1 <- ggplot(data = plotData, aes(sample = residuals)) +
  geom_qq() +
  geom_qq_line()
p2 <- ggplot(data = plotData, aes(residuals, ..density..)) +
  geom_histogram()
grid.arrange(p1, p2, ncol = 2)
# There is some significance to some other interactions, but we'll stop here.

# The last step is to get a measure of error using the chosen model by applying it to the holdout set.
predict.hold <- predict(glm3a.int, newdata = BI.hold, type = "response")
sqrt(sum((predict.hold - BI.hold$BodilyInjury)^2) / nrow(BI.hold))

# This is roughly the same as previous values, indicating there has not been overfitting. 
# We will use this as our best model

# Creating a Decision Tree for Comparison 
library(rpart)
library(rpart.plot)
BI_Tree <- rpart(BodilyInjury ~ . - LogBI -AgeHigh - AgeLow, 
                 data = BI.train,
                 method = "anova", 
                 control = rpart.control(cp = 0, maxdepth = 10)
                 )
BI_Tree.pruned <- prune(BI_Tree, cp = BI_Tree$cptable[which.min(BI_Tree$cptable[, "xerror"]), "CP"])
rpart.plot(BI_Tree.pruned)

predict.test <- predict(BI_Tree.pruned, newdata = BI.test)
sqrt(sum((predict.test - BI.test$BodilyInjury)^2) / nrow(BI.test))

#Thoughts 
# The best GLM had an RMSE of 13,365 and included the features Year, Sex, MaritalStatus, Miles, CarAge, Drivers, AgeLow, and AgeHigh. 
# The best decision tree had an RMSE of 13,429 and used the features Age, CarAge, and Sex.
# Since the tree model did not outperform the GLM, there is no reason to revise my initial thoughts. 
# Though the use of fewer features in the tree could be seen as an advantage.

# Interpreting our model 
summary(glm3a.int)
# Use exponentiation due to the log link.
100 * (exp(glm3a.int$coefficients) - 1)

# Year: Each additional calendar year increases the expected cost by 5.32%.
# Marital Status: Compared to being divorced, being married reduces expected costs by 2.62%, being single increases them by 0.01%, and being widowed reduces them by 0.95%.
# Miles: Each additional thousand miles decreases the expected cost by 0.62%.
# Car Age: Each additional year of car age increases the expected cost by 2.24%.
# Drivers: Each additional driver increases the expected cost by 7.41%.
# Age: After age 27, expected costs increase by 0.24% per year.
# For the interaction terms, note that, all else being equal, for females the contribution (before exponentiating) is -0.08791*AgeLow, while for males it is 1.760 - (0.08791 + 0.05998)AgeLow = 1.760 - 0.14789AgeLow. 
# To interpret this: at age 17 (the lowest age in the data), males have 109.66% higher expected claims than females, but by age 27, this difference drops to 15.09%.

#Show our last point graphically 
AgeMeans <- BI |>
  filter(Age < 28) |> # We only want to look at young ages
  group_by(Age, Sex) |>
  summarise(mean = mean(BodilyInjury)) |>
  as.data.frame()
AgeMeans
ggplot(data = AgeMeans, aes(x = Age, y = mean, color = Sex)) +
  geom_point()





