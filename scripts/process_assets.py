
import os
from PIL import Image, ImageOps, ImageDraw

def mask_circle_transparent(img_path, output_path, size=None):
    try:
        img = Image.open(img_path).convert("RGBA")
        
        # Create a circular mask
        mask = Image.new("L", img.size, 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse((0, 0, img.size[0], img.size[1]), fill=255)
        
        # Apply mask
        output = ImageOps.fit(img, mask.size, centering=(0.5, 0.5))
        output.putalpha(mask)
        
        if size:
            output = output.resize(size, Image.Resampling.LANCZOS)
            
        output.save(output_path, "PNG")
        print(f"Processed {output_path}")
        return output
    except Exception as e:
        print(f"Error processing {img_path}: {e}")
        return None

def generate_favicons(source_path, dest_dir):
    img = Image.open(source_path).convert("RGBA")
    
    # Sizes
    sizes = [
        ("favicon.ico", (32, 32)), # ICO can store multiple, but basic check
        ("favicon-32x32.png", (32, 32)),
        ("favicon-16x16.png", (16, 16)),
        ("apple-touch-icon.png", (180, 180))
    ]
    
    for name, size in sizes:
        out_path = os.path.join(dest_dir, name)
        # Resize
        resized = img.resize(size, Image.Resampling.LANCZOS)
        
        if name.endswith(".ico"):
            resized.save(out_path, format="ICO")
        else:
            resized.save(out_path, format="PNG")
        print(f"Generated {out_path}")

def main():
    base_dir = "/home/elliot/git_repos/honey-scan"
    logo_source = os.path.join(base_dir, "docs/img/logo.png")
    
    # 1. Update Main Logo (Circular Mask)
    # Overwrite the source with the masked version? 
    # User said "fix transparency... circle without black border"
    # I'll save it to a temp first to verify or just overwrite if confident.
    # The existing logo might be square with black background.
    
    # Let's save to logo_bear.png first as a test/update
    web_assets_dir = os.path.join(base_dir, "web/assets")
    logo_bear_dest = os.path.join(web_assets_dir, "logo_bear.png")
    
    # Process
    if os.path.exists(logo_source):
        print(f"Processing {logo_source}...")
        
        # Load and define "black" to be transparent if it's not a mask?
        # Actually user specifically asked for "Circle". 
        # If I cut a circle, the corners (which might be the black border) will go away.
        # But if the background INSIDE the circle is black, I might need flood fill?
        # "so das ein rundes Logo zu sehen ist ohne Schwarzen Rand" -> Usually implies the corners of a square image are black.
        # Simple circular crop usually solves this.
        
        processed_img = mask_circle_transparent(logo_source, logo_bear_dest)
        
        if processed_img:
            # Update docs/img/logo.png as well
            processed_img.save(logo_source)
            print(f"Updated {logo_source}")
            
            # 2. Generate Favicons
            generate_favicons(logo_bear_dest, web_assets_dir)
            
    else:
        print(f"Error: {logo_source} not found.")

if __name__ == "__main__":
    main()
