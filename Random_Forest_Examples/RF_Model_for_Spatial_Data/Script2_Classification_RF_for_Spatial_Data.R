library(readxl)
file_name <- "Script2_Input_Data.xlsx"
file_path <- file.path(getwd(), file_name)
pts <- as.data.frame(read_xlsx(file_path))
str(pts)
names(pts)
names(pts)<-c("long","lat","class")
names(pts)
table(pts$class)

# A simple plot using class descriptions
library(ggplot2)
qplot(long, lat, data = pts, col = class)

r_name<-list.files("Script2_Input_Data2", full.names = F, pattern = "tif$")
r_name

library(raster)
Analyti_hi<-raster("Script2_Input_Data2/Analyti_hi.tif")
Analyti_hi
elevation<-raster("Script2_Input_Data2/z.tif")
elevation
plot(elevation, col = gray.colors(256))
Cha_Ne_bl<-raster("Script2_Input_Data2/Cha_Ne_bl.tif")
Curvatu_de<-raster("Script2_Input_Data2/Curvatu_de.tif")
Valley_Dep<-raster("Script2_Input_Data2/Valley_Dep.tif")
tpi<-raster("Script2_Input_Data2/tpi.tif")
HillSha_de<-raster("Script2_Input_Data2/HillSha_de.tif")
Slope_degr<-raster("Script2_Input_Data2/Slope_degr.tif")
twi_gis<-raster("Script2_Input_Data2/twi_gis.tif")
LS_Factor<-raster("Script2_Input_Data2/LS_Factor.tif")
plan_cur<-raster("Script2_Input_Data2/plan_cur.tif")
FlowDir_de<-raster("Script2_Input_Data2/FlowDir_de.tif")
Chal_Ne_di<-raster("Script2_Input_Data2/Chal_Ne_di.tif")
Conver_in<-raster("Script2_Input_Data2/Conver_in.tif")
beerAspect<-raster("Script2_Input_Data2/beerAspect.tif")
prof_curv<-raster("Script2_Input_Data2/prof_curv.tif")
LF_in<-raster("Script2_Input_Data2/LF_in.tif")

# To see if both files have same extent
#compareRaster(Analyti_hi, elevation)

zone41_prj<-"+proj=utm +zone=41 +north +ellps=WGS84 +datum=WGS84 +units=m +no_defs"

crs(elevation)<-zone41_prj

Analyti_hi<-resample(Analyti_hi,elevation)
Cha_Ne_bl<-resample(Cha_Ne_bl,elevation)
Curvatu_de<-resample(Curvatu_de,elevation)
Valley_Dep<-resample(Valley_Dep,elevation)
tpi<-resample(tpi,elevation)
HillSha_de<-resample(HillSha_de,elevation)
Slope_degr<-resample(Slope_degr,elevation)
twi_gis<-resample(twi_gis,elevation)
LS_Factor<-resample(LS_Factor,elevation)
plan_cur<-resample(plan_cur,elevation)
FlowDir_de<-resample(FlowDir_de,elevation)
Chal_Ne_di<-resample(Chal_Ne_di,elevation)
Conver_in<-resample(Conver_in,elevation)
beerAspect<-resample(beerAspect,elevation)
prof_curv<-resample(prof_curv,elevation)
LF_in<-resample(LF_in,elevation)

# Stack all layers
covStack<-stack(elevation, Cha_Ne_bl, Chal_Ne_di, Conver_in, LS_Factor, 
                Valley_Dep, Analyti_hi, HillSha_de, Slope_degr, 
                beerAspect, tpi, twi_gis, FlowDir_de, plan_cur, 
                prof_curv, Curvatu_de)
covStack[[1]]
plot(covStack[[1]], main = names(covStack[[1]]))

# Extract values of raster by point
rastopoint<-data.frame(extract(covStack,pts[c(1,2)]))
View(rastopoint)

text.soil<-cbind(rastopoint, pts[3])
str(text.soil)
names(text.soil)

# Checking for missing values
apply(text.soil,2,function(x) sum(is.na(x)))

# Removing missing values
text.soil<-na.omit(text.soil)
apply(text.soil,2,function(x) sum(is.na(x)))

# Display descriptive statistics of data
summary(text.soil)
text.soil$class<-as.factor(text.soil$class)
head(text.soil)
library(psych)
des.data<-describe(text.soil)
ind_normality<-des.data$skew< -1 | des.data$skew> 1
ind_normality
summary(ind_normality)
rownames(des.data[ind_normality,])
des.data[ind_normality,]
hist(text.soil$Cha_Ne_bl)
multi.hist(subset(text.soil, select = -class))
library(GGally)
ggpairs(text.soil[,1:7])
ggpairs(text.soil[,c(1,2,3,4,5,6,17)])
qplot(Analyti_hi,z,data = text.soil, color = class)
qplot(Valley_Dep, z, data = text.soil, color = class)

# Split data to train and test
set.seed(345)
ind<-sample(2,nrow(text.soil),replace = T, prob = c(0.8,0.2))
table(ind)
ind
train<-text.soil[ind==1,]
test<-text.soil[ind==2,]
dim(train);head(train)
dim(test);head(train)

table(train$class)
table(test$class)

# Create RF Model for Classification of Soil Texture
library(randomForest)
RF_text_soil<-randomForest(class~.,
                    data = train,
                    proximity = T,
                    importance = T,
                    ntree = 350,
                    do.trace = 50)
RF_text_soil
RF_text_soil$mtry
RF_text_soil$ntree
plot(RF_text_soil)
par(mfrow=c(1,1),mar=c(3,3,3,3))
attributes(RF_text_soil)
importance(RF_text_soil)
varImpPlot(RF_text_soil)
varImpPlot(RF_text_soil, sort = T, n.var = 10, main = "RF Model Importance")

# Determine the optimal mtry
tune_RF<-tuneRF(train[,-17],train[,17],stepFactor = 0.5)
print(tune_RF)

# Make a new model with the best mtry
RF_text_soil2<-randomForest(class~.,
                           data = train,
                           proximity = T,
                           importance = T,
                           ntree = 100,
                           mtry = 8,
                           do.trace = 50)
RF_text_soil2
RF_text_soil2$mtry
RF_text_soil2$ntree
plot(RF_text_soil2)
par(mfrow=c(1,1),mar=c(3,3,3,3))
attributes(RF_text_soil2)
importance(RF_text_soil2)
varImpPlot(RF_text_soil2)


# Evaluate the accuracy of the two models
RF_Pred_Test<-predict(RF_text_soil,test)
RF_Pred_Test2<-predict(RF_text_soil2,test)
library(caret)
confusionMatrix(RF_Pred_Test,test$class)
confusionMatrix(RF_Pred_Test2,test$class)

# Make map
library(raster)
tempdf<-data.frame(cellnos=seq(1:ncell(covStack)))
vals<-as.data.frame(getValues(covStack))
tempdf<-cbind(tempdf,vals)
tempdf<-tempdf[complete.cases(tempdf),]
str(tempdf)
cellnos<-c(tempdf$cellnos)
gxy<-data.frame(xyFromCell(covStack,cellnos,spatial = F))
tempdf<-cbind(gxy,tempdf)

# Predict new values with RF model
data_noxy<-tempdf[,c(-1,-2,-3)]
str(data_noxy)
RF_Pred<-predict(RF_text_soil2,data_noxy)

map.RF.TS<-cbind(tempdf[,c(1,2)])
map.RF.TS$RF_Pred<-RF_Pred
str(map.RF.TS)

library(ggplot2)
ggplot(data = map.RF.TS, aes(y=y,x=x,fill=RF_Pred))+geom_tile()

library(raster)
coordinates(map.RF.TS)<- ~x+y
gridded(map.RF.TS)<- T
library(RColorBrewer)
display.brewer.all()
area_colors<-brewer.pal(3,"Set1")
spplot(map.RF.TS,
       col.regions = area_colors,
       main = "Soil Texture of Gorgan",
       key.space = "right",
       scales = list(draw=T))


plot(map.RF.TS,
     col = area_colors,
     main = "Soil Texture of Gorgan")

library(tmap)
mypalette<-c("green", "purple", "wheat")
zone40_prj<-"+proj=utm +zone=40 +north +ellps=WGS84 +datum=WGS84 +units=m +no_defs"
proj4string(map.RF.TS)<-zone40_prj
tm_shape(map.RF.TS)+
  tm_raster(palette = mypalette, title = "Soil Texture of Gorgan")+
  tm_layout(frame = F, legend.outside = T)

library(plotKML)
plotKML(map.RF.TS)
  






















