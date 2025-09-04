#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# The directory where your original font files are located.
SOURCE_FONTS_DIR="fonts"
# The main output directory for the generated glyphs.
GLYPHS_DIR="glyphs"
# The name of the JSON file that lists all font styles.
JSON_FILE="glyphs.json"
# The path to the build-glyphs executable.
BUILD_GLYPHS_EXEC="./node_modules/.bin/build-glyphs"

# --- Script Start ---
# Check if the source font directory exists.
if [ ! -d "$SOURCE_FONTS_DIR" ]; then
    echo "Error: Source font directory not found at '$SOURCE_FONTS_DIR'"
    exit 1
fi

# Check if the build-glyphs executable exists.
if [ ! -x "$BUILD_GLYPHS_EXEC" ]; then
    echo "Error: build-glyphs executable not found or not executable at '$BUILD_GLYPHS_EXEC'"
    exit 1
fi

# Clean up previous builds to ensure a fresh start.
echo "Cleaning up previous build..."
rm -rf "$GLYPHS_DIR" "$JSON_FILE"
mkdir -p "$GLYPHS_DIR"

# Create an empty bash array to hold the font names for the JSON file.
declare -a font_names_for_json

# --- Find and Process Fonts ---
# Loop through all .ttf files found in the source directory.
# The `while ... done < <(find ...)` syntax is crucial to avoid a subshell,
# ensuring the font_names_for_json array is available after the loop.
while IFS= read -r font_path; do
    # --- Derive Names and Paths ---
    # 1. Get the filename without the extension (e.g., "Modam-Bold").
    filename_no_ext=$(basename "$font_path" .ttf)

    # 2. Create the "Font Name" by replacing hyphens with spaces (e.g., "Modam Bold").
    font_name="${filename_no_ext//-/ }"

    # 3. Define the full output path for this specific font.
    output_dir="$GLYPHS_DIR/$font_name"

    # --- Process the Font ---
    echo "Processing '$font_path' -> '$output_dir'"

    # Create the specific output directory for this font's glyphs.
    mkdir -p "$output_dir"

    # Run the build-glyphs command.
    "$BUILD_GLYPHS_EXEC" "$font_path" "$output_dir"

    # Add the properly quoted font name to our array for later JSON generation.
    font_names_for_json+=("\"$font_name\"")

done < <(find "$SOURCE_FONTS_DIR" -type f -name "*.ttf")

# --- Finalize ---
# Check if any fonts were actually processed.
if [ ${#font_names_for_json[@]} -eq 0 ]; then
    echo "Warning: No .ttf files were found in '$SOURCE_FONTS_DIR'. $JSON_FILE will be empty."
    echo "[]" > "$JSON_FILE"
    exit 0
fi

# After the loop, generate the glyphs.json file from the array.
echo "Generating $JSON_FILE..."

# This function joins the array elements with a comma.
json_content=$(IFS=,; echo "${font_names_for_json[*]}")

# We wrap the content in brackets to form a valid JSON array.
echo "[$json_content]" > "$JSON_FILE"


echo "-----------------------------------"
echo "All glyphs built successfully."
echo "Generated $JSON_FILE and populated the '$GLYPHS_DIR' directory."
