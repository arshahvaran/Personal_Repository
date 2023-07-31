# import libraries
import os
import rasterio as rio
import geopandas as gpd
import matplotlib.pyplot as plt
import rioxarray as rxr
from shapely.geometry import Point, point
from rasterio.plot import show
import csv

# Output directory
out_dir = r"C:\Users\ReSEC2021\Downloads"

# Read points from shapefile/CSv
#If CSV you need to generate geometry using geopandas and make sure it works(a geometry column needs to be created)
bathy = gpd.read_file(r"C:\Users\ReSEC2021\Downloads\bathymetry.shp")

# print dateframe to check data
print(bathy)

# check projection
print(bathy.crs)

# set data folder
data = r"C:\Users\ReSEC2021\Downloads\LC08_L1GT_047016_20191116_20191202_01_T2_Handle_Lake.tif"

# Open raster data
temp = rio.open(data)

#Check projection
print(temp.crs)

## plot both data togther 
# fig, ax = plt.subplots(figsize=(12,12))
# bathy.plot(ax=ax, color='red')
# show(temp, ax=ax)
# plt.show()

# create empty list to store temperature extract  
Tem = []

#extract point value from raster
for point in bathy['geometry']:
    # Select first and second element of the geometries as x and y. They are the projected x and y cordinates
    x = point.xy[0][0]
    y = point.xy[1][0]

    # Use x and y to find the row and column index of the array for the raster data
    row, col = temp.index(x,y)

    # print extracted temperature output based on index
    print(temp.read(1)[row,col])

    # append the output to empty list created
    Tem.append(temp.read(1)[row,col])

# Generate a column based on extract output to the existing bathymetry file
bathy["Temp"] = Tem

# Save to CSV
bathy.to_csv(os.path.join(out_dir,"Bathy_with_temp.csv"),index=False,mode='w')

