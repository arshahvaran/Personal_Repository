
# Installing a new package
install.packages("randomForest", dependencies = T)

# Loading RF library
library(randomForest)

# Loading dataset
data("iris")

# About the dataset
force(iris)
str(iris)
head(iris)
dim(iris)

# Display descriptive statistics of the dataset
summary(iris)
# Display descriptive statistics of a column of a dataset
summary(iris$Sepal.Length)
table(iris$Species)

# For calculating skewness and kurtosis
install.packages("e1071", dependencies = T)
library("e1071")
skewness(iris$Sepal.Length)
kurtosis(iris$Sepal.Length)

# More detailed descriptive statistics report
install.packages("psych", dependencies = T)
library("psych")
describe(iris)
# Saving as a data frame
describeIris<- describe(iris)
View(describeIris)

# Other functions of "psych"
describeBy(iris$Sepal.Length, group = iris$Species, digits = 4)
headTail(iris)

# For showing the relationships between variables
install.packages("GGally", dependencies = T)
library("GGally")
ggpairs(iris[,1:5])
par(
  mfrow=c(1,1),
  mar=c(3,3,3,3))
plot(iris$Sepal.Length,
     iris$Sepal.Width,
     col  =iris$Species,
     pch = 16,
     xlab = "Sepal Length",
     ylab = "Sepal Width")
legend(x="topleft",
       legend = levels(as.factor(iris$Species)),
       col = c("black","red","green"),
       pch = c(16),
       bty = "n",
       cex = 0.8)

# Split iris data to training and testing sets
set.seed(123)
ind<-sample(2,nrow(iris),replace = T, prob = c(0.7,0.3))
table(ind)
ind
traindata<-iris[ind==1,]
testdata<-iris[ind==2,]
dim(traindata);head(traindata)
dim(testdata);head(testdata)

# Generate RF model for classification
names(iris)
iris_rf<-randomForest(Species~.,
                      data = traindata,
                      proximity = T,
                      importance = T)
iris_rf
print(iris_rf)
plot(iris_rf)
attributes(iris_rf)
iris_rf$ntree
iris_rf$mtry
iris_rf$confusion
iris_rf$importance
importance(iris_rf)
varImpPlot(iris_rf)
varImpPlot(iris_rf,sort = T, n.var = 2, main = "Top-2 Variables")

# Building RF model for testing data
iris_pred<-predict(iris_rf, newdata = testdata)
table(iris_pred,testdata$Species)
plot(margin(iris_rf,testdata$Species))

# Add prediction values to data
testdata2<-testdata
testdata2$irispred<-iris_pred
str(testdata2)

# Checking the classification accuracy model
print(sum(iris_pred==testdata$Species))
print(length(testdata$Species))
print((sum(iris_pred==testdata$Species))/(length(testdata$Species)))

install.packages("ModelMetrics", dependencies = T)
library("ModelMetrics")
ce(testdata$Species, iris_pred)

install.packages("caret", dependencies = T)
library("caret")
confusionMatrix(iris_pred,testdata$Species)
postResample(pred = iris_pred,obs = testdata$Species)

# Cross validation on train data
cv_iris_rf<-rfcv(trainx = traindata[,-5],trainy = traindata[,5],cv.fold = 10)
pred_cv<-cv_iris_rf[["predicted"]][["2"]]
confusionMatrix(pred_cv,traindata$Species)

pred_all<-predict(iris_rf,iris)
confusionMatrix(pred_all,iris$Species)

# Determine the optimal mtry
tune_RF<-tuneRF(iris[,-5],iris[,5],stepFactor = 0.5)
print(tune_RF)

# Make a new model with the best mtry
iris_rf2<-randomForest(Species~.,
                       data = traindata,
                       proximity = T,
                       importance = T,
                       mtry = 4,
                       ntree = 1000,
                       nodesize = 2,
                       nsplit = 3)
iris_rf2
plot(iris_rf2)
# Assessing accuracy this time using jackknife
iris_pred2<-predict(iris_rf2,testdata)
confusionMatrix(iris_pred2,testdata$Species)

# Partial dependence plot
partialPlot(iris_rf,traindata,Petal.Length,"versicolor")
partialPlot(iris_rf,traindata,Petal.Length,"virginica", add = T, col = "blue")
partialPlot(iris_rf,traindata,Petal.Length,"setosa", add = T, col = "red")

# Export data to csv and Excel file
getwd()
write.csv(testdata2,file = "testdata_iris.csv")
install.packages("openxlsx", dependencies = T)
library("openxlsx")
write.xlsx(testdata2, "testdata_iris.xlsx")

