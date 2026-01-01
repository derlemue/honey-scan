
from PIL import Image, ImageDraw, ImageOps
import os

SOURCE_LOGO = "/home/elliot/git_repos/honey-scan/web/assets/logo_bear.png"
ASSETS_DIR = "/home/elliot/git_repos/honey-scan/web/assets"
DOCS_IMG_DIR = "/home/elliot/git_repos/honey-scan/docs/img"

def make_circle(img):
    # Ensure source is RGBA
    img = img.convert("RGBA")
    
    # Create the mask
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0) + img.size, fill=255)
    
    
    # Actually, simpler:
    # Create a new blank RGBA image
    final = Image.new("RGBA", output.size, (0, 0, 0, 0))
    # Paste the output image using the circular mask
    final.paste(output, (0, 0), mask)
    
    return final

def main():
    if not os.path.exists(SOURCE_LOGO):
        print(f"Error: {SOURCE_LOGO} not found.")
        return

    print(f"Processing {SOURCE_LOGO}...")
    img = Image.open(SOURCE_LOGO)
    
    # Create circular version
    circle_img = make_circle(img)
    
    # Save standard favicons
    print("Saving favicons...")
    circle_img.resize((16, 16), Image.Resampling.LANCZOS).save(os.path.join(ASSETS_DIR, "favicon-16x16.png"))
    circle_img.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(ASSETS_DIR, "favicon-32x32.png"))
    circle_img.resize((180, 180), Image.Resampling.LANCZOS).save(os.path.join(ASSETS_DIR, "apple-touch-icon.png"))
    
    # Save .ico (multi-size)
    icon_sizes = []
    for s in [(16,16), (32,32), (48,48), (64,64)]:
         icon_sizes.append(circle_img.resize(s, Image.Resampling.LANCZOS))
    
    icon_sizes[0].save(os.path.join(ASSETS_DIR, "favicon.ico"), format='ICO', sizes=[(i.width, i.height) for i in icon_sizes], append_images=icon_sizes[1:])
    
    # Save Main Docs Logo
    print("Saving docs logo...")
    if not os.path.exists(DOCS_IMG_DIR):
        os.makedirs(DOCS_IMG_DIR)
    
    circle_img.save(os.path.join(DOCS_IMG_DIR, "logo.png"))

    print("Assets generated successfully.")

if __name__ == "__main__":
    main()
