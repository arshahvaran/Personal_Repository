#conda create --name videotrimming
#conda activate videotrimming
#pip insatll pandas
#pip install moviepy
#cd "C:\Users\PHYS3009\Desktop\Video_Trimming_v1"
#python Video_Trimming_v1.py

import os
import pandas as pd
from moviepy.editor import VideoFileClip

# Define the path to the Excel file and the output directory
excel_file_path = "C:/Users/PHYS3009/Desktop/Video_Trimming_v1/Video_Trimming_v1.xlsx"
output_dir = "C:/Users/PHYS3009/Desktop/Video_Trimming_v1/Output"

# Check if the output directory exists, if not, create it
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Read the Excel file
try:
    df = pd.read_excel(excel_file_path)
except Exception as e:
    print(f"Failed to read the Excel file: {e}")
    # Exit if the file cannot be read
    exit()

# Iterate over the rows of the DataFrame
for index, row in df.iterrows():
    input_file_path = row['Input_File_Path']
    start_time = row['Start_Time']
    end_time = row['End_Time']
    output_name = row['Output_Name'] + '.mp4'  # Ensure the output is in MP4 format

    # Check if the input file exists
    if not os.path.isfile(input_file_path):
        print(f"Input file not found: {input_file_path}")
        continue

    # Try to convert the start and end times to seconds
    try:
        start_time_seconds = sum(x * int(t) for x, t in zip([3600, 60, 1], str(start_time).split(':')))
        end_time_seconds = sum(x * int(t) for x, t in zip([3600, 60, 1], str(end_time).split(':')))
    except ValueError as e:
        print(f"Invalid time format for file {input_file_path}: {e}")
        continue

    # Define the output file path
    output_file_path = os.path.join(output_dir, output_name)

    # Trim the video
    try:
        with VideoFileClip(input_file_path) as video:
            trimmed_video = video.subclip(start_time_seconds, end_time_seconds)
            # Save the trimmed video in MP4 format without specifying bitrate
            trimmed_video.write_videofile(output_file_path, codec='libx264', audio_codec='aac')
    except Exception as e:
        print(f"Failed to trim the video {input_file_path}: {e}")

print("Video trimming is complete.")
