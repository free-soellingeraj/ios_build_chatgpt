#!/usr/bin/env python3

import os
import re
import argparse
import fnmatch
import plistlib
import traceback


def read_ai_ignore(directory):
    ignore_path = os.path.join(directory, '.ai_ignore')
    ignore_patterns = []
    if os.path.exists(ignore_path):
        with open(ignore_path, 'r') as file:
            ignore_patterns = [line.strip() for line in file if line.strip() and not line.startswith("#")]
    return ignore_patterns


def is_ignored(path, ignore_patterns):
    for pattern in ignore_patterns:
        if fnmatch.fnmatch(path, pattern):
            return True
    return False


def read_code_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
        return content
    except:
        return None

def read_files_in_directory(directory, ignore_patterns):
    code_files = {}
    info_plist = None
    project_pbxproj = None
    for foldername, subfolders, filenames in os.walk(directory):
        for filename in filenames:
            filepath = os.path.join(foldername, filename)
            relative_path = os.path.relpath(filepath, directory)
            ignore = is_ignored(relative_path, ignore_patterns)
            if not ignore:
                code = read_code_file(filepath)
                if code is not None:
                    code_files[filepath] = code

    info_plist = ''
    project_pbxproj = ''
    for k, v in code_files.items():
        if k.endswith('.plist'):
            info_plist = k
        if k.endswith('.pbxproj'):
            project_pbxproj = k
    if project_pbxproj:
        del code_files[project_pbxproj]

    return code_files, info_plist, project_pbxproj


def remove_unnecessary_content(code):
    code = re.sub(r'//.*', '', code)  # Remove single-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)  # Remove multi-line comments
    code = re.sub(r'\s+', ' ', code)  # Remove excessive whitespace
    return code


def add_line_numbers(code):
    lines = []
    for line_num, line in enumerate(code.split('\n')):
        lines.append(str(line_num)+' '+line)
    return '\n'.join(lines)


def extract_swift_version_and_target(project_pbxproj):
    swift_version = None
    target = None
    if project_pbxproj:
        with open(project_pbxproj, 'r', encoding='utf-8') as file:
            content = file.read()
            swift_version_line = next((line for line in content.splitlines() if 'SWIFT_VERSION' in line), None)
            target_line = next((line for line in content.splitlines() if 'IPHONEOS_DEPLOYMENT_TARGET' in line), None)
            if swift_version_line:
                swift_version = swift_version_line.split('=')[-1].strip()
            if target_line:
                target = target_line.split('=')[-1].strip()
    return swift_version, target


def create_prompt(code_files, info_plist, project_pbxproj, change_prompt):
    full_prompt = "I am developing an iOS mobile app.\n"
    swift_version, target = extract_swift_version_and_target(project_pbxproj)
    if swift_version:
        full_prompt += f"The Swift version being used is {swift_version}.\n"
    if target:
        full_prompt += f"The iOS deployment target is {target}.\n"

    for file_path, code in code_files.items():
        content = code
        content = add_line_numbers(code)
        full_prompt += f"File: {file_path}\n{content}\n\n"

    full_prompt += f"{change_prompt}\nPlease suggest the necessary code changes or creations, specifying which files should be altered or created. Carry through any boilerplate or documentation or comments and wrap any code in three backticks with a language tag. Use non 3rd party frameworks and libraries wherever possible.  Please structure the response as sets of filepath to the codefile to alter followed by a code block e.g. Alter file1.py\n```python\nimport star```\nfile2.py\n```python\nimport os```, etc..  Please only return entire code files, no edit or alteration suggestions with snippets of files, even if it means the response takes longer and has duplicate code from the request.  Assume that if the file and code are not listed in this prompt, they do not exist and need to be created."

    return full_prompt


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate a prompt with project details and code files.")
    parser.add_argument("directory", help="Path to the project directory")
    parser.add_argument("change_prompt", help="Text describing the changes you are looking to make")

    args = parser.parse_args()

    directory = args.directory
    change_prompt = args.change_prompt

    ignore_patterns = read_ai_ignore(directory)
    code_files, info_plist, project_pbxproj = read_files_in_directory(directory, ignore_patterns)
    prompt = create_prompt(code_files, info_plist, project_pbxproj, change_prompt)

    print(prompt)

