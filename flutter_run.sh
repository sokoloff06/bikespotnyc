#!/bin/bash

# This script reads variables from .env and passes them to `flutter run`
# using --dart-define.

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Error: .env file not found."
    exit 1
fi

# Read .env file, filter out comments and empty lines, and build the --dart-define arguments
DART_DEFINES=$(grep -v '^#' .env | grep -v '^$' | awk '{print "--dart-define=" $0}' | tr '\n' ' ')

# Execute flutter run with all the dart define arguments
# You can add other flutter run arguments here if needed (e.g., --debug)
echo "Running flutter with environment variables from .env..."
flutter run $DART_DEFINES
