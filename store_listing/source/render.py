"""Renders every Play Store graphic and Android launcher icon from SVG/HTML.

Run from the repo root:  python3 store_listing/source/render.py
Needs Google Chrome (headless) and Pillow.
"""
import math
import os
import subprocess
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "store_listing", "graphics")
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Brand: the app accent (#EF6745) deepened at one end so white reads clearly.
C1, C2 = "#FF8A5C", "#E2492A"


def sparkle(cx, cy, r, waist=0.16):
    """Four-point sparkle centred at (cx, cy) with tip radius r."""
    w = r * waist
    return (f"M{cx},{cy - r} C{cx + w},{cy - w} {cx + w},{cy - w} {cx + r},{cy} "
            f"C{cx + w},{cy + w} {cx + w},{cy + w} {cx},{cy + r} "
            f"C{cx - w},{cy + w} {cx - w},{cy + w} {cx - r},{cy} "
            f"C{cx - w},{cy - w} {cx - w},{cy - w} {cx},{cy - r}Z")


def glyph(cx, cy, s, color="#fff"):
    """The mark: a segmented status ring around a sparkle. s = ring radius."""
    stroke = s * 0.17
    circ = 2 * math.pi * s
    gap = circ * 0.075
    seg = circ / 3 - gap
    return f"""
    <circle cx="{cx}" cy="{cy}" r="{s}" fill="none" stroke="{color}"
      stroke-width="{stroke}" stroke-linecap="round"
      stroke-dasharray="{seg:.2f} {gap:.2f}"
      transform="rotate(-62 {cx} {cy})"/>
    <path d="{sparkle(cx, cy, s * 0.60, 0.21)}" fill="{color}"/>
    <path d="{sparkle(cx + s * 0.50, cy - s * 0.50, s * 0.19, 0.24)}" fill="{color}"/>
    """


def gradient_bg(w, h):
    return f"""
    <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>
    </linearGradient></defs>
    <rect width="{w}" height="{h}" fill="url(#g)"/>"""


def render_html(html, w, h, path, transparent=False):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(html)
        src = f.name
    args = [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
            f"--window-size={w},{h}", f"--screenshot={path}",
            "--force-device-scale-factor=1", "--virtual-time-budget=8000"]
    if transparent:
        args.append("--default-background-color=00000000")
    subprocess.run(args + [f"file://{src}"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.unlink(src)
    img = Image.open(path)
    if img.size != (w, h):
        img = img.crop((0, 0, w, h))
    img.save(path)


def page(body, w, h, extra_head=""):
    return f"""<!doctype html><html><head><meta charset="utf-8">{extra_head}
    <style>html,body{{margin:0;padding:0;width:{w}px;height:{h}px;overflow:hidden;
    background:transparent}}</style></head><body>{body}</body></html>"""


def svg(w, h, inner):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{inner}</svg>'


# ---------------------------------------------------------------------------
# Icons
# ---------------------------------------------------------------------------
def icons():
    big = 1024
    # Play Store icon: full-bleed square, Play applies its own rounded mask.
    store = svg(big, big, gradient_bg(big, big) + glyph(512, 512, 300))
    tmp = os.path.join(OUT, "_store_1024.png")
    render_html(page(store, big, big), big, big, tmp)
    Image.open(tmp).convert("RGBA").resize((512, 512), Image.LANCZOS).save(
        os.path.join(OUT, "app_icon_512.png"), optimize=True)
    os.rename(tmp, os.path.join(OUT, "logo_1024.png"))

    # Adaptive icon layers (108dp canvas; glyph kept inside the 66dp safe zone).
    fg = svg(big, big, glyph(512, 512, 262))
    bg = svg(big, big, gradient_bg(big, big))
    mono = svg(big, big, glyph(512, 512, 262, "#000"))
    layers = {}
    for name, s in (("fg", fg), ("bg", bg), ("mono", mono)):
        p = os.path.join(OUT, f"_layer_{name}.png")
        render_html(page(s, big, big), big, big, p, transparent=(name != "bg"))
        layers[name] = Image.open(p).convert("RGBA")
        os.unlink(p)

    # Legacy launcher icon (API 24-25): rounded square with the glyph.
    legacy_svg = svg(big, big, f"""
      <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>
      </linearGradient><clipPath id="c"><rect x="64" y="64" width="896" height="896" rx="210"/></clipPath></defs>
      <g clip-path="url(#c)"><rect width="{big}" height="{big}" fill="url(#g)"/></g>
      {glyph(512, 512, 290)}""")
    round_svg = svg(big, big, f"""
      <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>
      </linearGradient></defs>
      <circle cx="512" cy="512" r="448" fill="url(#g)"/>{glyph(512, 512, 270)}""")
    legacy = {}
    for name, s in (("legacy", legacy_svg), ("round", round_svg)):
        p = os.path.join(OUT, f"_{name}.png")
        render_html(page(s, big, big), big, big, p, transparent=True)
        legacy[name] = Image.open(p).convert("RGBA")
        os.unlink(p)

    densities = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}
    for d, k in densities.items():
        folder = os.path.join(RES, f"mipmap-{d}")
        os.makedirs(folder, exist_ok=True)
        launcher = round(48 * k)
        legacy["legacy"].resize((launcher, launcher), Image.LANCZOS).save(
            os.path.join(folder, "ic_launcher.png"), optimize=True)
        legacy["round"].resize((launcher, launcher), Image.LANCZOS).save(
            os.path.join(folder, "ic_launcher_round.png"), optimize=True)
        layer = round(108 * k)
        for name, img in layers.items():
            img.resize((layer, layer), Image.LANCZOS).save(
                os.path.join(folder, f"ic_launcher_{'foreground' if name == 'fg' else 'background' if name == 'bg' else 'monochrome'}.png"),
                optimize=True)

    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
"""
    for n in ("ic_launcher.xml", "ic_launcher_round.xml"):
        with open(os.path.join(anydpi, n), "w") as f:
            f.write(xml)


# ---------------------------------------------------------------------------
# Notification icon (white silhouette, Android tints it)
# ---------------------------------------------------------------------------
def notification_icon():
    big = 384
    s = svg(big, big, glyph(192, 192, 150))
    p = os.path.join(OUT, "_notif.png")
    render_html(page(s, big, big), big, big, p, transparent=True)
    img = Image.open(p).convert("RGBA")
    os.unlink(p)
    for d, k in {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}.items():
        folder = os.path.join(RES, f"drawable-{d}")
        os.makedirs(folder, exist_ok=True)
        n = round(24 * k)
        img.resize((n, n), Image.LANCZOS).save(
            os.path.join(folder, "ic_notification.png"), optimize=True)


# ---------------------------------------------------------------------------
# Feature graphic 1024x500
# ---------------------------------------------------------------------------
FONTS = ('<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@500;600;700'
         '&family=Playfair+Display:wght@700&family=Tiro+Devanagari+Hindi&family=Mukta:wght@700'
         '&display=block" rel="stylesheet">')


def card(x, y, rot, bg, title, sub, title_font, title_size, color="#fff", deco=""):
    return f"""<div class="card" style="left:{x}px;top:{y}px;transform:rotate({rot}deg);background:{bg}">
      {deco}<div class="t" style="font-family:{title_font};font-size:{title_size}px;color:{color}">{title}</div>
      <div class="s" style="color:{color}">{sub}</div></div>"""


def feature_graphic():
    w, h = 1024, 500
    logo = svg(120, 120, f"""<rect width="120" height="120" rx="30" fill="#fff"/>
      <defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/></linearGradient></defs>
      <g>{glyph(60, 60, 36, "url(#lg)").replace('stroke="url(#lg)"', 'stroke="url(#lg)"')}</g>""")
    sun = '<div class="sun"></div>'
    body = f"""
    <div class="bg"></div>
    <div class="ring r1"></div><div class="ring r2"></div>
    <div class="left">
      <div class="brand">{logo}<span>Status Maker</span></div>
      <h1>Beautiful statuses<br>in seconds</h1>
      <p class="hi">हिंदी और English में स्टेटस बनाएँ</p>
      <div class="chips"><span>Good Morning</span><span>Festivals</span><span>Birthday</span><span>Quotes</span></div>
    </div>
    {card(594, 98, -7, "linear-gradient(160deg,#FFD27A,#FF9A5A 60%,#F0613E)", "सुप्रभात", "आपका दिन शुभ हो", "'Tiro Devanagari Hindi',serif", 34, "#5a2306", sun)}
    {card(722, 62, 2, "linear-gradient(160deg,#3B1E54,#7A2E6E 55%,#E0563F)", "शुभ<br>दीपावली", "रोशनी और खुशियाँ", "'Mukta',sans-serif", 30, "#FFE3A3", '<div class="diya">🪔</div>')}
    {card(846, 110, 9, "linear-gradient(160deg,#FFE4EC,#FFB3C7)", "Happy<br>Birthday", "Wishing you joy", "'Playfair Display',serif", 26, "#8A1F45", '<div class="cake">🎂</div>')}
    """
    css = f"""<style>
    *{{box-sizing:border-box}}
    .bg{{position:absolute;inset:0;background:linear-gradient(120deg,{C1} 0%,#F06A44 45%,{C2} 100%)}}
    .ring{{position:absolute;border-radius:50%;border:2px solid rgba(255,255,255,.18)}}
    .r1{{width:520px;height:520px;left:520px;top:-60px}}
    .r2{{width:300px;height:300px;left:-90px;top:300px}}
    .left{{position:absolute;left:64px;top:62px;width:520px;color:#fff;font-family:Poppins,sans-serif}}
    .brand{{display:flex;align-items:center;gap:16px;font-weight:600;font-size:30px}}
    .brand svg{{width:68px;height:68px;filter:drop-shadow(0 6px 14px rgba(120,30,10,.25))}}
    h1{{margin:30px 0 0;font-size:50px;line-height:1.08;font-weight:700;letter-spacing:-.5px}}
    .hi{{margin:16px 0 0;font-family:Mukta,sans-serif;font-weight:700;font-size:25px;opacity:.95}}
    .chips{{display:flex;gap:10px;margin-top:26px;flex-wrap:wrap}}
    .chips span{{background:rgba(255,255,255,.2);border:1.5px solid rgba(255,255,255,.45);padding:7px 15px;
      border-radius:999px;font-size:16px;font-weight:500}}
    .card{{position:absolute;width:150px;height:268px;border-radius:20px;padding:18px 10px;display:flex;
      flex-direction:column;justify-content:center;align-items:center;text-align:center;overflow:hidden;
      box-shadow:0 18px 40px rgba(90,20,5,.35);border:4px solid rgba(255,255,255,.9)}}
    .t{{line-height:1.15;font-weight:700}} .s{{margin-top:8px;font-family:Mukta,Poppins,sans-serif;font-size:13px;opacity:.85}}
    .sun{{position:absolute;width:92px;height:92px;border-radius:50%;background:rgba(255,255,255,.55);top:26px;left:29px}}
    .diya{{font-size:34px;margin-bottom:6px}} .cake{{font-size:36px;margin-bottom:6px}}
    </style>"""
    path = os.path.join(OUT, "feature_graphic_1024x500.png")
    render_html(page(css + body, w, h, FONTS), w, h, path)
    Image.open(path).convert("RGB").save(path, optimize=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    icons()
    notification_icon()
    feature_graphic()
    print("done")
