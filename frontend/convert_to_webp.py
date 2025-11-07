#!/usr/bin/env python3
"""
PNG to WebP Converter
Converts all PNG images in the assets/images directory to WebP format
"""

import os
from pathlib import Path
from PIL import Image

def convert_png_to_webp(png_path, quality=85):
    """
    Convert a PNG file to WebP format

    Args:
        png_path: Path to the PNG file
        quality: WebP quality (0-100, default 85)

    Returns:
        tuple: (webp_path, original_size, new_size)
    """
    try:
        # Open the PNG image
        img = Image.open(png_path)

        # Get original file size
        original_size = os.path.getsize(png_path)

        # Create WebP filename
        webp_path = png_path.with_suffix('.webp')

        # Convert and save as WebP
        img.save(webp_path, 'webp', quality=quality, method=6)

        # Get new file size
        new_size = os.path.getsize(webp_path)

        # Calculate reduction percentage
        reduction = ((original_size - new_size) / original_size) * 100

        return webp_path, original_size, new_size, reduction

    except Exception as e:
        print(f"Error converting {png_path}: {e}")
        return None, 0, 0, 0

def main():
    # Get the assets/images directory
    base_dir = Path(__file__).parent / 'assets' / 'images'

    if not base_dir.exists():
        print(f"Error: Directory {base_dir} does not exist")
        return

    # Find all PNG files
    png_files = list(base_dir.rglob('*.png'))

    if not png_files:
        print("No PNG files found")
        return

    print(f"Found {len(png_files)} PNG files")
    print("=" * 80)

    total_original = 0
    total_new = 0
    converted_count = 0

    for png_file in png_files:
        result = convert_png_to_webp(png_file)

        if result[0]:
            webp_path, original_size, new_size, reduction = result
            total_original += original_size
            total_new += new_size
            converted_count += 1

            # Print conversion info
            print(f"✓ {png_file.relative_to(base_dir)}")
            print(f"  {original_size/1024:.1f} KB → {new_size/1024:.1f} KB ({reduction:.1f}% reduction)")

    print("=" * 80)
    print(f"\nConversion complete!")
    print(f"Converted: {converted_count}/{len(png_files)} files")
    print(f"Total size: {total_original/1024:.1f} KB → {total_new/1024:.1f} KB")

    if total_original > 0:
        total_reduction = ((total_original - total_new) / total_original) * 100
        print(f"Total reduction: {total_reduction:.1f}%")
        print(f"Saved: {(total_original - total_new)/1024:.1f} KB")

    print("\nNote: Original PNG files are kept. You can delete them after verifying WebP files work correctly.")

if __name__ == '__main__':
    main()
