from PIL import Image, ImageDraw, ImageFont
import os

# Configuration
WIDTH = 1024
HEIGHT = 1024
COLS = 13
ROWS = 4
BG_COLOR = (255, 255, 255, 255) # White
BORDER_COLOR = (50, 50, 50, 255) # Dark Grey
TEXT_BLACK = (0, 0, 0, 255)
TEXT_RED = (200, 0, 0, 255)

# Setup
img = Image.new('RGBA', (WIDTH, HEIGHT), (0,0,0,0)) # Transparent base
draw = ImageDraw.Draw(img)

# Suits mapping matches CardView.lua
# Row 0: Spades (s=3) -> Black
# Row 1: Clubs (s=2) -> Black
# Row 2: Hearts (s=0) -> Red
# Row 3: Diamonds (s=1) -> Red
suits_config = [
    (0, "♠", TEXT_BLACK), # Spades
    (1, "♣", TEXT_BLACK), # Clubs
    (2, "♥", TEXT_RED),   # Hearts
    (3, "♦", TEXT_RED)    # Diamonds
]

ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

# Fonts
try:
    # Try fonts known to support Card Suits on macOS
    font_candidates = [
        "/System/Library/Fonts/Apple Symbols.ttf",  # Best for symbols
        "/System/Library/Fonts/Menlo.ttc",          # Good fallback
        "/Library/Fonts/Arial.ttf"
    ]
    
    selected_font = None
    for f in font_candidates:
        if os.path.exists(f):
            selected_font = f
            print(f"Using font: {f}")
            break
            
    if not selected_font:
        raise Exception("No suitable font found")
    
    # Use selected font for logic
    corner_font = ImageFont.truetype(selected_font, 30)
    center_font = ImageFont.truetype(selected_font, 70)
    
except Exception as e:
    print(f"Warning: Falling back to default font (symbols may fail). {e}")
    corner_font = ImageFont.load_default()
    center_font = corner_font

for r_idx, symbol, color in suits_config:
    row_y = int(r_idx * HEIGHT / ROWS)
    row_h = int((r_idx + 1) * HEIGHT / ROWS) - row_y
    
    for c_idx, rank in enumerate(ranks):
        col_x = int(c_idx * WIDTH / COLS)
        col_w = int((c_idx + 1) * WIDTH / COLS) - col_x
        
        # Define Card Rect (with margin)
        # Lua expects content at col_x. We fill the cell.
        # But we leave a 1px border transparent to avoid bleeding?
        # No, Lua logic 'col * width' lands exactly on edge.
        # Best to have edge be border.
        
        rect = [col_x, row_y, col_x + col_w - 1, row_y + row_h - 1]
        
        # Fill Card
        draw.rectangle(rect, fill=BG_COLOR, outline=BORDER_COLOR, width=2)
        
        # Corner Text (Top Left)
        draw.text((col_x + 5, row_y + 5), f"{rank}\n{symbol}", font=corner_font, fill=color)
        
        # Center Symbol
        bbox = draw.textbbox((0, 0), symbol, font=center_font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        
        cx = col_x + col_w / 2
        cy = row_y + row_h / 2
        
        draw.text((cx - w/2, cy - h/2), symbol, font=center_font, fill=color)

# Ensure output directory exists
os.makedirs("content/images", exist_ok=True)
img.save("content/images/cards_sheet.png")
print("Generated content/images/cards_sheet.png")
