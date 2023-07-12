import sys

def get_build_outcome(build_log):
    log_lines = build_log.split('\n')
    outcome_lines = get_line_numbers_for_substring_match(lines=log_lines, substring='**')
    if len(outcome_lines) == 0:
        return ""
    return log_lines[outcome_lines[0]]

def get_line_numbers_for_substring_match(lines, substring):
    line_numbers = []
    for line_number, line in enumerate(lines):
        if substring in line:
            line_numbers.append(line_number)
    return line_numbers

def get_errors_from_simctl_build_log(build_log):
    log_lines = build_log.split('\n')
    error_last_lines = get_line_numbers_for_substring_match(lines=log_lines, substring='~')
    error_last_lines += get_line_numbers_for_substring_match(lines=log_lines, substring='^')
    error_last_lines = sorted(list(set(error_last_lines)))
    brief_stack_traces = []
    for last_line in error_last_lines:
        brief_stack_traces.append('\n'.join(log_lines[last_line-2:last_line+1]))
    return brief_stack_traces

def parse_build_log(build_log):
    outcome_string = get_build_outcome(build_log)
    brief_stack_traces = get_errors_from_simctl_build_log(build_log)
    return outcome_string, brief_stack_traces

if __name__ == "__main__":
    build_log = sys.argv[1]
    output_type = sys.argv[2] # outcome | errors_string
    if output_type == 'outcome':
        print(get_build_outcome(build_log))
    elif output_type == 'errors_string':
        print(' and '.join(get_errors_from_simctl_build_log(build_log)))
