#!/bin/bash

function exit_prompt() {
    echo
    echo "1) Accept changes (commit)"
    echo "2) Reject changes (revert)"
    echo "3) Keep changes (do not revert)"
    read -p "Choose option (1/2/3): " -n 1 -r
    echo
    case $REPLY in
        1)
            for file_path in "${changed_files[@]}"; do
                git add "$file_path"
            done
            git commit -m "(feature success) $change_prompt"
            echo "Code updates committed."
            ;;
        2)
            for file_path in "${changed_files[@]}"; do
                if git ls-files --error-unmatch "$file_path" &> /dev/null; then
                    git checkout -- "$file_path"
                else
                    rm "$file_path"
                fi
            done
            echo "Code updates rejected and reverted."
            ;;
        3)
            echo "Keeping the changes without committing."
            for file_path in "${changed_files[@]}"; do
                git add "$file_path"
            done
            git commit -m "(intermediate commit) $change_prompt"
            echo "Code updates committed."
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
    exit
}

# Trap Ctrl+C and call exit_prompt function
trap exit_prompt SIGINT

toolpath="$(dirname -- "${BASH_SOURCE[0]}")"
toolpath="$(cd -- "$toolpath" && pwd)"
if [[ -z "$toolpath" ]]; then
    exit 1
fi
echo "Tool path: $toolpath"

if ! command -v jq &> /dev/null; then
    echo "jq could not be found. Please install jq to parse JSON responses."
    exit
fi

if ! command -v yq &> /dev/null; then
    echo "yq could not be found. Please install yq to parse YAML files."
    exit
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: ./update_file_via_prompt.sh <change_prompt>"
    exit 1
fi

config_file="chatgpt_app_config.yaml"
change_prompt=$1

api_key=$(yq eval '.api_key' $config_file)
max_tokens=$(yq eval '.max_tokens' $config_file)
test_regime=$(yq eval '.test_regime' $config_file)
model_id=$(yq eval '.model_id' $config_file)
temperature=0.3

full_prompt=$(python3.8 $toolpath/create_full_prompt.py "." "$change_prompt")

json_payload=$(jq -n \
    --arg content "$full_prompt" \
    --arg model_id "$model_id" \
    --argjson temperature "$temperature" \
    '{messages: [{"role": "user", "content": $content}], model: $model_id, temperature: $temperature}')

echo "JSON payload to OpenAI: $json_payload"

response=$(curl https://api.openai.com/v1/chat/completions -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $api_key" \
    -d "$json_payload" )

if echo "$response" | jq -e '.error' > /dev/null; then
    error_msg=$(echo "$response" | jq -r '.error.message')
    echo "Error from ChatGPT API: $error_msg"
    exit_prompt
fi

echo "LLM Response: ${response}"

updated_code=$(echo "$response" | jq -r '.choices[0].message.content')

# parse response and make proposed code changes
python3.8 $toolpath/parse_file_changes.py "$updated_code"

# update .xcodeproj file to reflect any new files, etc..
xcodegen

if [ $? -ne 0 ]; then
    echo "The $toolpath/parse_file_changes.py script failed. Exiting..."
    exit_prompt
fi

# mapfile -t changed_files < changed_files_temp.txt
while IFS= read -r line; do
    changed_files+=("$line")
done < changed_files_temp.txt

edit_found=0

for filename in "${changed_files[@]}"; do
    if [[ $filename == *"edit"* ]]; then
        edit_found=1
    fi
done

if [[ $edit_found -eq 1 ]]; then
    echo "The substring 'edit' was found in one or more filenames."
    echo "Exiting loop.  Run tests directly after editing the files manually.  File to edit are marked in place with <file to edit>.edit"
    echo "Run tests with ./ios_app_rapid_test.sh"
    exit 0
else
    echo "The substring 'edit' was not found in any filenames."
    echo "Continuing testing..."
fi

# Execute in subshell
$test_regime $toolpath

# Capture the outcome of the test
test_status=$?

echo "test status: $test_status"
rm changed_files_temp.txt

if [ $test_status -eq 0 ]; then
    echo "Tests passed successfully without error."
else
    echo "Tests passed with errors."
fi

exit_prompt
