
import os
from PIL import Image

SOURCE_IMAGE = "/home/elliot/.gemini/antigravity/brain/021eb22b-b822-4155-acc8-771281f28870/uploaded_image_1767271456323.jpg"
REPO_ROOT = "/home/elliot/git_repos/honey-scan"

DESTINATIONS = [
    # Main Logos
    ("docs/img/logo.png", (500, 500)), 
    ("web/assets/logo_bear.png", (500, 500)), # Replacing current web logo
    
    # Favicons (Web)
    ("web/assets/favicon-16x16.png", (16, 16)),
    ("web/assets/favicon-32x32.png", (32, 32)),
    ("web/assets/apple-touch-icon.png", (180, 180)),
    
    # Favicons (Feed)
    ("feed/favicon-16x16.png", (16, 16)),
    ("feed/favicon-32x32.png", (32, 32)),
    ("feed/apple-touch-icon.png", (180, 180)),
]

def main():
    print(f"Processing {SOURCE_IMAGE}...")
    try:
        img = Image.open(SOURCE_IMAGE)
    except Exception as e:
        print(f"Error opening image: {e}")
        return

    # Convert to RGB (in case of CMYK etc, though it is JPEG)
    img = img.convert("RGB")
    
    # Create circular mask
    # Assuming the important content is centered and circular within the square image
    # We will create an alpha channel (mask) that is a white circle on black
    mask = Image.new("L", img.size, 0)
    from PIL import ImageDraw
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0) + img.size, fill=255)
    
    # Add alpha channel to image
    img.putalpha(mask)
    
    for relative_path, size in DESTINATIONS:
        full_path = os.path.join(REPO_ROOT, relative_path)
        print(f"Generating {full_path} ({size})...")
        
        # Resize with LANCZOS (high quality)
        resized = img.resize(size, Image.LANCZOS)
        
        # Ensure dir exists
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
        resized.save(full_path, "PNG")
        
    # Generate ICO
    # web/assets/favicon.ico
    # feed/favicon.ico
    ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64)]
    ico_destinations = [
        "web/assets/favicon.ico",
        "feed/favicon.ico"
    ]
    
    print("Generating ICO files...")
    img.save(os.path.join(REPO_ROOT, "web/assets/favicon.ico"), format='ICO', sizes=ico_sizes)
    img.save(os.path.join(REPO_ROOT, "feed/favicon.ico"), format='ICO', sizes=ico_sizes)
    
    print("Done.")

if __name__ == "__main__":
    main()
