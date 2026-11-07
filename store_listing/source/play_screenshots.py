"""Play Store screenshots (1080x1920) and feature graphic (1024x500).

Style: light warm background, coral eyebrow, big headline with one highlighted
phrase, the real app screen in a phone, one part of the screen "lifted" out as
an elevated card, and floating callout chips.

Raw phone screenshots (1280x2856) live in store_listing/screenshots_raw/en/.
Run from the repo root:  python3 store_listing/source/play_screenshots.py
"""
import base64
import io
import os
import shutil
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import C1, C2, FONTS, ROOT, glyph, page, render_html, svg  # noqa: E402

RAW = os.path.join(ROOT, "store_listing", "screenshots_raw", "en")
UPLOAD = os.path.join(ROOT, "store_listing", "PLAY_STORE_UPLOAD")
OUT = os.path.join(UPLOAD, "screenshots")
W, H = 1080, 1920

ACCENT = "#EF5A36"
INK = "#17181C"
MUTED = "#626773"
BG = "linear-gradient(180deg,#FFF8F4 0%,#FDF0E9 100%)"
SHADOW = "0 34px 70px rgba(90,40,20,.20), 0 6px 18px rgba(90,40,20,.08)"

# Phone: outer frame and the screen inside it. Raw screenshots are scaled so
# their width fills the screen; everything below the canvas is cut off.
PX, PY, PW, BORDER = 120, 640, 840, 17
SX, SY, SW = PX + BORDER, PY + BORDER, PW - 2 * BORDER
SCALE = SW / 1280

ICONS = {
    "sparkle": '<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/>',
    "pencil": '<path d="M4 20h4L19 9l-4-4L4 16v4z"/><path d="M13.5 6.5l4 4"/>',
    "share": '<path d="M12 15V3M7 8l5-5 5 5"/><path d="M5 14v6h14v-6"/>',
    "heart": '<path d="M12 20s-7-4.4-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.6-7 10-7 10z"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "user": '<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0116 0"/>',
    "lang": '<path d="M3 5h11M8.5 3v2M5 9c1.5 3 4 5.5 8 7M12 5c-.5 4-3.5 8.5-8 11"/>'
            '<path d="M13 21l4-9 4 9M14.5 18h5"/>',
    "save": '<path d="M6 3h12v18l-6-4.5L6 21z"/>',
    "shield": '<path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
    "moon": '<path d="M20 14.5A8 8 0 119.5 4a6.5 6.5 0 0010.5 10.5z"/>',
    "image": '<rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="9" cy="10" r="2"/>'
             '<path d="M21 16l-5-5-9 9"/>',
}

CSS = f"""
  *{{box-sizing:border-box;margin:0}}
  body{{font-family:Poppins,Mukta,sans-serif;color:{INK}}}
  .bg{{position:absolute;inset:0;background:{BG}}}
  .eyebrow{{position:absolute;left:92px;top:122px;font-size:31px;font-weight:500;color:{ACCENT};
    display:flex;align-items:center;gap:16px}}
  .eyebrow:before{{content:"";width:12px;height:12px;border-radius:50%;background:{ACCENT}}}
  h1{{position:absolute;left:90px;right:60px;top:192px;font-size:88px;line-height:1.08;
    font-weight:600;letter-spacing:-2.2px}}
  h1 em{{font-style:normal;color:{ACCENT}}}
  .sub{{position:absolute;left:92px;right:90px;font-size:34px;line-height:1.45;color:{MUTED}}}
  .phone{{position:absolute;left:{PX}px;top:{PY}px;width:{PW}px;height:1500px;
    background:#16181D;border-radius:118px;box-shadow:0 40px 90px rgba(60,25,10,.16)}}
  .screen{{position:absolute;left:{BORDER}px;top:{BORDER}px;width:{SW}px;height:1480px;
    border-radius:101px;overflow:hidden;background:#F8F9FB}}
  .screen img{{display:block;width:{SW}px}}
  .cam{{position:absolute;left:{PX + PW // 2 - 16}px;top:{PY + 38}px;width:32px;height:32px;
    border-radius:50%;background:#0B0C0F}}
  .lift{{position:absolute;box-shadow:{SHADOW};overflow:hidden}}
  .lift img{{display:block;width:100%;height:100%}}
  .chip{{position:absolute;display:flex;align-items:center;gap:20px;padding:16px 34px 16px 16px;
    background:#fff;border-radius:999px;font-size:33px;font-weight:500;white-space:nowrap;
    box-shadow:0 18px 40px rgba(90,40,20,.14);border:1px solid rgba(0,0,0,.04)}}
  .ico{{width:62px;height:62px;border-radius:50%;background:#FFEDE6;display:flex;
    align-items:center;justify-content:center}}
  .ico svg,.tile .ico svg{{width:32px;height:32px;fill:none;stroke:{ACCENT};stroke-width:2;
    stroke-linecap:round;stroke-linejoin:round}}
  .tile{{position:absolute;background:#fff;border-radius:44px;padding:44px 40px;
    box-shadow:0 22px 50px rgba(90,40,20,.10);border:1px solid rgba(0,0,0,.035)}}
  .tile .ico{{width:96px;height:96px;border-radius:28px}}
  .tile .ico svg{{width:44px;height:44px}}
  .tile h3{{font-size:40px;font-weight:600;letter-spacing:-.5px;margin-top:40px}}
  .tile p{{font-size:29px;line-height:1.4;color:{MUTED};margin-top:14px}}
  .pills{{display:flex;gap:14px;margin-top:26px}}
  .pills span{{padding:12px 28px;border-radius:999px;font-size:28px;background:#F1EEEC;color:{MUTED}}}
  .pills span.on{{background:{ACCENT};color:#fff}}
"""


def icon(name):
    return f'<svg viewBox="0 0 24 24">{ICONS[name]}</svg>'


def uri(img):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()


def raw(name):
    return Image.open(os.path.join(RAW, name)).convert("RGB")


def phone(name):
    img = raw(name)
    img = img.resize((SW, round(img.height * SCALE)), Image.LANCZOS)
    return (f'<div class="phone"><div class="screen"><img src="{uri(img)}"></div></div>'
            f'<div class="cam"></div>')


def lift(name, box, k=1.04, rot=0, dx=0, dy=0, radius=40):
    """Copy of part of the screen, shown raised above the phone in place."""
    x0, y0, x1, y1 = box
    crop = raw(name).crop(box)
    w, h = (x1 - x0) * SCALE, (y1 - y0) * SCALE
    crop = crop.resize((round(w * k * 1.5), round(h * k * 1.5)), Image.LANCZOS)
    left, top = SX + x0 * SCALE, SY + y0 * SCALE
    return (f'<div class="lift" style="left:{left:.0f}px;top:{top:.0f}px;width:{w:.0f}px;'
            f'height:{h:.0f}px;border-radius:{radius / k:.0f}px;'
            f'transform:translate({dx}px,{dy}px) rotate({rot}deg) scale({k})">'
            f'<img src="{uri(crop)}"></div>')


def chip(x, y, ico, text):
    return f'<div class="chip" style="left:{x}px;top:{y}px"><div class="ico">{icon(ico)}</div>{text}</div>'


def header(eyebrow, title, sub, sub_top=430):
    return (f'<div class="bg"></div><div class="eyebrow">{eyebrow}</div><h1>{title}</h1>'
            f'<div class="sub" style="top:{sub_top}px">{sub}</div>')


def render(n, body):
    dest = os.path.join(OUT, f"{n:02d}.png")
    render_html(page(f"<style>{CSS}</style>{body}", W, H, FONTS), W, H, dest)
    Image.open(dest).convert("RGB").save(dest, optimize=True)
    print("made", dest)


def slides():
    render(1, header("Fresh statuses every day",
                     "Beautiful statuses,<br>ready in <em>seconds</em>",
                     "Good Morning, festivals and birthdays, in Hindi and English.")
           + phone("01_home.png")
           + lift("01_home.png", (55, 570, 1225, 2560), k=1.04, rot=-1.6, radius=44)
           + chip(560, 960, "sparkle", "New posts daily")
           + chip(80, 1790, "pencil", "Tap any post to customise"))

    render(2, header("Ready-made templates",
                     "A design for<br><em>every moment</em>",
                     "Pick a template, add your name, and it's ready to share.")
           + phone("03_create.png")
           + lift("03_create.png", (553, 1500, 1013, 2315), k=1.14, rot=2.5, dy=-60, radius=34)
           + chip(560, 1330, "check", "Everything is editable")
           + chip(60, 1800, "heart", "Festivals & birthdays"))

    render(3, header("Easy editor",
                     "Make every status<br><em>truly yours</em>",
                     "Change the text, fonts, colours, photo and stickers.")
           + phone("02_editor.png")
           + lift("02_editor.png", (722, 172, 1243, 318), k=1.3, dx=-30, radius=36)
           + lift("02_editor.png", (0, 2480, 1280, 2790), k=1.06, rot=-1, dy=-610, radius=44)
           + chip(70, 1180, "user", "Add your photo & name"))

    render(4, header("Share with family",
                     "Like, customise<br>&amp; <em>share</em>",
                     "Send your status to friends and family in one tap.")
           + phone("05_share.png")
           + lift("05_share.png", (0, 2055, 1280, 2740), k=1.05, rot=-1.2, dy=-470, radius=48)
           + chip(570, 930, "heart", "Like your favourites")
           + chip(70, 1080, "share", "Share in one tap"))

    tiles = [
        (90, 600, 900, 330, "lang", "Hindi &amp; English", "Use the app in the language you love.",
         '<div class="pills" style="position:absolute;right:40px;top:44px;margin:0">'
         '<span>EN</span><span class="on">हिंदी</span></div>'),
        (90, 970, 435, 420, "image", "Your photo", "Add it, then move, zoom and frame it.", ""),
        (555, 970, 435, 420, "save", "Save drafts", "Edit your designs again any time.", ""),
        (90, 1430, 435, 420, "shield", "Safe community", "Report, hide or block any post.", ""),
        (555, 1430, 435, 420, "moon", "Light or dark", "Pick the look you like.",
         '<div class="pills"><span>Light</span><span class="on">Dark</span></div>'),
    ]
    body = header("And so much more", "Everything you need,<br><em>built in</em>",
                  "No sign-up, no ads. Just make and share.")
    for x, y, w, h, ico, t, p, extra in tiles:
        body += (f'<div class="tile" style="left:{x}px;top:{y}px;width:{w}px;height:{h}px">'
                 f'<div class="ico">{icon(ico)}</div><h3>{t}</h3><p>{p}</p>{extra}</div>')
    render(5, body)


def feature_graphic():
    w, h = 1024, 500

    def card(name, box, cw, x, y, rot, z):
        img = raw(name).crop(box)
        ch = round(cw * img.height / img.width)
        img = img.resize((cw * 2, ch * 2), Image.LANCZOS)
        return (f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cw}px;height:{ch}px;'
                f'transform:rotate({rot}deg);z-index:{z};border-radius:22px;overflow:hidden;'
                f'border:5px solid #fff;box-shadow:0 22px 44px rgba(90,40,20,.25)">'
                f'<img src="{uri(img)}" style="width:100%;height:100%;display:block"></div>')

    logo = svg(64, 64, f'<defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1">'
                       f'<stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>'
                       f'</linearGradient></defs><rect width="64" height="64" rx="16" fill="url(#lg)"/>'
               + glyph(32, 32, 19))
    body = f"""
    <div style="position:absolute;inset:0;background:linear-gradient(120deg,#FFF8F4 0%,#FDEBE2 100%)"></div>
    <div style="position:absolute;right:-120px;top:-160px;width:620px;height:620px;border-radius:50%;
      background:radial-gradient(closest-side,rgba(239,90,54,.20),rgba(239,90,54,0))"></div>
    <div style="position:absolute;left:64px;top:72px;width:470px;font-family:Poppins,sans-serif;color:{INK}">
      <div style="display:flex;align-items:center;gap:16px;font-size:28px;font-weight:600">{logo}Status Maker</div>
      <div style="margin-top:34px;font-size:50px;line-height:1.08;font-weight:600;letter-spacing:-1.4px">
        Beautiful statuses,<br>ready in <span style="color:{ACCENT}">seconds</span></div>
      <div style="margin-top:20px;font-size:21px;line-height:1.45;color:{MUTED}">
        Good Morning, festivals and birthdays.<br>In Hindi and English. Free.</div>
    </div>
    {card("03_create.png", (55, 1500, 515, 2315), 172, 560, 118, -9, 1)}
    {card("01_home.png", (55, 570, 1225, 2560), 226, 690, 54, -1, 3)}
    {card("04_dark.png", (55, 320, 1225, 2165), 196, 812, 112, 8, 2)}
    <div style="position:absolute;left:600px;top:398px;z-index:4;display:flex;align-items:center;gap:10px;
      padding:9px 20px 9px 9px;background:#fff;border-radius:999px;font:500 18px Poppins,sans-serif;
      color:{INK};box-shadow:0 12px 28px rgba(90,40,20,.18)">
      <span style="width:34px;height:34px;border-radius:50%;background:#FFEDE6;display:flex;
        align-items:center;justify-content:center"><svg viewBox="0 0 24 24" width="18" height="18"
        style="fill:none;stroke:{ACCENT};stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round">
        {ICONS['check']}</svg></span>Add your photo &amp; name</div>"""
    dest = os.path.join(UPLOAD, "2_feature_graphic_1024x500.png")
    render_html(page(body, w, h, FONTS), w, h, dest)
    Image.open(dest).convert("RGB").save(dest, optimize=True)
    shutil.copy(dest, os.path.join(ROOT, "store_listing", "graphics", "feature_graphic_1024x500.png"))
    print("made", dest)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    slides()
    feature_graphic()
