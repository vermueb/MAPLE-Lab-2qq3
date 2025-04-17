
# manipulate.py
# Import functions.
from os import makedirs, remove
from os.path import exists
from subprocess import run
from pathlib import Path
from emotionally_managing.gdrive import download_file, get_filenames

# Make sure we have a folder to output audio files.
output_folder = "audio_files"
if not exists(output_folder):
    makedirs(output_folder)
    
# Establish manipulation levels.
semitones = range(-12, 13)
soundfonts = ["1qiYEpF0tjAdxDKrZ0zz6VuN0sor1X7ia",
  "1NRb8BJyTjbe35I3QLgHFdZNnzToNSBxE",
  "1KGmtIIADtlg5gzAJQq9Yt7hBPP0VWuUn",
  "16Qg00I9eTKpHhna64A9Rc6ov5YjlhnHt",
  "1ICbq9sXC_GCZIbAFuJAewF0jEvSogMqq",
  "1EUkkDzCau3TQLikIDNlvU5dhkkJlkJcu",
  "1VvQShCrY1NinT97TXN8X7ni4NvQcUIod", 
  "1xsMzdEITiGePgDA_j-SxzAPAAuUIJ1j5"
]

# Get soundfont files.
soundfont_files = [download_file(sf) for sf in soundfonts]

# Manipulate multiple files 
midi_gdrive_folder = "1nul-rjgtDaE8IdiMgHeW-j59Y_VMOHut" # This is Chopin.
midi_gdrive_files = get_filenames(midi_gdrive_folder)

# Loop across manipulations.
for file in midi_gdrive_files:
  midi_file = download_file(midi_gdrive_files[file])
  for st in semitones:
    for sf in soundfont_files: 
    # Build a file name based on this level of the manipulation.
      output_file = f"{output_folder}/{Path(midi_file).stem}_instrument+semitones_{Path(sf).stem}+{st}"
      
      # Run emo-manipulate.
      run([
          "emo-manipulate",
          "-i", midi_file,
          "-o", output_file,
          "-f", sf,
          "-s", str(st)
      ])
      
      # Print some info so we know whats happening as this runs.
      print(f"Created {output_file}")
      
      
  # Create baseline
  output_file = f"{output_folder}/{Path(midi_file).stem}_NA+NA_NA+NA"
  run([
    "emo-manipulate",
    "-i", midi_file,
    "-o", output_file
  ])


# Remove the temporary files.
remove(midi_file)
for file in soundfont_files:
  remove(file)
