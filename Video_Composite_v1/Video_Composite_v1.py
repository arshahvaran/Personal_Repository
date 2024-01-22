#conda activate videotrimming
#cd "C:\Users\alire\OneDrive\Desktop\Video_Composite_v1"
#install ImageMagick from https://imagemagick.org/script/download.php to C:\Program Files\ImageMagick-7.1.1-Q16-HDRI
#python Video_Composite_v1.py


from moviepy.config import change_settings
change_settings({"IMAGEMAGICK_BINARY": r"C:\Program Files\ImageMagick-7.1.1-Q16-HDRI\magick.exe"})

from moviepy.editor import VideoFileClip, concatenate_videoclips, TextClip, CompositeVideoClip
import os

# Directory containing the videos
directory = "I:\\Better Call Saul (2015–2022) & Breaking Bad (2008–2013) - All Don Eladio's Scenes [In Chronological Order]"


# List and sort the video files
video_files = sorted([file for file in os.listdir(directory) if file.endswith(".mp4")])

# Prepare a list for the final clips
final_clips = []

# Duration of the text clip
text_clip_duration = 3

for file in video_files:
    # Full path of the video file
    filepath = os.path.join(directory, file)

    # Load the video file
    video_clip = VideoFileClip(filepath)

    # Create a text clip with the file name, minus the last 8 characters
    #text_for_clip = file[:-8]  # Removes the last 8 characters
    text_for_clip = file[:-4]  # Removes the last 4 characters
    text_clip = TextClip(text_for_clip, fontsize=70, color='white', bg_color='black', size=video_clip.size).set_duration(text_clip_duration)

    # Concatenate text clip with video
    final_clips.append(CompositeVideoClip([text_clip]))
    final_clips.append(video_clip)


# Concatenate all the clips
final_video = concatenate_videoclips(final_clips, method="compose")

# Extract the folder name from the directory path
folder_name = os.path.basename(directory)

# Construct the output file path using the folder name
output_file = os.path.join(directory, f"{folder_name}.mp4")

# Write the result to the file
final_video.write_videofile(output_file, codec="libx264", fps=24)
