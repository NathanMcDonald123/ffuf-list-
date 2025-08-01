# 🕵️ Ffuf Batch Fuzzing Script

A simple and effective Bash script to automate `ffuf` scans on a list of targets using multiple wordlists. This tool is designed for rapid reconnaissance and finding hidden endpoints, files, and directories.

-----

## ✨ Features

  * **Batch Processing:** Fuzzes multiple targets from a single input file (e.g., `alive.txt`).
  * **Multiple Wordlists:** Supports using an array of specific wordlist files and entire directories of wordlists.
  * **Automated Fuzzing:** Loops through each target and runs `ffuf` with each specified wordlist.
  * **Noise Filtering:** Automatically filters out common `404 Not Found` responses based on length, words, and lines.
  * **Consolidated Output:** After all scans, it consolidates and displays "true findings" in a clear, easy-to-read format.

-----

## 🚀 How to Use

### 1\. **Configuration**

Open the `fuzzing.sh` script and modify the `WORDLISTS` and `WORDLIST_DIRS` arrays to include the paths to your desired wordlists.

```bash
# --- Configuration ---
WORDLISTS=(
    "/usr/share/seclists/Fuzzing/LFI/LFI-Jhaddix.txt"
    # Add more specific wordlists here
)

WORDLIST_DIRS=(
    "/usr/share/seclists/Fuzzing/SQLi/"
    # Add more directories of wordlists here
)
```

You may also want to adjust the `NOISE_LENGTH`, `NOISE_WORDS`, and `NOISE_LINES` variables to match the typical `404` response of your target.

### 2\. **Run the Script**

Provide the script with a text file containing a list of `IP:Port` targets.

```bash
./fuzzing.sh alive.txt
```

### 3\. **Review Results**

The script will:

  * Save individual JSON results for each scan in the `ffuf_https_output` directory.
  * Print a consolidated list of interesting findings directly to the terminal in red for easy visibility.

-----

## 🛠️ Dependencies

This script requires `ffuf` and `jq` to be installed on your system.

  * **`ffuf` (Fuzz Faster U Fool):** A fast web fuzzer written in Go.
      * **Installation:** `go install github.com/ffuf/ffuf/v2@latest`
  * **`jq`:** A lightweight and flexible command-line JSON processor.
      * **Installation:** `sudo apt-get install jq`
