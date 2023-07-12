import json
import re
import sys


def get_code_and_language(text):
    splt = text.split('\n')
    lang = splt[0]
    code = '\n'.join(splt[1:])
    return lang, code

def get_code_section_indices(text, start=0):
    backtick_start = text.index('```', start)+3
    backtick_close = text.index('```', backtick_start)
    return backtick_start, backtick_close

def get_filename_indices(text, wrap_char='`', start=0):
    backtick_start = text.index(wrap_char, start)+1
    backtick_close = text.index(wrap_char, backtick_start)
    return backtick_start, backtick_close

def get_preceding_paragraph_indices(text, backtick_start, preceding_blocks=2):
    scope = text[:backtick_start-3]
    splt = [string for string in scope.split('\n') if string.lstrip().rstrip()]
    preceding_paragraph = ''.join(splt[-preceding_blocks:]).replace('\n', '').lstrip().rstrip()
    idx = len(scope) - len(preceding_paragraph) - 1
    return idx

def get_filenames_from_text(text, wrap_char):
    filenames = []
    start = 0
    while True:
        try:
            backtick_start, backtick_close = get_filename_indices(text, wrap_char, start)
            filenames.append(text[backtick_start: backtick_close])
            start = backtick_close + 1

        except:
            break

    return filenames

def has_extension(string):
    if '.' in string:
        return True
    else:
        return False

def get_code_ppara_blocks(text):
    blocks = []
    start = 0
    while True:
        try:
            backtick_start, backtick_close = get_code_section_indices(text, start)
            lang, code = get_code_and_language(text[backtick_start: backtick_close])
            pidx = get_preceding_paragraph_indices(text, backtick_start)
            ppara = text[pidx: backtick_start-3]
            filenames_backtick = get_filenames_from_text(ppara, wrap_char="`")
            filenames_quote = get_filenames_from_text(ppara, wrap_char='"')
            filenames = filenames_backtick + filenames_quote
            filenames = [filename for filename in filenames if has_extension(filename)]
            blocks.append((lang, code, ppara, filenames))
            start = backtick_close + 1

        except:
            break

    return blocks

def pretty_print_code(text):
    for i, line in enumerate(text.split('\n')):
        print(str(i)+' '+line)

def pretty_print_list(l):
    for i, line in enumerate(l):
        print(str(i)+' '+line)

def write_list_to_column(filepath, lines):
    # Open the file at file_path in write mode, this will replace the entire content
    with open(filepath, 'w') as file:
        # Iterate through the lines and write each line to the file
        for line in lines:
            file.write(line + '\n')

def write_code(filepath, code, overwrite=True):
    # Split the content_string by newline character to get a list of lines
    lines = code.split('\n')
    write_list_to_column(filepath, lines)


def prompt_user_for_file(lang, code, ppara, filenames):

    # Show the developer the preceding paragraph and code block
    print("--- Start ---")
    print("--- Preceding Paragraph ---")
    pretty_print_code(ppara)
    print("--- Code Block ---")
    pretty_print_code(code)
    print("--- Suggested Files ---")
    pretty_print_list(filenames)

    # Prompt the developer to select a file
    selected_file = input("Please select a file for this code block: ")
    print("--- End ---")

    return selected_file


def main(content):
    output = []
    changed_files = []
    blocks = get_code_ppara_blocks(text=content)
    for block in blocks:
        lang, code, ppara, filenames = block
        selected_file = prompt_user_for_file(lang, code, ppara, filenames)
        # Store them in the output
        output.append({
            "preceding_paragraph": ppara,
            "code_block": code,
            "suggested_files": filenames,
            "language": lang,
            "selected_file": selected_file
        })

        print(f'Writing {selected_file} num lines:', len(code.split('\n')))
        write_code(selected_file, code)

    write_list_to_column('changed_files_temp.txt', [out['selected_file'] for out in output])

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python parse_file_changes.py '<content>'")
        sys.exit(1)
    content = sys.argv[1]
    main(content)

