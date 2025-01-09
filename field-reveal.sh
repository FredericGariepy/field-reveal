#!/bin/bash
#--------------------------------------------
# Frederic Gariepy
# https://github.com/FredericGariepy/field-reveal
# Path to the fields.txt file
fields_file="fields.txt"

# TODO
# *change the check to get list from arg2, or other method
# Check if fields_file exists
if [ ! -f "$fields_file" ]; then
  echo "Error: $fields_file does not exist."
  exit 1
fi

# Check if exactly one argument is passed
if [ $# -ne 1 ]; then
  echo -e "Usage: field-reveal -option /path/to/target. Reveal fields of Directories and Files. \nfield-reveal -h for help."
  exit 1
fi

# Set the target variable to the argument passed
target="$1"

# Remove the trailing slash if present
target="${target%/}"

# Resolve full path of the target
target=$(realpath "$target" 2>/dev/null)

# Set the LESS environment variable to use a custom prompt
export LESS="--prompt=Press 'q' to quit."


# list directory files with detailed information
list_files() {
  # Directory listing
  local target="$1"
  # Print fields for directories, this is done statically
  echo -e "Fields for "$target" : \nIndex, Permissions, Links, Owner, Group, Size, Month, Day, Time, Filename"
  {
  echo -e "Index, Permissions, Links, Owner, Group, Size, Month, Day, Time, Filename"

    # Process the ls output dynamically
    ls -al "$target" | tail -n +2 | awk '{
      printf "%d\t", NR-1;  # Add index
      for (i = 1; i <= NF; i++) {
        printf "%s\t", $i;  # Dynamically handle all fields
      }
      print "";  # New line after processing a row
    }'
  } | column -t | less -S  -P "Index Permissions Links Owner Group Size Month Day Time Filename | Press 'q' to quit\. -N"

}

# Function to get the target's path relative to significant Linux folders
get_significant_path() {
    local target="$1"

    # Review: is necessary? 
    # $? is a special variable. It holds the exit status of the last executed command. 0 if successful.
    if [[ $? -ne 0 ]]; then
        echo "Error: Path '$1' is not supported."
        exit 1
    fi

    # List of significant folders
    local significant_folders=(/etc/ /var/ /usr/ /lib/ /boot/ /opt/ /home/ /proc/ /sys/ /run/)

    # Check if $target contains any significant folder
    for folder in "${significant_folders[@]}"; do
    # Check if the target contains the folder path
        if [[ "$target" == *"$folder"* ]]; then
            # This keeps the significant folder and everything after it

            # remove everything up to and including first occurance of $folder
            target="${target#*$folder}"

            # prepend the $folder back
            target="$folder$target"

            targetType=1  # Target is significant
            break
        fi
    done

    # return target
    echo "$target"
}

# debug print
# target_path=$(get_significant_path "$target")
# echo "$target_path"

show_file() {
  local target_path="$1"
  local fields_file="$2"

  # Get the comma-separated fields for matching target_path from the fields file
  local fields=$(awk -F',' -v path="$target_path" '
    $1 ~ path {                                 # Does the first field (/path/) being passed to awk match the path in fields_file ?
      for (i = 2; i <= NF; i++) {               # Process the matching line, skipping over the matching /path/
        gsub(/^[ \t]+|[ \t]+$/, "", $i)         # Remove leading and trailing spaces/tabs
        printf "%s%s", $i, (i < NF ? "," : "")  # Print the field followed by a comma
      }
    }
  ' "$fields_file")

  # Extract separator and fields_count directly from the fields string
  separator=$(echo "$fields" | cut -d',' -f1)
  separator=${separator:-","}

  awk_parser=$(echo "$fields" | cut -d',' -f2)

  fields_count=$(echo "$fields" | cut -d',' -f3)

  fields=$(echo "$fields" | cut -d',' -f4-)

  # If no fields found, exit with error
  if [ -z "$fields" ]; then
    echo "No fields found for path: $target_path" >&2
    return 1
  fi

  # Print the fields to the terminal
  echo -e "Fields for $target_path :\n$fields"

  # Prepare header for display
  local header=$(printf "%s" "$fields" | tr ',' '\t')

  # Pipe the header into less along with the file content
  {
    # Print header first
    echo -e "$header"

    # Process the file content
    if [ "$awk_parser" == "FPAT" ]; then
      tail -n +1 "$target_path" | awk -v FPAT="$separator" -v fields_count="$fields_count" '{
        if ($0 ~ /^#/) { next }
        if (NF < (fields_count - 1)) { next }
        printf "%s", $1
        for (i=2; i<=fields_count; i++) {
          printf "\t%s", $i
        }
        for (i=fields_count+1; i<=NF; i++) {
          printf " %s", $i
        }
        printf "\n"
      }'
    else
      tail -n +1 "$target_path" | awk -F "$separator" -v fields_count="$fields_count" '{
        if ($0 ~ /^#/) { next }
        if (NF < (fields_count - 1)) { next }
        printf "%s", $1
        for (i=2; i<=fields_count; i++) {
          printf "\t%s", $i
        }
        for (i=fields_count+1; i<=NF; i++) {
          printf " %s", $i
        }
        printf "\n"
      }'
    fi

  } | column -t -s $'\t' | less -S -P "$(echo -e "$header" | tr -s '\t' ', ') | Press 'q' to quit"
}


# Check target type and perform field-reveal
field_reveal() {
  if [ -e "$target" ]; then
    if [ -d "$target" ]; then
      # It's a directory
      list_files "$target"  # List the files in the folder
      return  # Exit
    fi
    if [ -f "$target" ]; then
      # It's a file
      target_path=$(get_significant_path "$target")
      show_file "$target_path" "$fields_file"
      return  # Exit
    fi
    exit 1  # Path exists but is neither a file nor a directory (special file)
  else
    echo "Error: '$target' does not exist."
    exit 1  # Path does not exist
  fi
}

field_reveal "$target"
