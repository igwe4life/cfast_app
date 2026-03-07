
import re

def count_braces(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove comments
    content = re.sub(r'//.*', '', content)
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
    
    # Remove strings
    content = re.sub(r"'(?:[^'\\]|\\.)*'", "''", content)
    content = re.sub(r'"(?:[^"\\]|\\.)*"', '""', content)

    open_braces = content.count('{')
    close_braces = content.count('}')
    
    print(f"Open braces: {open_braces}")
    print(f"Close braces: {close_braces}")
    
    stack = []
    lines = content.splitlines()
    for i, line in enumerate(lines):
        for char in line:
            if char == '{':
                stack.append(i + 1)
            elif char == '}':
                if not stack:
                    print(f"Extra closing brace at line {i + 1}")
                else:
                    stack.pop()
    
    if stack:
        print(f"Unclosed braces at lines: {stack}")

if __name__ == "__main__":
    count_braces(r"c:\Users\Admin\StudioProjects\cfast_app\lib\screens\create_listing.dart")
