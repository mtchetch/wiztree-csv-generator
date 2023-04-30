#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Script for generating CSV-file listings used in Wiztree"
    echo "Usage: $0 <directory>/ <csv_output_file>"
    exit 1
fi

dir="$1"
csv_file="$2"

echo "File Name,Size,Allocated,Modified,Attributes,Files,Folders" > "$csv_file"

output=$(find "$dir" -exec stat -c '%n|%s|%b|%y|%F' '{}' \;)

IFS=$'\n'
for line in $output; do
    IFS='|' read -r file_name size blocks mtime type <<< "$line"

    is_dir=0
    is_file=0

    if [ "$type" == "directory" ]; then
        is_dir=1
        files=$(find "$file_name" -maxdepth 1 -type f 2>/dev/null | wc -l)
        folders=$(find "$file_name" -maxdepth 1 -type d 2>/dev/null | wc -l)
        folders=$((folders - 1))
    else
        is_file=1
        files=0
        folders=0
    fi

    allocated=$((blocks * 512))
    modified=$(date -d "$mtime" +'%Y/%m/%d %H.%M.%S')
    attributes=0

    windows_path="X:$(echo "$file_name" | sed 's/^[/]*//' | tr '/' '\\')"
    echo "\"$windows_path\",$size,$allocated,$modified,$attributes,$files,$folders" >> "$csv_file"
done
