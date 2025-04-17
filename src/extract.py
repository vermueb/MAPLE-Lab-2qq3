# extract.py
from os import makedirs
from os.path import join, basename
from glob import glob
from csv import writer
import json
import librosa

def librosa_chroma(file_path):
    y, sr = librosa.load(file_path)  # You can set sample rate explicitly if needed
    # Compute Constant-Q chroma features
    chroma_cqt = librosa.feature.chroma_cqt(y=y, sr=sr)
    return chroma_cqt

# Define folder paths
audio_folder = 'audio_files'
output_folder = 'data'
makedirs(output_folder, exist_ok=True)

# CSV file path
output_csv = join(output_folder, 'df_raw.csv')

# Find all audio files in the audio_files folder
audio_files = glob(join(audio_folder, '*'))

# Open the CSV file for writing
with open(output_csv, 'w', newline='') as csvfile:
    csv_writer = writer(csvfile)
    # Write header: each row will have the filename, feature type, and the serialized feature matrix.
    csv_writer.writerow(['filename', 'feature', 'val'])
    
    # Loop over each audio file
    for audio_file in audio_files:
        try:
            chroma_values = librosa_chroma(audio_file)
            # Serialize the 2D array as a JSON string
            chroma_json = json.dumps(chroma_values.tolist())
            # Write one row per file
            csv_writer.writerow([basename(audio_file), 'chroma_cqt', chroma_json])
        except Exception as e:
            print(f"Error processing {audio_file}: {e}")
            continue
