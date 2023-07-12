#!/bin/bash

# Check if the correct number of arguments are passed
if [ "$#" -ne 3 ]; then
    echo "Usage: ./log_gpt_api_call.sh [prompt] [filename] [response]"
    exit 1
fi

# Extract arguments
PROMPT=$1
FILENAME=$2
RESPONSE=$3

# Get the current timestamp
TIMESTAMP=$(date --iso-8601=seconds)

# Log the prompt, response, timestamp, and filename in a JSON format
LOG_ENTRY="{\"timestamp\": \"$TIMESTAMP\", \"filename\": \"$FILENAME\", \"prompt\": \"$PROMPT\", \"response\": \"$RESPONSE\"}"

# Append the log entry to a log file
echo $LOG_ENTRY >> api_call_log.jsonl

# Notify the user
echo "API call logged successfully."

