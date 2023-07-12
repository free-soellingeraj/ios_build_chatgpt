# ios_build_chatgpt
Building IOS apps via the command line with LLM prompts.
# Environment
Tested in:
- MacOS (M1)
- Latest OS
- Latest XCode
- xcodegen


# Usage

## Configure your project
```bash
$ mkdir -p path/to/new_project
$ cd path/to/new_project
$ cp path/to/ios_build_chatgpt/.ai_ignore .
$ cp path/to/ios_build_chatgpt/ios_app_rapid_test.sh .
$ cp path/to/ios_build_chatgpt/project.yml .
$ cp path/to/ios_build_chatgpt/chatgpt_app_config.yaml .
```

## Update static data
Add correct paths in:
 - project.yml
 - chatgpt_app_config.yaml

OpenAI API key is required in chatgpt_app_config.yaml for LLM

## Writing Code
```bash
$ path/to/ios_build_chatgpt/update_file_via_prompt.sh "your feature definition"
```

# Demo
https://drive.google.com/file/d/1IFwAePTK5WdYikarxJk6oYcrGUc21Tdh/view?usp=drive_link


# Roadmap
Bugs:
- filename suggestions are not working.. get a better regex
- figure out why failure outcome doesn't work on testing regime
- pasting exceptions from CLI print out into prompt doesn't work

Features:

- non-whole-file updates! Low Priority because GPT4 does what I ask.
- exception follow ups
- what happens when the LLM returns no changes
	- agent is getting stuck
- when the LLM says "the code already has that feature..."

Hard coded shit

- Starting point as the ios Hello, World. app doesn't seem to be scripted.  Create it in xcode and put it in GH.
- the prompt template - move it into a purpose built python script that returns the prompt
- remove: The substring 'edit' was not found in any filenames.
- manually created project.yml
- manually installing all deps
- this thing: "com.mycompany.new_project" in test script
- manually accepted the EULA for xcodegen

