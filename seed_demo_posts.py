import os
import random
import io
from PIL import Image, ImageDraw, ImageFont
from supabase import create_client, Client
from dotenv import load_dotenv

"""
Production Ready Seed Script
----------------------------
This script requires the following dependencies:
pip install supabase Pillow python-dotenv

Create a .env file in the root of your project with:
SUPABASE_URL=your_project_url
SUPABASE_KEY=your_service_role_key_or_anon_key

This script will:
1. Generate 30 local 1920x1080 images.
2. Generate in-memory Mobile (1280px) and Thumbnail (600px) versions.
3. Upload all versions to the Supabase Storage 'media' bucket.
4. Insert the references securely into the 'posts' table.
5. Automatically skip duplicates based on DB records.
"""

# Load environment variables
load_dotenv()
url: str = os.environ.get("SUPABASE_URL", "")
key: str = os.environ.get("SUPABASE_KEY", "")

BUCKET_NAME = "media"
TABLE_NAME = "posts"

def generate_gradient(width, height, color1, color2):
    base = Image.new('RGB', (width, height), color1)
    top = Image.new('RGB', (width, height), color2)
    mask = Image.new('L', (1, height))
    mask.putdata([int(255 * (y / height)) for y in range(height)])
    mask = mask.resize((width, height))
    base.paste(top, (0, 0), mask)
    return base

def generate_images(count=30, output_dir='input_images'):
    """Generates base images locally if they don't already exist."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    width, height = 1920, 1080
    
    try:
        font = ImageFont.truetype("arial.ttf", 250)
    except IOError:
        font = ImageFont.load_default()

    generated_files = []
    print(f"Verifying {count} local demo images...")
    for i in range(1, count + 1):
        output_path = os.path.join(output_dir, f"post_{i}.jpg")
        generated_files.append(output_path)
        
        if os.path.exists(output_path):
            continue
            
        color1 = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        color2 = (random.randint(0, 255), random.randint(0, 255), random.randint(0, 255))
        img = generate_gradient(width, height, color1, color2)
        
        overlay = Image.new('RGBA', img.size, (0, 0, 0, 0))
        overlay_draw = ImageDraw.Draw(overlay)
        text = f"Post #{i}"
        
        box_w, box_h = 1000, 450
        box_x1 = (width - box_w) // 2
        box_y1 = (height - box_h) // 2
        
        overlay_draw.rounded_rectangle([box_x1, box_y1, box_x1 + box_w, box_y1 + box_h], radius=40, fill=(0, 0, 0, 150))
        img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
        draw = ImageDraw.Draw(img)
        
        try:
            left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
            text_w, text_h = right - left, bottom - top
        except AttributeError:
            text_w, text_h = draw.textsize(text, font=font)
            
        draw.text(((width - text_w) / 2, (height - text_h) / 2 - 20), text, fill="white", font=font)
        img.save(output_path, "JPEG", quality=90)
        
    return generated_files

def resize_image(img, max_width):
    """Proportionally scales an image down to the max_width."""
    ratio = max_width / float(img.size[0])
    if ratio >= 1.0:
        return img.copy()
    new_height = int(float(img.size[1]) * ratio)
    return img.resize((max_width, new_height), Image.Resampling.LANCZOS)

def upload_bytes(supabase: Client, bucket_name: str, file_path: str, img: Image.Image, quality: int):
    """Compresses image to bytes and uploads directly to Supabase storage."""
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG', quality=quality)
    img_byte_arr = img_byte_arr.getvalue()
    
    bucket = supabase.storage.from_(bucket_name)
    try:
        bucket.upload(file_path, img_byte_arr, {"content-type": "image/jpeg"})
    except Exception as e:
        # Ignore conflict errors if the file already exists in the bucket
        if "Duplicate" not in str(e) and "409" not in str(e) and "already exists" not in str(e).lower() and "StatusCode.CONFLICT" not in str(e):
            print(f"    Warning: Upload failed for {file_path}: {e}")
            
    return bucket.get_public_url(file_path)

def main():
    if not url or not key:
        print("==========================================================")
        print("ERROR: SUPABASE_URL and SUPABASE_KEY are not set.")
        print("Please create a .env file with these variables.")
        print("==========================================================")
        return

    supabase: Client = create_client(url, key)
    
    # 1. Generate/verify local raw images
    files = generate_images()
    total_files = len(files)
    
    print("\nStarting upload and database seeding process...")
    
    # 2. Pre-fetch existing database records to confidently skip duplicates
    try:
        existing_data = supabase.table(TABLE_NAME).select("media_raw_url").execute()
        existing_raw_urls = {record["media_raw_url"] for record in existing_data.data}
    except Exception as e:
        print(f"Warning: Could not fetch existing posts. Assuming empty database. ({e})")
        existing_raw_urls = set()

    for i, file_path in enumerate(files, 1):
        print(f"Processing {i}/{total_files}...")
        
        file_name = os.path.basename(file_path)
        
        # Predict the exact public URL to verify against the DB before doing any heavy image processing
        predicted_raw_path = f"raw/{file_name}"
        predicted_raw_url = supabase.storage.from_(BUCKET_NAME).get_public_url(predicted_raw_path)
        
        if predicted_raw_url in existing_raw_urls:
            print(f"  -> Skipping {file_name}: Already indexed in database.")
            continue
            
        try:
            # 3. Create Tiered Image Variations
            with Image.open(file_path) as img:
                img_raw = img
                img_mobile = resize_image(img, 1280) # Medium resolution
                img_thumb = resize_image(img, 600)   # Low resolution thumbnail
                
                # 4. Upload to Storage
                raw_url = upload_bytes(supabase, BUCKET_NAME, predicted_raw_path, img_raw, 90)
                mobile_url = upload_bytes(supabase, BUCKET_NAME, f"mobile/{file_name}", img_mobile, 80)
                thumb_url = upload_bytes(supabase, BUCKET_NAME, f"thumb/{file_name}", img_thumb, 70)
                
                # 5. Commit to Database
                post_data = {
                    "media_raw_url": raw_url,
                    "media_mobile_url": mobile_url,
                    "media_thumb_url": thumb_url,
                    "like_count": random.randint(10, 5000)
                }
                
                supabase.table(TABLE_NAME).insert(post_data).execute()
                print(f"  -> Successfully processed and saved {file_name}")
                
        except Exception as e:
            print(f"  -> Failed to process {file_name}: {e}")

    print("\nFinished seeding all media!")

if __name__ == "__main__":
    main()
