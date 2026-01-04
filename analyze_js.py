import re
import os
from dotenv import load_dotenv

load_dotenv()

# path = 'web/assets/app.6539b5af.js'
# Switch to DLL to check for ECharts Lib
path_dll = 'web/assets/dllSelf.09a1636445d39f4f9ec3.js'
path_app = 'web/assets/app.6539b5af.js'


def analyze_file(filepath, label):
    print(f"\n\n========== ANALYZING {label} ==========")
    if not os.path.exists(filepath):
        print(f"Skipping {label}: File {filepath} not found.")
        return

    try:
        with open(filepath, 'rb') as f:
            content = f.read()
        print(f"File size: {len(content)} bytes")
        
        # Check D3 specific
        print(f"\n--- {label}: D3 specific ---")
        for key in [b'd3.geo', b'geoPath', b'geoMercator', b'topojson', b'geojson']:
             if key in content:
                 print(f"Found {key.decode()}")

    except Exception as e:
        print(f"Error reading {label}: {e}")

def analyze_app_map():
    if not os.path.exists(path_app):
        print(f"Skipping APP analysis: {path_app} not found.")
        return

    try:
        with open(path_app, 'rb') as f:
            content = f.read()
            
        # Check D3 usage in APP
        print(f"\n--- APP: D3 Usage ---")
        for key in [b'd3.geo', b'geoPath', b'geoMercator', b'd3.select']:
             if key in content:
                 print(f"Found {key.decode()}")
                 matches = list(re.finditer(key, content))[:3]
                 for m in matches:
                     start = max(0, m.start() - 50)
                     end = min(len(content), m.end() + 100)
                     print(f"   ...{content[start:end].decode('utf-8', errors='replace')}...")

        # Search for .json files (Maps)
        print(f"\n--- APP: JSON Loads ---")
        pattern = b'[\w-]+\.json' 
        matches = list(re.finditer(pattern, content))
        for m in matches:
            # check if it looks like a file path
            start = max(0, m.start() - 20)
            end = min(len(content), m.end() + 10)
            snippet = content[start:end].decode('utf-8', errors='replace')
            if "/" in snippet or "asset" in snippet or "map" in snippet:
                print(f"...{snippet}...")
                
        # Search for Data Binding
        # "node" or "attack" binding
        print(f"\n--- APP: Data Binding ---")
        pattern = b'data\(\[' # data([...
        matches = list(re.finditer(pattern, content))
        if matches:
             print("Found .data([ usage (D3 binding)")

    except Exception as e:
        print(f"Error analyzing app: {e}")

analyze_file(path_dll, "DLL")
# analyze_file(path_app, "APP")
analyze_app_map()
