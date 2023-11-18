import os
import rasterio
import pandas as pd
from rasterio.warp import transform

# Function to parse metadata file and extract TOA reflectance coefficients
def parse_metadata(metadata_path):
    coefficients = {}
    try:
        with open(metadata_path) as f:
            metadata_lines = f.readlines()
        
        # Process each line
        for line in metadata_lines:
            if 'REFLECTANCE_MULT_BAND_' in line or 'REFLECTANCE_ADD_BAND_' in line:
                key, value = line.strip().split(' = ')
                coefficients[key] = float(value)
    except FileNotFoundError:
        print(f"Metadata file not found: {metadata_path}")
    except Exception as e:
        print(f"Error parsing metadata: {e}")
    
    return coefficients

# Function to calculate TOA Reflectance
def dn_to_toa(reflectance_mult, reflectance_add, dn):
    return reflectance_mult * dn + reflectance_add

# Read the Excel file with the points and image names
excel_path = "C:/Users/PHYS3009/Desktop/TOA_Pixel_Extraction/Matchup_Data_v1.xlsx"
df_points = pd.read_excel(excel_path)

# Base directory for Landsat images
base_dir = "E:/Thesis/Chapter_3/RS_Data/Level_1"

# Initialize an empty DataFrame to store the output
output_data = []

for index, row in df_points.iterrows():
    image_folder = row['Image']
    lat, lon = row['Latitude_DD'], row['Longitude_DD']
    year = image_folder.split('_')[3][:4]  # Extract year from the image folder name

    # Construct the folder path for the Landsat image
    folder_path = os.path.join(base_dir, year, image_folder)

    # Read metadata and extract coefficients
    metadata_path = os.path.join(folder_path, image_folder + '_MTL.txt')
    coefficients = parse_metadata(metadata_path)

    # Create a dictionary to hold TOA reflectance values for the bands
    toa_reflectance = {}

    # Process only bands 1 through 5
    for band in range(1, 6):
        band_file = f"{folder_path}/{image_folder}_B{band}.TIF"
        with rasterio.open(band_file) as src:
            # Convert the coordinates to the image's CRS
            easting, northing = transform('EPSG:4326', src.crs, [lon], [lat])
            
            # Get the row and column of the point in the image
            col, row = src.index(easting[0], northing[0])
            
            # Check if the row and column are within the valid bounds of the image
            if 0 <= row < src.height and 0 <= col < src.width:
                # Read the DN value at the point
                dn = src.read(1)[row, col]
                
                # Calculate TOA reflectance
                mult_key = f'REFLECTANCE_MULT_BAND_{band}'
                add_key = f'REFLECTANCE_ADD_BAND_{band}'
                if mult_key in coefficients and add_key in coefficients:
                    toa_reflectance[f"rhotoa_B{band}"] = dn_to_toa(coefficients[mult_key], coefficients[add_key], dn)
                else:
                    print(f"Metadata does not contain necessary keys for band {band}")
                    toa_reflectance[f"rhotoa_B{band}"] = None  # Handle missing data
            else:
                print(f"Coordinate is out of bounds for image {image_folder}")
    
    # Append the results to the output list
    output_data.append({
        "Latitude_DD": lat,
        "Longitude_DD": lon,
        "Image": image_folder,
        **toa_reflectance
    })

# Create a DataFrame from the output list
df_output = pd.DataFrame(output_data)

# Define the output Excel file path
output_excel_path = "C:/Users/PHYS3009/Desktop/TOA_Pixel_Extraction/TOA_Pixel_Extraction.xlsx"

# Write the DataFrame to an Excel file
df_output.to_excel(output_excel_path, index=False)

print(f"Output Excel file created at {output_excel_path}")
