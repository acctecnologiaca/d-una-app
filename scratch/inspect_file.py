import sys

file_path = r"C:\Users\aleja\flutter_apps\MVP\d_una_app\lib\features\profile\presentation\screens\verification_screen.dart"
with open(file_path, 'rb') as f:
    content = f.read()
    # Print the first 200 bytes as hex and repr
    print(f"First 200 bytes hex: {content[:200].hex()}")
    print(f"First 200 bytes repr: {repr(content[:200])}")
    
    # Find the dialog area
    search_str = b"final confirmed = await showDialog<bool>("
    idx = content.find(search_str)
    if idx != -1:
        print(f"Found dialog area at index {idx}")
        # Print 50 bytes before and 100 after
        start = max(0, idx - 50)
        end = min(len(content), idx + 150)
        print(f"Dialog area bytes repr: {repr(content[start:end])}")
    else:
        print("Could not find dialog string in binary content")
