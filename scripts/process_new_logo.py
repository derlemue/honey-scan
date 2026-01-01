
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
    
    # Convert to RGBA for transparency
    img = img.convert("RGBA")
    
    # Create circular mask
    size = img.size
    # Assume square image or crop to square
    min_dim = min(size)
    
    # Create a new square image with transparent background
    square_img = Image.new("RGBA", (min_dim, min_dim), (0, 0, 0, 0))
    
    # Center crop the original if not square (just in case)
    left = (size[0] - min_dim) // 2
    top = (size[1] - min_dim) // 2
    right = (size[0] + min_dim) // 2
    bottom = (size[1] + min_dim) // 2
    
    cropped_content = img.crop((left, top, right, bottom))
    
    # Create mask
    mask = Image.new("L", (min_dim, min_dim), 0)
    from PIL import ImageDraw
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, min_dim, min_dim), fill=255)
    
    # Apply mask
    square_img.paste(cropped_content, (0, 0), mask)
    img = square_img
    
    # Trim excess transparent space if any (optional, but requested "symmetrical spacing")
    # Actually, a perfect circle in a square box IS symmetrical.
    # The user complained about "black edge". The mask fixes that.
    # "Abstand oben und unten so an das dieser symetrisch ist" -> The square crop handles this if the logo is centered.
    
    for relative_path, size in DESTINATIONS:
        full_path = os.path.join(REPO_ROOT, relative_path)
        print(f"Generating {full_path} ({size})...")
        
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
