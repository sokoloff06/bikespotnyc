#!/bin/bash

# A script to bulk-upload secrets to GitHub from a .env file.
#
# Prerequisites:
# 1. GitHub CLI (`gh`) must be installed. See: https://cli.github.com/
# 2. You must be authenticated. Run `gh auth login`.
# 3. You must be in the root of the repository you want to set secrets for.

ENV_FILE=".env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: The '$ENV_FILE' file was not found."
    echo "Please ensure it exists in the current directory."
    exit 1
fi

echo "Reading secrets from '$ENV_FILE' and uploading to the current GitHub repository."

# Loop through each line in the .env file
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip comments and empty lines
    if [[ "$line" =~ ^\s*# ]] || [[ -z "$line" ]]; then
        continue
    fi

    # Extract the key and value
    # This handles values that might contain '='
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)

    # Remove surrounding quotes from the value, if they exist
    value="${value%\"}"
    value="${value#\"}"

    echo "Setting secret for '$key'..."
    # Use gh CLI to set the secret. The --body flag reads the value from stdin.
    echo "$value" | gh secret set "$key" --body -
done < "$ENV_FILE"

echo "✅ All secrets have been set successfully."

