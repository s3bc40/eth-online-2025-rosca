#!/bin/bash

# ABI Synchronization Script
#
# Automatically finds all contract artifact JSON files in `out` directory,
# extracts their ABIs using 'jq', and saves the resulting JSON files.
#
# Generate with the help of AI (Gemini)


TARGET_DIR="abis"
ROOT_DIR="../../apps/foundry"

echo "--- ABI Synchronization Started ---"

# Check if 'jq' is installed
if ! command -v jq &> /dev/null
then
    echo "ERROR: 'jq' command not found. Please install 'jq' to run this script."
    exit 1
fi

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Find needed JSON artifact files in the 'out' directories
FIND_COMMAND="find $ROOT_DIR -type f -path '*/out/*' \( -name 'Factory.json' -o -name 'Committee.json' -o -name 'MockAutomationRegistrar.json' -o -name 'MockAutomationRegistry.json' -o -name 'MockEntropy.json' \) -print0"
ARTIFACTS_FOUND=0

# Loop through all found artifact paths
# "-print0" put a null character at the end of each file name to handle spaces in names
# "IFS= read -r -d $'\0'" reads each null-terminated string correctly
eval $FIND_COMMAND | while IFS= read -r -d $'\0' ARTIFACT_PATH; do
    ARTIFACTS_FOUND=$((ARTIFACTS_FOUND + 1))
    
    # Get the basename (e.g., MyContract.json)
    BASE_FILE=$(basename "$ARTIFACT_PATH")
    # Remove the .json suffix
    # Start the stream edition and ignore case for .json extension
    CONTRACT_NAME=$(echo "$BASE_FILE" | sed 's/\.json$//I')
    
    OUTPUT_PATH="${TARGET_DIR}/${CONTRACT_NAME}.json"

    # Extract the ABI using jq to safely extract the '.abi' property.
    # "." refers to the entire JSON content of the file.
    ABI_CONTENT=$(jq '.abi' "$ARTIFACT_PATH")

    # Check if jq command was successful and ABI content is valid
    # "$?" checks the exit status of the last command (jq in this case).
    # "-z" checks if the string is empty.
    if [ "$?" -ne 0 ] || [ "$ABI_CONTENT" == "null" ] || [ -z "$ABI_CONTENT" ]; then
        echo "  [SKIP] Invalid or missing ABI in: $(basename "$ARTIFACT_PATH")"
        continue
    fi

    # Write the ABI content to the target file
    echo "$ABI_CONTENT" > "$OUTPUT_PATH"
    echo "  [SYNC] Extracted ${CONTRACT_NAME}.json to ${OUTPUT_PATH}"
done

if [ "$ARTIFACTS_FOUND" -eq 0 ]; then
    echo "No contract artifacts found. Check \$ROOT_DIR path ($ROOT_DIR) and build outputs."
fi

echo "--- ABI Synchronization Complete ($ARTIFACTS_FOUND artifacts processed) ---"

exit 0
