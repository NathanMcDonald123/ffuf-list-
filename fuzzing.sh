#!/bin/bash

# --- Configuration ---
# The first command-line argument will be used as the targets file.
# Example usage: ./script.sh alive.txt

# Array of specific wordlist FILES to use.
WORDLISTS=(
    # General fuzzing and attack strings
    # 								enter any specific wordlists HERE, EXAMPLE BELOW
    "/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt"
)

# New array of DIRECTORIES containing multiple wordlist files to use.
# The script will loop through every .txt file in each of these directories.
WORDLIST_DIRS=(
    # 								enter any specific directories with wordlists HERE, EXAMPLE BELOW
    "/usr/share/seclists/Fuzzing/SQLi/"
)

OUTPUT_DIR="ffuf_https_output" # Directory to save individual JSON results
NOISE_LENGTH="1565"
NOISE_WORDS="183"
NOISE_LINES="14"

# --- Script Start ---

echo "[*] Initializing Ffuf Scan Environment..."

# Check for the required command-line argument
if [ -z "$1" ]; then
    echo "ERROR: No targets file provided."
    echo "Usage: $0 <targets_file>"
    exit 1
fi
HTTPS_TARGETS="$1"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Check if wordlist files exist
for wordlist in "${WORDLISTS[@]}"; do
    if [ ! -f "$wordlist" ]; then
        echo "ERROR: Wordlist not found at $wordlist. Please verify the path."
        exit 1
    fi
done

# Check if wordlist directories exist
for dir in "${WORDLIST_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "ERROR: Wordlist directory not found at $dir. Please verify the path."
        exit 1
    fi
done

# Check if targets file exists
if [ ! -f "$HTTPS_TARGETS" ]; then
    echo "ERROR: Target list not found at $HTTPS_TARGETS. Please verify the path."
    exit 1
fi

echo "[*] Starting ffuf scans on discovered HTTPS services..."
echo "    Using targets from: $HTTPS_TARGETS"
echo "    Filtering out responses with Length: $NOISE_LENGTH, Words: $NOISE_WORDS, Lines: $NOISE_LINES"

# Loop through each IP:Port combination in the targets file
while IFS= read -r ip_port; do
    # Skip empty lines or lines starting with '#'
    [[ "$ip_port" =~ ^#.* ]] && continue
    [ -z "$ip_port" ] && continue

    ip=$(echo "$ip_port" | cut -d ':' -f 1)
    port=$(echo "$ip_port" | cut -d ':' -f 2)
    protocol="https"

    # --- Loop 1: Iterate through specific wordlist files ---
    for wordlist in "${WORDLISTS[@]}"; do
        wordlist_name=$(basename "$wordlist" .txt)
        output_file_name="${ip}-${port}-${wordlist_name}-ffuf_results.json"
        
        echo "    -> Fuzzing $protocol://$ip:$port/FUZZ with file: $wordlist_name"

        ffuf -u "$protocol://$ip:$port/FUZZ" \
             -w "$wordlist" \
             -mc 200,301,302 \
             -fs "$NOISE_LENGTH" \
             -fw "$NOISE_WORDS" \
             -fl "$NOISE_LINES" \
             -t 50 \
             -v \
             -o "$OUTPUT_DIR/$output_file_name" \
             -of json \
             -r

        echo "--------------------------------------------------------"
    done

    # --- Loop 2: Iterate through all .txt files in specified directories ---
    for dir in "${WORDLIST_DIRS[@]}"; do
        for wordlist_file in "$dir"*.txt; do
            # Skip if the glob pattern finds no files
            [ -f "$wordlist_file" ] || continue
            
            wordlist_name=$(basename "$wordlist_file" .txt)
            output_file_name="${ip}-${port}-${wordlist_name}-ffuf_results_dir.json"

            echo "    -> Fuzzing $protocol://$ip:$port/FUZZ with file: $wordlist_name (from directory)"
            
            ffuf -u "$protocol://$ip:$port/FUZZ" \
                 -w "$wordlist_file" \
                 -mc 200,301,302 \
                 -fs "$NOISE_LENGTH" \
                 -fw "$NOISE_WORDS" \
                 -fl "$NOISE_LINES" \
                 -t 50 \
                 -v \
                 -o "$OUTPUT_DIR/$output_file_name" \
                 -of json \
                 -r
            
            echo "--------------------------------------------------------"
        done
    done
done < "$HTTPS_TARGETS"

echo "[*] All Ffuf scans complete."
echo "[*] Consolidating and displaying true findings from all results..."

# --- Consolidate and Display True Findings in RED ---
echo -e "\033[0;31m--- Consolidated Ffuf True Findings ---"

# The xargs and jq output is now piped to another xargs command
# that adds the red color before and resets it after each line.
find "$OUTPUT_DIR" -name "*.json" -print0 | xargs -0 jq -c \
    '.results[] | select((.status == 200 or .status == 301 or .status == 302) and (.length != '$NOISE_LENGTH' or .words != '$NOISE_WORDS' or .lines != '$NOISE_LINES')) | {url: .url, status: .status, length: .length, words: .words, lines: .lines, "content-type": ."content-type", redirect: .redirectlocation}' | xargs -L 1 -I {} echo -e "\033[0;31m{}\033[0m"

echo -e "\033[0;31m--- End of Consolidated Ffuf True Findings ---\033[0m"
echo "[*] Script finished."

