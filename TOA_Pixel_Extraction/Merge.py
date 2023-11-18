import pandas as pd

# Define the file paths
file1_path = r'C:\Users\PHYS3009\Desktop\TOA_Pixel_Extraction\TOA_Pixel_Extraction_v2.xlsx'
file2_path = r'C:\Users\PHYS3009\Desktop\TOA_Pixel_Extraction\Matchup_Data_v2.xlsx'
output_path = r'C:\Users\PHYS3009\Desktop\TOA_Pixel_Extraction\Merged.xlsx'

# Load the data from both files into pandas DataFrames
df1 = pd.read_excel(file1_path)
df2 = pd.read_excel(file2_path)

# Merge the DataFrames based on the specified columns
merged_df = pd.merge(df1, df2, on=['Latitude_DD', 'Longitude_DD', 'Image'], how='inner')

# Save the merged data to a new Excel file
merged_df.to_excel(output_path, index=False)

print(f'Merged data saved to {output_path}')
