"""Turns raw phone screenshots into Play Store screenshots (1080x1920, 9:16).

Raw phone screenshots (e.g. 1080x2340) are taller than Play's 2:1 limit, so
each one is placed in a phone frame under a caption.

1. Put raw screenshots in store_listing/screenshots_raw/en/ (and /hi/ for the
   Hindi listing), named with the prefixes below, e.g. 01_home.png.
2. Run from the repo root:  python3 store_listing/source/frame_screenshots.py
3. Upload store_listing/graphics/screenshots/<lang>/*.png in order.
"""
import base64
import glob
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import C1, C2, FONTS, ROOT, page, render_html  # noqa: E402

RAW = os.path.join(ROOT, "store_listing", "screenshots_raw")
OUT = os.path.join(ROOT, "store_listing", "graphics", "screenshots")

CAPTIONS = {
    "01": {"en": "Fresh statuses<br>every day", "hi": "रोज़ नए<br>स्टेटस"},
    "02": {"en": "Ready-made templates<br>for every moment", "hi": "हर मौके के लिए<br>तैयार टेम्पलेट"},
    "03": {"en": "Add your photo,<br>name & quote", "hi": "अपनी फ़ोटो, नाम<br>और कोट जोड़ें"},
    "04": {"en": "Morning, festivals,<br>birthdays & more", "hi": "सुप्रभात, त्योहार,<br>जन्मदिन और भी"},
    "05": {"en": "Share it<br>in one tap", "hi": "एक टैप में<br>शेयर करें"},
    "06": {"en": "Hindi & English,<br>light & dark", "hi": "हिंदी और English,<br>लाइट और डार्क"},
    "07": {"en": "Like, save &<br>customise", "hi": "लाइक, सेव और<br>कस्टमाइज़ करें"},
    "08": {"en": "Safe community<br>you control", "hi": "सुरक्षित कम्युनिटी,<br>आपके कंट्रोल में"},
}

W, H = 1080, 1920


def frame(src, caption, dest):
    shot = Image.open(src).convert("RGB")
    # Phone screen area: fit inside 760x1460, keep aspect.
    sw, sh = shot.size
    scale = min(760 / sw, 1460 / sh)
    pw, ph = round(sw * scale), round(sh * scale)
    tmp = dest + ".src.png"
    shot.resize((pw, ph), Image.LANCZOS).save(tmp)
    with open(tmp, "rb") as f:
        data = base64.b64encode(f.read()).decode()
    os.unlink(tmp)
    body = f"""<style>
      .bg{{position:absolute;inset:0;background:linear-gradient(150deg,{C1},{C2})}}
      .cap{{position:absolute;top:96px;left:60px;right:60px;text-align:center;color:#fff;
        font-family:Poppins,Mukta,sans-serif;font-weight:700;font-size:74px;line-height:1.12}}
      .phone{{position:absolute;left:50%;top:360px;transform:translateX(-50%);
        padding:18px;background:#14161a;border-radius:70px;box-shadow:0 30px 70px rgba(80,20,5,.45)}}
      .phone img{{display:block;width:{pw}px;height:{ph}px;border-radius:54px}}
    </style>
    <div class="bg"></div><div class="cap">{caption}</div>
    <div class="phone"><img src="data:image/png;base64,{data}"></div>"""
    render_html(page(body, W, H, FONTS), W, H, dest)
    Image.open(dest).convert("RGB").save(dest, optimize=True)


def main():
    made = 0
    for lang in ("en", "hi"):
        files = sorted(glob.glob(os.path.join(RAW, lang, "*.png")))
        os.makedirs(os.path.join(OUT, lang), exist_ok=True)
        for src in files:
            key = os.path.basename(src)[:2]
            if key not in CAPTIONS:
                print(f"skip {src}: name must start with 01..08")
                continue
            dest = os.path.join(OUT, lang, f"{key}.png")
            frame(src, CAPTIONS[key][lang], dest)
            made += 1
            print("made", dest)
    print(f"{made} screenshots")


if __name__ == "__main__":
    main()
