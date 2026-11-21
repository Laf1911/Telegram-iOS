import os
from PIL import Image

def generate_icons():
    root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    source_icon = os.path.join(root_dir, "neogram_icon.png")
    fallback_icon = os.path.join(root_dir, "Telegram", "Telegram-iOS", "DefaultAppIcon.xcassets", "AppIconLLC.appiconset", "Swiftgram.png")
    
    icon_to_use = source_icon if os.path.exists(source_icon) else fallback_icon
    print(f"Using icon source: {icon_to_use}")
    
    if not os.path.exists(icon_to_use):
        print("Error: No source icon found!")
        return
        
    img = Image.open(icon_to_use)
    # Гарантируем отсутствие альфа-канала (Apple AppIcon требует чистый RGB 24-bit)
    if img.mode != "RGB":
        background = Image.new("RGB", img.size, (0, 0, 0))
        if img.mode == "RGBA":
            background.paste(img, mask=img.split()[3])
        else:
            background.paste(img)
        img = background
        
    targets = [
        # Основная иконка приложения
        (os.path.join(root_dir, "Telegram", "Telegram-iOS", "DefaultAppIcon.xcassets", "AppIconLLC.appiconset", "Swiftgram.png"), (1024, 1024)),
        # Альтернативная черная иконка SGBlack
        (os.path.join(root_dir, "Telegram", "Telegram-iOS", "SGBlack.alticon", "SGBlack@2x.png"), (120, 120)),
        (os.path.join(root_dir, "Telegram", "Telegram-iOS", "SGBlack.alticon", "SGBlack@3x.png"), (180, 180)),
        # Watch App
        (os.path.join(root_dir, "Telegram", "Watch", "App", "Assets.xcassets", "AppIcon.appiconset", "Swiftgram.png"), (1024, 1024)),
        (os.path.join(root_dir, "Telegram", "WatchApp", "tgwatch Watch App", "Assets.xcassets", "AppIcon.appiconset", "Swiftgram.png"), (1024, 1024))
    ]
    
    for path, size in targets:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        # Сохраняем в RGB формате без альфа-канала
        resized.convert("RGB").save(path, "PNG")
        print(f"Generated {size[0]}x{size[1]} -> {path}")

if __name__ == "__main__":
    generate_icons()
