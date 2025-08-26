#!/bin/bash

# Function to print usage
usage() {
  echo "Usage: $0 -d directory -c creator -o company -p package [-y year]"
  echo "  -d directory  Directory to read from (including subdirectories)"
  echo "  -c creator    Name of the creator"
  echo "  -o company    Name of the company with the copyright"
  echo "  -p package    Package or library name"
  echo "  -y year       Copyright year (optional, defaults to current year)"
  exit 1
}

# Get the current year if not provided
current_year=$(date +"%Y")

# Default values
year="$current_year"

# Parse arguments
while getopts ":d:c:o:p:y:" opt; do
  case $opt in
    d) directory="$OPTARG" ;;
    c) creator="$OPTARG" ;;
    o) company="$OPTARG" ;;
    p) package="$OPTARG" ;;
    y) year="$OPTARG" ;;
    *) usage ;;
  esac
done

# Check for mandatory arguments
if [ -z "$directory" ] || [ -z "$creator" ] || [ -z "$company" ] || [ -z "$package" ]; then
  usage
fi

# Define the header template
header_template="//
//  %s
//  %s
//
//  Created by %s.
//  Copyright © %s %s.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//"

# Loop through each Swift file in the specified directory and subdirectories
find "$directory" -type f -name "*.swift" | while read -r file; do
  # Check if the first line is the swift-format-ignore indicator
  first_line=$(head -n 1 "$file")
  if [[ "$first_line" == "// swift-format-ignore-file" ]]; then
    echo "Skipping $file due to swift-format-ignore directive."
    continue
  fi

  # Create the header with the current filename
  filename=$(basename "$file")
  header=$(printf "$header_template" "$filename" "$package" "$creator" "$year" "$company")

  # Remove all consecutive lines at the beginning which start with "// ", contain only whitespace, or only "//"
  awk '
  BEGIN { skip = 1 }
  {
    if (skip && ($0 ~ /^\/\/ / || $0 ~ /^\/\/$/ || $0 ~ /^$/)) {
      next
    }
    skip = 0
    print
  }' "$file" > temp_file

  # Add the header to the cleaned file
  (echo "$header"; echo; cat temp_file) > "$file"
  
  # Remove the temporary file
  rm temp_file
done

echo "Headers added or files skipped appropriately across all Swift files in the directory and subdirectories."