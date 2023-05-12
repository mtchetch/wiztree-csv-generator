#!/bin/bash
if [ $# -ne 2 ]; then
    echo "Script for generating CSV-file listings used in Wiztree"
    echo "Usage: $0 <directory>/ <csv_output_file>"
    exit 1
fi

dir="$1"
csv_file="$2"

echo "File Name,Size,Allocated,Modified,Attributes,Files,Folders" > "$csv_file"

listing=$(find "$dir" -printf '%y½%p½%s½%b½%TY/%Tm/%Td %TH.%TM.%TS\n')
IFS=$'\n'

for line in $listing; do
    IFS="½"
    read -r type file_name size blocks mtime <<< "$line"
    allocated=$((blocks * 512))
    # Truncate fractional seconds
    mtime=$(echo "$mtime" | cut -d. -f1,2,3)
    modified=$(date -d "$mtime" +'%Y/%m/%d %H.%M.%S' 2>/dev/null)
    if [ "$type" == "d" ]; then
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
done
