
import re

def check_class_closure(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    clean_lines = []
    # Simplified cleaning: just remove // comments for brace counting
    # This is rough but should work for this purpose
    for line in lines:
        line_content = line.split('//')[0]
        clean_lines.append(line_content)

    depth = 0
    class_start_line = -1
    class_found = False

    for i, line in enumerate(clean_lines):
        line_num = i + 1
        
        # Check for class start
        if 'class _AddListingScreenState' in line:
            class_start_line = line_num
            class_found = True
            print(f"Class starts at line {line_num}")

        # Count braces
        open_count = line.count('{')
        close_count = line.count('}')
        
        previous_depth = depth
        depth += open_count - close_count
        
        if class_found:
            if depth == 0 and previous_depth > 0:
                print(f"Class potentially closes at line {line_num}")
                # We want to know if this is the end of the file or premature
                if line_num < len(lines) - 10: # arbitrary buffer
                    print("Class closed prematurely!")
            
            if depth < 0:
                 print(f"Error: Negative depth at line {line_num}")

if __name__ == "__main__":
    check_class_closure(r"c:\Users\Admin\StudioProjects\cfast_app\lib\screens\create_listing.dart")
