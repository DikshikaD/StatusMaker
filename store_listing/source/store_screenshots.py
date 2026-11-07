"""Builds the five Play Store screenshots (1080x1920), each in its own style.

1. Put raw phone screenshots in store_listing/screenshots_raw/en/:
     01_home.png  02_editor.png  03_create.png  04_hindi.png  04_dark.png
     05_share.png
2. Run from the repo root:  python3 store_listing/source/store_screenshots.py
3. Upload store_listing/PLAY_STORE_UPLOAD/screenshots/*.png in order.
"""
import base64
import io
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import C1, C2, FONTS, ROOT, glyph, page, render_html, svg  # noqa: E402

RAW = os.path.join(ROOT, "store_listing", "screenshots_raw", "en")
OUT = os.path.join(ROOT, "store_listing", "PLAY_STORE_UPLOAD", "screenshots")
W, H = 1080, 1920

BASE_CSS = f"""
  *{{box-sizing:border-box}}
  .cap{{position:absolute;left:70px;right:70px;font-family:Poppins,Mukta,sans-serif;
    font-weight:700;line-height:1.1;letter-spacing:-1px}}
  .sub{{font-family:Poppins,Mukta,sans-serif;font-weight:500;font-size:36px;
    letter-spacing:0;line-height:1.3;margin-top:22px}}
  .phone{{position:absolute;padding:16px;background:#121418;border-radius:66px}}
  .phone img{{display:block;border-radius:52px}}
  .pill{{display:inline-block;padding:14px 30px;border-radius:999px;font-weight:600;
    font-size:30px;margin:0 8px 14px 0}}
"""


def shot(name, width):
    """Raw screenshot as a data URI, scaled to `width` px; returns (uri, height)."""
    img = Image.open(os.path.join(RAW, name)).convert("RGB")
    h = round(img.height * width / img.width)
    buf = io.BytesIO()
    img.resize((width, h), Image.LANCZOS).save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode(), h


def phone(name, width, left, top, rot=0, shadow="0 40px 80px rgba(0,0,0,.35)"):
    uri, h = shot(name, width)
    return (f'<div class="phone" style="left:{left}px;top:{top}px;transform:rotate({rot}deg);'
            f'box-shadow:{shadow}"><img src="{uri}" style="width:{width}px;height:{h}px"></div>')


def logo(size):
    return svg(size, size, f'<rect width="{size}" height="{size}" rx="{size * .24}" fill="url(#lg)"/>'
               f'<defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" '
               f'stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/></linearGradient></defs>'
               + glyph(size / 2, size / 2, size * .3))


def render(n, body):
    dest = os.path.join(OUT, f"{n:02d}.png")
    html = page(f"<style>{BASE_CSS}</style>{body}", W, H, FONTS)
    render_html(html, W, H, dest)
    Image.open(dest).convert("RGB").save(dest, optimize=True)
    print("made", dest)


def s1_hero():
    """Coral gradient, logo + headline on top, phone rising from the bottom."""
    render(1, f"""
    <div style="position:absolute;inset:0;background:linear-gradient(160deg,{C1},{C2})"></div>
    <div style="position:absolute;left:70px;top:90px;display:flex;align-items:center;gap:20px;
      color:#fff;font:600 38px Poppins">{logo(76)}<span>Status Maker</span></div>
    <div class="cap" style="top:210px;color:#fff;font-size:88px">Beautiful statuses<br>in seconds
      <div class="sub" style="opacity:.92">Good Morning, festivals, birthdays &amp; more</div></div>
    {phone('01_home.png', 760, 144, 640)}""")


def s2_dark():
    """Dark stage with a coral glow behind the phone."""
    render(2, f"""
    <div style="position:absolute;inset:0;background:#15171c"></div>
    <div style="position:absolute;left:140px;top:560px;width:800px;height:1100px;border-radius:50%;
      background:radial-gradient(closest-side,rgba(239,103,69,.55),rgba(239,103,69,0));filter:blur(30px)"></div>
    <div class="cap" style="top:110px;color:#fff;font-size:84px">Make it <span style="color:#FF8A5C">yours</span>
      <div class="sub" style="color:#b9bcc6">Edit text, fonts, colours, photos &amp; stickers</div></div>
    {phone('02_editor.png', 640, 204, 420, shadow='0 40px 120px rgba(239,103,69,.35)')}""")


def s3_tilted():
    """Warm cream background, tilted phone, category pills."""
    pills = "".join(
        f'<span class="pill" style="background:{bg};color:{fg}">{t}</span>'
        for t, bg, fg in [("Good Morning", "#FFE3D6", "#B83A1E"), ("Festivals", "#FFF0C7", "#8A5A00"),
                          ("Birthday", "#FBDDE8", "#A3214F"), ("Love", "#FFD9D9", "#B3262E"),
                          ("Devotional", "#E6E1FF", "#4B3AA8"), ("Motivation", "#D9F2E6", "#1F6B47")])
    render(3, f"""
    <div style="position:absolute;inset:0;background:#FFF6EF"></div>
    <div style="position:absolute;right:-250px;top:-250px;width:560px;height:560px;border-radius:50%;
      background:linear-gradient(160deg,{C1},{C2});opacity:.9"></div>
    <div class="cap" style="top:110px;color:#1E1F24;font-size:84px;right:260px">Ready-made<br>templates</div>
    <div style="position:absolute;left:70px;right:70px;top:420px;font-family:Poppins">{pills}</div>
    {phone('03_create.png', 690, 200, 720, rot=-4, shadow='0 50px 90px rgba(120,50,20,.28)')}""")


def s4_two_phones():
    """Two overlapping phones: Hindi light mode and dark mode."""
    render(4, f"""
    <div style="position:absolute;inset:0;background:linear-gradient(180deg,#FFE9DF,#FFD3C2)"></div>
    <div class="cap" style="top:110px;color:#1E1F24;font-size:84px;text-align:center">हिंदी &amp; English
      <div class="sub" style="color:#5b4038">Light and dark mode</div></div>
    {phone('04_dark.png', 600, 420, 560, rot=6, shadow='0 40px 80px rgba(60,20,10,.35)')}
    {phone('04_hindi.png', 600, 40, 520, rot=-6, shadow='0 40px 80px rgba(60,20,10,.35)')}""")


def s5_share():
    """Caption at the bottom, phone at the top bleeding off the edge."""
    render(5, f"""
    <div style="position:absolute;inset:0;background:linear-gradient(200deg,#FF7A59,#D93A5A)"></div>
    {phone('05_share.png', 760, 144, -220, shadow='0 40px 90px rgba(80,10,20,.4)')}
    <div style="position:absolute;left:0;right:0;bottom:0;height:520px;
      background:linear-gradient(180deg,rgba(217,58,90,0),#C93354 45%)"></div>
    <div class="cap" style="bottom:130px;color:#fff;font-size:88px;text-align:center">Like, customise<br>&amp; share
      <div class="sub" style="opacity:.92">Send it to friends and family in one tap</div></div>""")


def main():
    os.makedirs(OUT, exist_ok=True)
    for f in (s1_hero, s2_dark, s3_tilted, s4_two_phones, s5_share):
        f()


if __name__ == "__main__":
    main()
