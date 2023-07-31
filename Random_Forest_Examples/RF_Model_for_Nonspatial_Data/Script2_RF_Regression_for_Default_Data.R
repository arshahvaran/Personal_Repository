R.version.string
install.packages("readxl", dependencies = T)
library("readxl")
file_name <- "Script2_Input_Data.xlsx"
file_path <- file.path(getwd(), file_name)
data <- as.data.frame(read_xlsx(file_path))
str(data)
head(data)
names(data)
names(data)<-c("size","thickness","time","R","PB")
names(data)

# Print attributes
summary(data)
summary(data$PB)
install.packages("e1071", dependencies = T)
library("e1071")
skewness(data$PB)
kurtosis(data$PB)
install.packages("psych", dependencies = T)
library("psych")
describe(data)
# Checking normality 
hist(data$PB)
qqnorm(data$PB, pch = 20, col = "red")
qqline(data$PB, lty = 2, col = "blue", lwd = 2)

# Log transformation
data2 <- subset(data, PB != 0 & !is.na(PB))
log_data2 <- data2
log_data2$PB <- log(data2$PB)
install.packages("nortest", dependencies = T)
library("nortest")
ad.test(data2$PB)
shapiro.test(data2$PB)
ad.test(log_data2$PB)
shapiro.test(log_data2$PB)

# Showing the relationships between variables
install.packages("GGally", dependencies = T)
library("GGally")
ggpairs(data = data[,1:5])

# Checking to see if there is missing data
install.packages("MASS", dependencies = T)
library("MASS")
apply(data,2,function(x) sum(is.na(x)))

# Split iris data to training and testing sets
set.seed(500)
ind<-sample(2,nrow(data),replace = T, prob = c(0.75,0.25))
table(ind)
ind
train<-data[ind==1,]
test<-data[ind==2,]
dim(train);head(train)
dim(test);head(test)

########## LINEAR REGRESSION MODELING

# Modeling
lm_fit_PB<-lm(PB~.,data = train)
lm_fit_PB
summary(lm_fit_PB)
head(residuals(lm_fit_PB))
names(summary(lm_fit_PB))
summary(lm_fit_PB)[["r.squared"]]
summary(lm_fit_PB)[["coefficients"]]
summary(lm_fit_PB)[["adj.r.squared"]]
Coef_Reg<-data.frame(coef(lm_fit_PB))
install.packages("caret", dependencies = T)
library("caret")
VI_LM<-varImp(lm_fit_PB)
colnames(VI_LM)<-"RegModelImportantce"
VI_LM

# Evaluating the accuracy of the model
Pred_LM_Train<-predict(lm_fit_PB,train)
head(Pred_LM_Train)

# Calculate ME, MSE and RMSE
bias_LM_CV<-mean(train$PB-Pred_LM_Train)
bias_LM_CV
MSE_Train<-mean((train$PB-Pred_LM_Train)^2)
MSE_Train
RMSE_Train<-sqrt(MSE_Train)
RMSE_Train

install.packages("ModelMetrics", dependencies = T)
library("ModelMetrics")
mae(actual = train$PB, predicted = Pred_LM_Train)
mse(actual = train$PB, predicted = Pred_LM_Train)
rmse(actual = train$PB, predicted = Pred_LM_Train)


library("caret")
postResample(pred = Pred_LM_Train, obs = train$PB)

# Now for the test data set
Pred_LM_Test<-predict(lm_fit_PB, newdata = test)
postResample(pred = Pred_LM_Test, obs = test$PB)
bias_LM_CV<-mean(test$PB-Pred_LM_Test)
bias_LM_CV
mse(actual = test$PB, predicted = Pred_LM_Test)

# Now for all the data set
Pred_LM_ALL<-predict(lm_fit_PB, newdata = data)
postResample(pred = Pred_LM_ALL, obs = data$PB)
 bias_LM_CV<-mean(data$PB-Pred_LM_ALL)
bias_LM_CV
mse(actual = data$PB, predicted = Pred_LM_ALL)

# Add prediction values to data
test2<-test
test2$Pred_LM<-Pred_LM_Test
str(test2)

########## RF REGRESSION MODELING

library(randomForest)
RF_PB<-randomForest(PB~., 
             data = train, 
             proximity = T, 
             importance = T,
             do.trace = T)
RF_PB
plot(RF_PB)

importance(RF_PB)
varImpPlot(RF_PB)

# Determine the optimal mtry
data<-as.data.frame(data)
tune_RF<-tuneRF(data[,-5],
                data[,5],
                stepFactor = 0.75)
print(tune_RF)

# Make a new model with the best mtry
RF_PB2<-randomForest(PB~., 
                    data = train, 
                    proximity = T, 
                    importance = T,
                    do.trace = 100,
                    mtry = 3)
RF_PB2
plot(RF_PB2)

importance(RF_PB2)
varImpPlot(RF_PB2)

VI_RF<-varImp(RF_PB2)
VI_RF
colnames(VI_RF)<-"RF_Model_Importance"
VI_RF

# Evaluating the accuracy of the model
Pred_RF1<-predict(RF_PB,test)
Pred_RF2<-predict(RF_PB2,test)

bias1<-mean(test$PB-Pred_RF1)
bias1
bias2<-mean(test$PB-Pred_RF2)
bias2

mse(actual = test$PB, predicted = Pred_RF1)
mse(actual = test$PB, predicted = Pred_RF2)

postResample(test$PB, Pred_RF1)
postResample(test$PB, Pred_RF2)

# Plotting the performance of both models
test2$Pred_RF2<-Pred_RF2
plot(test$PB,test2$Pred_RF2,
     col = "red",
     main = "Real vs Predicted",
     pch = 18,
     cex = 1,
     xlab = "Real",
     ylab = "Predicted")
points(test$PB,
       test2$Pred_LM,
       col = "blue",
       pch = 15,
       cex = 1)
abline(0,1, lwd = 2)
legend("bottomright",
       legend = c("RF","LM"),
       pch = c(18,15),
       col = c("red","blue"))

# Saving data
VI_LM<-t(VI_LM)
VI_RF<-t(VI_RF)
VI_Both<-rbind(VI_LM,VI_RF)
VI_Both

install.packages("writexl")
library("writexl")
VI_Both<-as.data.frame(VI_Both)
write_xlsx(VI_Both, path = "VI_Both.xlsx")


