
path = "/home/elliot/git_repos/honey-scan/web/assets/app.6539b5af.js"
target = "api_active"
window_size = 500

try:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
        index = content.find(target)
        if index != -1:
            start = max(0, index - window_size)
            end = min(len(content), index + len(target) + window_size)
            print(f"Context found:\n{content[start:end]}")
        else:
            print("Target string not found.")
except Exception as e:
    print(f"Error: {e}")
