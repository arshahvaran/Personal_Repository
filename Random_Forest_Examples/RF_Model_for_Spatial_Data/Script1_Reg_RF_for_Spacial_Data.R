library(readxl)
file_name <- "Script1_Input_Data.xlsx"
file_path <- file.path(getwd(), file_name)
data <- as.data.frame(read_xlsx(file_path))
str(data)
head(data)
names(data)
summary(data)

library(e1071)
skewness(data$OC)
kurtosis(data$OC)

library(psych)
describe(data)

hist(data$OC)
qqnorm(data$OC, pch = 20, col = "red")
qqline(data$OC, lty = 2, col = "blue", lwd = 2)

hist(log(data$OC))
qqnorm(log(data$OC), pch = 20, col = "red")
qqline(log(data$OC), lty = 2, col = "blue", lwd = 2)

library(nortest)
ad.test(data$OC)
shapiro.test(data$OC)
ad.test(log(data$OC))
shapiro.test(log(data$OC))

# Sowing the relationships between variables
library(GGally)
ggpairs(data = data[,1:10])

# Checking to see if there is missing data
library(MASS)
apply(data,2,function(x) sum(is.na(x)))

plot(data$x,data$y)
library(ggplot2)
ggplot(data = data, aes(x,y))+geom_point(color = I("tomato"))

# Split data to train and test
set.seed(234)
ind<-sample(2,nrow(data),replace = T, prob = c(0.8,0.2))
table(ind)
ind
train<-data[ind==1,]
test<-data[ind==2,]
dim(train);head(train)
dim(test);head(train)

# Plot how the train and test data are distributed
plot(data$x,data$y, type = "n", main = "Sistan RF Model")
points(train$x,train$y, col = "blue", add = T)
points(test$x,test$y, col = "red", pch = 20, add = T)
legend("bottomleft",
       legend = c("Train Data", "Test Data"),
       pch = c(1,18),
       col = c("blue", "red"))

# Convert data frame to sparse partial class
install.packages("sp", dependencies = T)
library(sp)
coords_tmp<-cbind(train$x,train$y)
View(coords_tmp)
colnames(coords_tmp)<-c("long","lat")
View(coords_tmp)

# Create spatial point data frame (for train data)
zone41_prj<-"+proj=utm +zone=41 +north +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

train_sp<-SpatialPointsDataFrame(coords = coords_tmp, 
                                 data = data.frame(train[-c(1,2)]),
                                 proj4string = CRS(zone41_prj))
class(train_sp)
head(train_sp@data)
train_sp@coords
train_sp@proj4string

plot(train_sp, col="red", pch = 20)

# Another way to create spatial point data frame (for test data)
install.packages("raster", dependencies = T)
library("raster")
test_sp<-as.data.frame(test)
coordinates(test_sp)<- ~x+y
class(test_sp)
head(test_sp@data)
test_sp@coords
crs(test_sp)<- zone41_prj
test_sp@proj4string

install.packages("tmap", dependencies = T)
library(tmap)
tm_shape(train_sp)+
  tm_dots(col = "darkred", size = 0.1, shape = 1, alpha =1)+
  tm_shape(test_sp)+tm_dots(col = "blue", size = 0.3, shape = 20)+
  tm_layout(title = "Sampling Points", frame = F, title.position = c("left","top"), title.size = 0.8)+
  tm_add_legend(type = "symbol", col = c("darkred","blue"), shape = c(1,20), labels = c("Train","Test"))
  

# Create RF Model for Regression
library(randomForest)
RF_OC<-randomForest(OC~p1+p2+p3+p4+p5+p6+p7,
                    data = train_sp,
                    proximity = T,
                    importance = T,
                    ntree = 1000)
RF_OC
RF_OC$mtry
RF_OC$ntree
plot(RF_OC)
attributes(RF_OC)
importance(RF_OC)
varImpPlot(RF_OC)

library(caret)
VI_RF_OC<- varImp(RF_OC)
VI_RF_OC
colnames(VI_RF_OC)<-"RF_Model_importance"
VI_RF_OC<-t(VI_RF_OC)
VI_RF_OC

# Determine the optimal mtry
tune_RF<-tuneRF(train_sp@data[,-8],train_sp@data[,8],stepFactor = 2)
print(tune_RF)

# Determine the optimal ntree
store_maxtrees<- list()
for(ntree in c(500,600,700,800,900,1000,1200,1400,1600,1800,2000)) {
  set.seed(567)
  RF_maxtrees<-train(OC~p1+p2+p3+p4+p5+p6+p7,
                     data = train_sp@data,
                     method = "rf",
                     importance = T,
                     nodesize = 14,
                     maxnodes = 24,
                     ntree = ntree)
  key<-toString(ntree)
  store_maxtrees[[key]]<- RF_maxtrees
}

results_tree<- resample(store_maxtrees)
summary(results_tree)

# Create a new model based on the best mtry and ntree
RF_OC2<-randomForest(OC~p1+p2+p3+p4+p5+p6+p7,
                    data = train_sp,
                    proximity = T,
                    importance = T,
                    ntree = 1000,
                    mtry = 4)
RF_OC2
RF_OC2$mtry
RF_OC2$ntree
plot(RF_OC2)
attributes(RF_OC2)
importance(RF_OC2)
varImpPlot(RF_OC2)

library(caret)
VI_RF_OC2<- varImp(RF_OC2)
VI_RF_OC2
colnames(VI_RF_OC2)<-"RF_Model_importance"
VI_RF_OC2<-t(VI_RF_OC2)
VI_RF_OC2

# Evaluate the accuracy of the model
RF_Pred_Train<-predict(RF_OC2,train_sp@data)
RF_Pred_Test<-predict(RF_OC2,test_sp@data)

library(caret)
postResample(RF_Pred_Train, train$OC)
postResample(RF_Pred_Test, test$OC)

# Make raster file for one variable of data frame
xyzp1<- cbind(data$x,data$y,data$p1)
p1raster<-rasterFromXYZ(xyz = xyzp1, crs = zone41_prj)
plot(p1raster)
res(p1raster)

# Make raster file for every variable of data frame
make_raster<-function(a) {result<-cbind(data$x,data$y,a)
map<-rasterFromXYZ(xyz = result, crs = zone41_prj)
print(map)
plot(map)
return(map)}

p2raster<-make_raster(data$p2)
p3raster<-make_raster(data$p3)
p4raster<-make_raster(data$p4)
p5raster<-make_raster(data$p5)
p6raster<-make_raster(data$p6)
p7raster<-make_raster(data$p7)

par_stack<-stack(p1raster,p2raster,p3raster,p4raster,p5raster,p6raster,
                 p7raster)
names(par_stack)
names(par_stack)<-c("p1", "p2","p3","p4","p5","p6","p7")

map_RF_OC<-predict(par_stack, 
                   RF_OC2, 
                   "OC stock.RF.tif",
                   format = "GTiff",
                   datatype = "FLT4S",
                   overwrite = T)
plot(map_RF_OC, main = "OC Sistan Based on RF Model")

install.packages("RColorBrewer", dependencies = T)
library(RColorBrewer)
display.brewer.all()
library(tmap)
tm_shape(map_RF_OC)+
  tm_raster(palette  = "YlOrRd", title = "OC Sistan Based on RF Model")+
  tm_layout(frame = F)

install.packages("plotKML", dependencies = T)
library(plotKML)
plotKML(map_RF_OC)





