#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Script for generating CSV-file listings used in Wiztree"
    echo "Usage: $0 <directory>/ <csv_output_file.csv>"
    exit 1
fi
# Function to process each line


dir="$1"
csv_file="$2"
#Remove csv extention and preserve full path for the tmp listing file
tmp_listing=$(echo "$csv_file" | sed 's/\.csv$//g')
echo "Saving tmp listing to" $tmp_listing
echo -n "" > "$tmp_listing"
echo "File Name,Size,Allocated,Modified,Attributes,Files,Folders" > "$csv_file"

process_line() {
    local line=$1
    IFS="½" read -r type file_name size blocks mtime <<< "$line"
    allocated=$((blocks * 512))
    # Truncate fractional seconds
    mtime=$(echo "$mtime" | cut -d. -f1,2,3)
    modified=$(date -d "$mtime" +'%Y/%m/%d %H.%M.%S' 2>/dev/null)
    if [ "$type" == "d" ]; then
        #Add trailing slash to filename if it is a directory
        file_name="$file_name/"
        #Find number of files and directories
        files=$(find "$file_name" -maxdepth 1 -type f 2>/dev/null | wc -l)
        folders=$(find "$file_name" -maxdepth 1 -type d 2>/dev/null | wc -l)
        folders=$((folders - 1))
    else
        files=0
        folders=0
    fi
    attributes=0
    windows_path="X:\\$(echo "$file_name" | sed 's/^[/]*//' | tr '/' '\\')"
    echo "\"$windows_path\",$size,$allocated,$mtime,$attributes,$files,$folders" >> "$csv_file"
}

# add find results to tmp_listing file as they come in
find "$dir" -printf '%y½%p½%s½%b½%TY/%Tm/%Td %TH.%TM.%TS\n' 2>/dev/null | tee >(cat >> "$tmp_listing") 
echo "Listing done, processing to csv format"
# Remove " from filenames to prevent wiztree import from crashing due to malformed csv
sed -i 's/"/_/g' "$tmp_listing"
echo "Double quotes removed from listing"
IFS=$'\n'

# Check if the input file exists
if [ ! -f "$tmp_listing" ]; then
    echo "Input file $tmp_listing does not exist."
    exit 1
fi

# Read the file line by line using parallel execution to speed things up
while IFS= read -r line; do
    # Process each line in the background
    process_line "$line" &
    
    # Limit the number of parallel processes to 4
    if (( $(jobs -r -p | wc -l) >= 4 )); then
        wait -n
    fi
done < "$tmp_listing"

# Wait for the remaining background processes to finish
wait

# Remove the temporary output file
rm "$tmp_listing"
