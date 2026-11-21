#!/usr/bin/env python3
import json
import os
import re

def main():
    api_id = os.environ.get("CUSTOM_API_ID", "").strip()
    api_hash = os.environ.get("CUSTOM_API_HASH", "").strip()
    if not api_id or not api_hash:
        print("No CUSTOM_API_ID or CUSTOM_API_HASH provided, keeping default values.")
        return

    # 1. build-system/appstore-configuration.json
    try:
        cfg_path = "build-system/appstore-configuration.json"
        if os.path.exists(cfg_path):
            with open(cfg_path, "r", encoding="utf-8") as f:
                d = json.load(f)
            d["api_id"] = str(api_id)
            d["api_hash"] = str(api_hash)
            with open(cfg_path, "w", encoding="utf-8") as f:
                json.dump(d, f, indent=4)
            print("Injected credentials into", cfg_path)
    except Exception as e:
        print("Error updating appstore-configuration.json:", e)

    # 2. Config xcconfig files
    for path in ["Telegram/Telegram-iOS/Config-AppStoreLLC.xcconfig", "Telegram/Telegram-iOS/Config-Fork.xcconfig"]:
        try:
            if os.path.exists(path):
                with open(path, "r", encoding="utf-8") as f:
                    c = f.read()
                c = re.sub(r"APP_CONFIG_API_ID=\d+", f"APP_CONFIG_API_ID={api_id}", c)
                c = re.sub(r'APP_CONFIG_API_HASH=\\"[^\\]*\\"', f'APP_CONFIG_API_HASH=\\"{api_hash}\\"', c)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(c)
                print("Injected credentials into", path)
        except Exception as e:
            print(f"Error updating {path}:", e)

    # 3. variables.bzl
    try:
        bzl_path = "build-system/example-configuration/variables.bzl"
        if os.path.exists(bzl_path):
            with open(bzl_path, "r", encoding="utf-8") as f:
                c = f.read()
            c = re.sub(r'telegram_api_id\s*=\s*"[^"]*"', f'telegram_api_id = "{api_id}"', c)
            c = re.sub(r'telegram_api_hash\s*=\s*"[^"]*"', f'telegram_api_hash = "{api_hash}"', c)
            with open(bzl_path, "w", encoding="utf-8") as f:
                f.write(c)
            print("Injected credentials into", bzl_path)
    except Exception as e:
        print("Error updating variables.bzl:", e)

if __name__ == "__main__":
    main()
