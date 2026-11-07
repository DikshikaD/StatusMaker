"""Promo video (1920x1080, 30 fps, ~48 s, with music) for the Play Store listing.

A walkthrough of the real app: one phone stays on screen while its content
changes with app-like transitions (slide, scroll, bottom sheets, zoom, flip,
circular reveal) and tap ripples; headlines and callout chips change beside it.
An intro and outro of real status designs frame it.

Inputs:  store_listing/video_raw/*.png  (raw 1280x2856 emulator screenshots)
Run:     python3 store_listing/source/promo_video.py
Output:  store_listing/PLAY_STORE_UPLOAD/promo_video_1080p.mp4
"""
import math
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import C1, C2, FONTS, ROOT, glyph, page, render_html, svg  # noqa: E402
from play_screenshots import ACCENT, ICONS, INK, MUTED  # noqa: E402
import promo_music  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
RAW = os.path.join(ROOT, "store_listing", "video_raw")
OUT = os.path.join(ROOT, "store_listing", "PLAY_STORE_UPLOAD", "promo_video_1080p.mp4")
W, H, FPS = 1920, 1080, 30
TOTAL = 48.0

# Phone geometry. Raw screenshots are 1280x2856; K maps raw px to screen px.
SW = 440
K = SW / 1280
SH = round(2856 * K)
BORDER, PAD = 12, 90
PW, PH = SW + 2 * BORDER, SH + 2 * BORDER
PCX, PCY = 1300, 540


# ---------------------------------------------------------------------------
# Easing
# ---------------------------------------------------------------------------
def clamp(p):
    return max(0.0, min(1.0, p))


def ease_out(p):
    p = clamp(p)
    return 1 - (1 - p) ** 3


def ease_in(p):
    p = clamp(p)
    return p ** 3


def ease_io(p):
    p = clamp(p)
    return 4 * p ** 3 if p < 0.5 else 1 - (-2 * p + 2) ** 3 / 2


def back(p):
    p = clamp(p)
    c = 1.6
    return 1 + (c + 1) * (p - 1) ** 3 + c * (p - 1) ** 2


def with_alpha(img, a):
    if a >= 1:
        return img
    img = img.copy()
    img.putalpha(img.getchannel("A").point(lambda v: round(v * a)))
    return img


# ---------------------------------------------------------------------------
# Screen timeline
# ---------------------------------------------------------------------------
# (time, screenshot, transition, arg)
SCREENS = [
    (4.5, "s01_lang", None, None),
    (6.15, "s03_ob1", "fade", None),
    (7.1, "s04_ob2", "left", None),
    (7.9, "s05_ob3", "left", None),
    (8.85, "s06_home", "fade", None),
    (10.4, "s08_home3", "scroll", (300, 2540)),
    (11.55, "s11_detail", "zoom", None),
    (13.65, "s12_menu", "sheet", 2190),
    (15.2, "s11_detail", "sheet_down", 2190),
    (15.95, "s13_editor", "zoom", None),
    (17.15, "s14b_bg", "sheet", 625),
    (18.45, "s15_editor_bg", "sheet_down", 625),
    (19.85, "s17_font", "sheet", 625),
    (21.15, "s18_font_applied", "sheet_down", 625),
    (22.55, "s22_stickers", "sheet", 625),
    (23.85, "s24_sticker_moved", "sheet_down", 625),
    (24.8, "s25_final", "fade", None),
    (25.75, "s28_toast", "fade", None),
    (27.4, "s28_creations", "fade", None),
    (28.55, "s29_explore", "fade", None),
    (29.6, "s30_explore2", "scroll", (330, 2540)),
    (30.65, "s31_bday", "zoom", None),
    (31.75, "s33_photo_frame", "fade", None),
    (32.65, "s34_heart", "fade", None),
    (33.85, "s36_after_pick", "zoom", None),
    (35.35, "s37_heart_photo", "fade", None),
    (36.05, "s39_typing", "fade", None),
    (36.7, "s40_bday_final", "fade", None),
    (37.4, "s45_home_en_light", "fade", None),
    (38.6, "s46_home_hi_light", "flip", None),
    (39.9, "s48_home_hi_dark", "reveal", (640, 1500)),
    (41.1, "s49_home_en_dark", "flip", None),
]
DUR = {"fade": .35, "left": .45, "scroll": .55, "sheet": .45, "sheet_down": .4,
       "zoom": .4, "reveal": .75, "flip": .6}
# (time, raw x, raw y): a tap ripple just before the screen reacts.
TAPS = [(5.9, 640, 1980), (8.6, 640, 2612), (11.3, 640, 1500), (13.4, 1207, 240),
        (15.7, 640, 2602), (16.9, 160, 2538), (18.2, 487, 2562), (19.6, 640, 1290),
        (20.9, 640, 2375), (22.3, 880, 2538), (23.6, 1092, 1250), (25.4, 802, 245),
        (28.3, 368, 2670), (30.4, 280, 1900), (31.5, 660, 1640), (32.4, 1145, 2387),
        (33.6, 1025, 2670), (35.1, 1135, 240), (35.8, 450, 992)]

_cache = {}


def screen(name):
    if name not in _cache:
        img = Image.open(os.path.join(RAW, name + ".png")).convert("RGBA")
        _cache[name] = img.resize((SW, SH), Image.LANCZOS)
    return _cache[name]


def darken(img, a):
    black = Image.new("RGBA", img.size, (0, 0, 0, 255))
    return Image.blend(img, black, a)


_scrim = {}


def scrim(plain, dimmed, top):
    """How much the app's modal scrim darkened `plain` to get `dimmed`."""
    key = (id(plain), id(dimmed))
    if key not in _scrim:
        box = (0, 0, SW, int(top * K * 0.6))
        a = sum(plain.convert("L").crop(box).getdata()) or 1
        b = sum(dimmed.convert("L").crop(box).getdata())
        _scrim[key] = max(0.0, min(0.7, 1 - b / a))
    return _scrim[key]


def transition(kind, arg, old, new, p):
    """Returns (image, horizontal scale for a flip)."""
    e = ease_io(p)
    if kind == "fade":
        return Image.blend(old, new, e), 1
    if kind == "left":
        img = Image.new("RGBA", (SW, SH))
        x = round(-SW * e)
        img.paste(old, (x, 0))
        img.paste(new, (x + SW, 0))
        return img, 1
    if kind == "scroll":
        y0, y1 = round(arg[0] * K), round(arg[1] * K)
        h = y1 - y0
        img = Image.blend(old, new, e)
        tile = Image.new("RGBA", (SW, h))
        tile.paste(old.crop((0, y0, SW, y1)), (0, round(-h * e)))
        tile.paste(new.crop((0, y0, SW, y1)), (0, round(h * (1 - e))))
        img.paste(tile, (0, y0))
        return img, 1
    if kind == "sheet":
        top = round(arg * K)
        a = scrim(old, new, arg)
        img = Image.blend(old, darken(old, a), e)
        img.paste(new.crop((0, top, SW, SH)), (0, top + round((SH - top) * (1 - e))))
        return img, 1
    if kind == "sheet_down":
        top = round(arg * K)
        a = scrim(new, old, arg)
        img = Image.blend(darken(new, a), new, e)
        img.paste(old.crop((0, top, SW, SH)), (0, top + round((SH - top) * e)))
        return img, 1
    if kind == "zoom":
        s = 0.9 + 0.1 * ease_out(p)
        w, h = round(SW * s), round(SH * s)
        img = old.copy()
        img.alpha_composite(with_alpha(new.resize((w, h), Image.BILINEAR), ease_out(p)),
                            ((SW - w) // 2, (SH - h) // 2))
        return img, 1
    if kind == "reveal":
        cx, cy = arg[0] * K, arg[1] * K
        r = math.hypot(max(cx, SW - cx), max(cy, SH - cy)) * e
        mask = Image.new("L", (SW, SH), 0)
        ImageDraw.Draw(mask).ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
        img = old.copy()
        img.paste(new, (0, 0), mask)
        return img, 1
    if kind == "flip":
        return (old if p < 0.5 else new), abs(math.cos(math.pi * ease_io(p)))
    return new, 1


def screen_at(t):
    idx = max(i for i, s in enumerate(SCREENS) if s[0] <= t) if t >= SCREENS[0][0] else 0
    start, name, kind, arg = SCREENS[idx]
    img, sx = screen(name), 1
    if kind and idx > 0 and t < start + DUR[kind]:
        img, sx = transition(kind, arg, screen(SCREENS[idx - 1][1]), img, (t - start) / DUR[kind])
    for tt, x, y in TAPS:
        q = (t - tt) / 0.5
        if 0 <= q <= 1:
            img = img.copy()
            over = Image.new("RGBA", (SW, SH))
            d = ImageDraw.Draw(over)
            r = 14 + 34 * ease_out(q)
            cx, cy = x * K, y * K
            d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(20, 20, 30, round(70 * (1 - q))),
                      outline=(255, 255, 255, round(230 * (1 - q))), width=3)
            img.alpha_composite(over)
    return img, sx


# ---------------------------------------------------------------------------
# Phone
# ---------------------------------------------------------------------------
def rounded_mask(w, h, r):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), r, fill=255)
    return m


def build_phone_body():
    size = (PW + 2 * PAD, PH + 2 * PAD)
    shadow = Image.new("L", size, 0)
    ImageDraw.Draw(shadow).rounded_rectangle((PAD + 10, PAD + 34, PAD + PW - 10, PAD + PH + 10), 70, fill=120)
    shadow = shadow.filter(ImageFilter.GaussianBlur(34))
    body = Image.new("RGBA", size, (90, 35, 15, 0))
    body.putalpha(shadow)
    shell = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shell).rounded_rectangle((PAD, PAD, PAD + PW, PAD + PH), 66, fill=(22, 24, 29, 255))
    body.alpha_composite(shell)
    return body


PHONE_BODY = None
SCREEN_MASK = None


def phone_image(scr):
    img = PHONE_BODY.copy()
    img.paste(scr, (PAD + BORDER, PAD + BORDER), SCREEN_MASK)
    d = ImageDraw.Draw(img)
    cx, cy = PAD + PW // 2, PAD + BORDER + 22
    d.ellipse((cx - 9, cy - 9, cx + 9, cy + 9), fill=(10, 11, 14, 255))
    return img


# ---------------------------------------------------------------------------
# HTML layers (text, chips, logo, button)
# ---------------------------------------------------------------------------
CSS = f"""
  *{{box-sizing:border-box;margin:0}}
  body{{font-family:Poppins,Mukta,sans-serif;color:{INK}}}
  .text{{position:absolute;left:150px;top:0;bottom:0;width:820px;display:flex;flex-direction:column;
    justify-content:center}}
  .eyebrow{{font-size:31px;font-weight:500;color:{ACCENT};display:flex;align-items:center;gap:14px}}
  .eyebrow:before{{content:"";width:11px;height:11px;border-radius:50%;background:{ACCENT}}}
  h1{{font-size:94px;line-height:1.06;font-weight:600;letter-spacing:-2.6px;margin-top:24px}}
  h1 em{{font-style:normal;color:{ACCENT}}}
  .sub{{font-size:34px;line-height:1.45;color:{MUTED};margin-top:30px;max-width:760px}}
  .chip{{position:absolute;display:flex;align-items:center;gap:14px;padding:12px 26px 12px 12px;
    background:#fff;border-radius:999px;font-size:26px;font-weight:500;white-space:nowrap;
    box-shadow:0 14px 34px rgba(90,40,20,.16);border:1px solid rgba(0,0,0,.04)}}
  .ico{{width:48px;height:48px;border-radius:50%;background:#FFEDE6;display:flex;align-items:center;
    justify-content:center}}
  svg.i{{width:26px;height:26px;fill:none;stroke:{ACCENT};stroke-width:2;stroke-linecap:round;
    stroke-linejoin:round}}
  .center{{position:absolute;left:0;right:0;display:flex;flex-direction:column;align-items:center;
    text-align:center}}
"""


def icon(name):
    return f'<svg class="i" viewBox="0 0 24 24">{ICONS[name]}</svg>'


def logo(size):
    return svg(size, size, f'<defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1">'
                           f'<stop offset="0" stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/>'
                           f'</linearGradient></defs><rect width="{size}" height="{size}" rx="{size * .24}" '
                           f'fill="url(#lg)"/>' + glyph(size / 2, size / 2, size * .3))


def layer(html, work, name):
    path = os.path.join(work, name + ".png")
    render_html(page(f"<style>{CSS}</style>{html}", W, H, FONTS), W, H, path, transparent=True)
    img = Image.open(path).convert("RGBA")
    box = img.getbbox() or (0, 0, 1, 1)
    return img.crop(box), box[:2]


def text_html(eyebrow, title, sub):
    return f'<div class="text"><div class="eyebrow">{eyebrow}</div><h1>{title}</h1><div class="sub">{sub}</div></div>'


def chip_html(x, y, ico, label):
    return f'<div class="chip" style="left:{x}px;top:{y}px"><div class="ico">{icon(ico)}</div>{label}</div>'


TEXTS = [
    (5.0, 9.4, "Easy start", "No sign-up.<br>Just <em>start.</em>", "Pick Hindi or English and you're in."),
    (9.6, 11.9, "Fresh every day", "Statuses for<br><em>every moment</em>",
     "Good Morning, festivals, birthdays and more, in Hindi and English."),
    (12.0, 16.6, "Love a post?", "Like, share or<br><em>customise it</em>",
     "Report, hide or block anything that's not okay."),
    (16.8, 25.4, "Easy editor", "Design it<br><em>your way</em>",
     "Change the background, font and colours. Add stickers."),
    (25.6, 28.6, "Save", "Saved to<br><em>My Creations</em>", "Come back and edit it any time."),
    (28.8, 37.0, "Ready-made templates", "Add your<br><em>photo &amp; name</em>",
     "Pick a template, drop in a photo, type a name. Done."),
    (37.2, 41.9, "Your language, your look", "हिंदी or English.<br><em>Light or dark.</em>",
     "Switch any time in Settings."),
]
CHIPS = [
    (10.0, 11.9, 1560, 300, "sparkle", "New posts daily"),
    (14.1, 16.6, 1560, 760, "shield", "Report · Hide · Block"),
    (17.3, 25.4, 1560, 330, "image", "Backgrounds"),
    (20.2, 25.4, 1560, 430, "pencil", "Fonts"),
    (23.4, 25.4, 1560, 530, "heart", "Stickers"),
    (26.0, 28.6, 1560, 300, "save", "Saved privately"),
    (32.4, 37.0, 1560, 640, "heart", "Photo frames"),
    (35.5, 37.0, 1560, 740, "user", "Your name"),
    (38.6, 41.9, 1560, 330, "lang", "हिंदी"),
    (39.9, 41.9, 1560, 430, "moon", "Dark mode"),
]

# Intro/outro cards: (screenshot, raw crop box).
CARDS = [
    ("s40_bday_final", (100, 375, 1178, 2288)),
    ("s06_home", (55, 565, 1225, 2550)),
    ("s11_detail", (80, 325, 1195, 2000)),
    ("s09_home4", (50, 350, 1230, 2425)),
    ("s25_final", (100, 375, 1178, 2288)),
    ("s30_explore2", (555, 1450, 1010, 2260)),
]
# Final (centre x, centre y, rotation) and the direction each card flies in from.
INTRO = [(300, 330, -10, (-700, -300)), (440, 800, 8, (-500, 700)), (110, 830, -5, (-600, 200)),
         (1620, 310, 10, (700, -300)), (1490, 800, -8, (500, 700)), (1810, 830, 6, (600, 200))]
OUTRO = [(200, 240, -12, (-600, -300)), (1720, 240, 11, (600, -300)),
         (190, 880, 8, (-600, 300)), (1730, 870, -9, (600, 300))]


def build_card(name, box, height=420):
    img = Image.open(os.path.join(RAW, name + ".png")).convert("RGB").crop(box)
    w = round(height * img.width / img.height)
    img = img.resize((w, height), Image.LANCZOS).convert("RGBA")
    bw = 7
    card = Image.new("RGBA", (w + 2 * bw, height + 2 * bw), (255, 255, 255, 255))
    card.paste(img, (bw, bw))
    card.putalpha(rounded_mask(card.width, card.height, 26))
    pad = 50
    out = Image.new("RGBA", (card.width + 2 * pad, card.height + 2 * pad), (90, 35, 15, 0))
    sh = Image.new("L", out.size, 0)
    ImageDraw.Draw(sh).rounded_rectangle((pad, pad + 18, pad + card.width, pad + card.height + 8), 26, fill=110)
    out.putalpha(sh.filter(ImageFilter.GaussianBlur(20)))
    out.alpha_composite(card, (pad, pad))
    return out


# ---------------------------------------------------------------------------
# Frame assembly
# ---------------------------------------------------------------------------
def gradient(w, h, c0, c1):
    g = Image.new("RGB", (2, 2))
    g.putdata([c0, c0, c1, c1])
    return g.resize((w, h), Image.BILINEAR)


def blob(size, rgb, alpha):
    small = Image.new("L", (128, 128), 0)
    ImageDraw.Draw(small).ellipse((16, 16, 112, 112), fill=alpha)
    m = small.filter(ImageFilter.GaussianBlur(18)).resize((size, size), Image.BILINEAR)
    img = Image.new("RGBA", (size, size), rgb + (0,))
    img.putalpha(m)
    return img


def paste(frame, img, x, y, a=1.0, scale=1.0, rot=0.0):
    if a <= 0.01:
        return
    if rot:
        img = img.rotate(rot, resample=Image.BICUBIC, expand=True)
    if scale != 1:
        img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.BILINEAR)
    img = with_alpha(img, a)
    frame.paste(img, (round(x - img.width / 2), round(y - img.height / 2)), img)


def main():
    global PHONE_BODY, SCREEN_MASK
    work = tempfile.mkdtemp(prefix="promo_")
    frames = os.path.join(work, "frames")
    os.makedirs(frames)

    PHONE_BODY = build_phone_body()
    SCREEN_MASK = rounded_mask(SW, SH, 54)
    bg = gradient(W, H, (255, 248, 244), (253, 231, 220))
    blob_a, blob_b = blob(1100, (239, 103, 69), 60), blob(900, (255, 170, 120), 70)

    texts = [(a, b, *layer(text_html(e, h1, s), work, f"t{i}")) for i, (a, b, e, h1, s) in enumerate(TEXTS)]
    chips = [(a, b, *layer(chip_html(x, y, ic, lab), work, f"c{i}")) for i, (a, b, x, y, ic, lab) in enumerate(CHIPS)]
    cards = [build_card(n, box) for n, box in CARDS]
    title, title_pos = layer(f'<div class="center" style="top:330px">{logo(150)}'
                             f'<div style="font-size:100px;font-weight:600;letter-spacing:-3px;margin-top:26px">'
                             f'Status <span style="color:{ACCENT}">Maker</span></div></div>', work, "title")
    tagline, tag_pos = layer('<div class="center" style="top:640px"><div style="font-size:38px;color:'
                             f'{MUTED}">Beautiful statuses in seconds</div></div>', work, "tagline")
    o_logo, o_logo_pos = layer(f'<div class="center" style="top:250px"><div style="display:flex;align-items:center;'
                               f'gap:22px;font-size:46px;font-weight:600">{logo(96)}Status Maker</div></div>',
                               work, "ologo")
    o_head, o_head_pos = layer('<div class="center" style="top:400px"><div style="font-size:84px;font-weight:600;'
                               f'letter-spacing:-2.4px">Make your first status <span style="color:{ACCENT}">today'
                               '</span></div></div>', work, "ohead")
    o_chips = [layer(chip_html(x, 560, ic, lab), work, f"oc{i}") for i, (x, ic, lab) in
               enumerate([(560, "sparkle", "Free"), (800, "check", "No sign-up"), (1110, "lang", "Hindi &amp; English")])]
    o_btn, o_btn_pos = layer('<div class="center" style="top:700px"><div style="display:flex;align-items:center;'
                             f'gap:18px;padding:26px 56px;border-radius:999px;background:linear-gradient(135deg,{C1},{C2});'
                             'color:#fff;font-size:40px;font-weight:600;box-shadow:0 20px 44px rgba(226,73,42,.38)">'
                             '<svg viewBox="0 0 24 24" width="40" height="40" style="fill:none;stroke:#fff;'
                             'stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round"><path d="M12 4v12M6 11l6 6 6-6"/>'
                             '<path d="M5 20h14"/></svg>Download free</div></div>', work, "obtn")
    print("layers ready")

    def centre(img, pos):
        return pos[0] + img.width / 2, pos[1] + img.height / 2

    def render_frame(t):
        f = bg.copy()
        paste(f, blob_a, 1450 + 160 * math.sin(t / 5), 260 + 120 * math.cos(t / 6))
        paste(f, blob_b, 300 + 140 * math.cos(t / 7), 900 + 90 * math.sin(t / 4))

        # Intro: cards fly in, title pops, everything clears for the phone.
        if t < 5.2:
            out = ease_in((t - 3.9) / 0.7)
            for k, (card, (cx, cy, rot, (fx, fy))) in enumerate(zip(cards, INTRO)):
                p = (t - 0.15 - k * 0.12) / 0.9
                if p <= 0:
                    continue
                e = back(p)
                x = cx + fx * (1 - e) + (cx - 960) * 0.5 * out
                y = cy + fy * (1 - e) + 6 * math.sin(t * 1.3 + k)
                paste(f, card, x, y, a=min(1, p * 2) * (1 - out), rot=rot * e)
            pt = (t - 1.5) / 0.6
            if pt > 0:
                x, y = centre(title, title_pos)
                paste(f, title, x, y - 40 * out, a=ease_out(pt) * (1 - out), scale=0.8 + 0.2 * back(pt))
            pg = (t - 2.1) / 0.6
            if pg > 0:
                x, y = centre(tagline, tag_pos)
                paste(f, tagline, x, y + 30 * (1 - ease_out(pg)) - 40 * out, a=ease_out(pg) * (1 - out))

        # Text and chips beside the phone.
        for a, b, img, pos in texts:
            if a <= t <= b:
                pin, pout = ease_out((t - a) / 0.7), ease_in((t - (b - 0.4)) / 0.4)
                x, y = centre(img, pos)
                paste(f, img, x, y + 40 * (1 - pin) - 30 * pout, a=pin * (1 - pout))
        for a, b, img, pos in chips:
            if a <= t <= b:
                p, pout = (t - a) / 0.45, ease_in((t - (b - 0.4)) / 0.4)
                x, y = centre(img, pos)
                paste(f, img, x, y, a=ease_out(p) * (1 - pout), scale=0.75 + 0.25 * back(p))

        # Phone.
        if 4.6 <= t <= 42.9:
            enter, leave = ease_out((t - 4.6) / 1.0), ease_in((t - 42.0) / 0.8)
            scr, sx = screen_at(t)
            ph = phone_image(scr)
            if sx < 1:
                ph = ph.resize((max(2, round(ph.width * sx)), ph.height), Image.BILINEAR)
            y = PCY + 800 * (1 - enter) + 800 * leave + 7 * math.sin(t * 2 * math.pi / 4.8)
            paste(f, ph, PCX, y, a=min(1, enter * 1.5) * (1 - leave))

        # Outro.
        if t >= 42.6:
            for k, (card, (cx, cy, rot, (fx, fy))) in enumerate(zip([cards[0], cards[2], cards[4], cards[5]], OUTRO)):
                p = (t - 42.8 - k * 0.1) / 0.9
                if p > 0:
                    e = back(p)
                    paste(f, card, cx + fx * (1 - e), cy + fy * (1 - e) + 6 * math.sin(t * 1.3 + k),
                          a=min(1, p * 2), rot=rot * e, scale=0.85)
            for img, pos, start, kind in [(o_logo, o_logo_pos, 42.9, "pop"), (o_head, o_head_pos, 43.3, "rise")]:
                p = (t - start) / 0.6
                if p > 0:
                    x, y = centre(img, pos)
                    if kind == "pop":
                        paste(f, img, x, y, a=ease_out(p), scale=0.8 + 0.2 * back(p))
                    else:
                        paste(f, img, x, y + 40 * (1 - ease_out(p)), a=ease_out(p))
            for k, (img, pos) in enumerate(o_chips):
                p = (t - 43.9 - k * 0.15) / 0.45
                if p > 0:
                    x, y = centre(img, pos)
                    paste(f, img, x, y, a=ease_out(p), scale=0.75 + 0.25 * back(p))
            p = (t - 44.6) / 0.5
            if p > 0:
                x, y = centre(o_btn, o_btn_pos)
                pulse = 1 + 0.035 * math.sin((t - 45.1) * 2 * math.pi / 1.2) if t > 45.1 else 1
                paste(f, o_btn, x, y, a=ease_out(p), scale=(0.7 + 0.3 * back(p)) * pulse)

        return f

    if PREVIEW:
        sheet = Image.new("RGB", (480 * 4, 270 * math.ceil(len(PREVIEW) / 4)), "#666")
        for k, t in enumerate(PREVIEW):
            sheet.paste(render_frame(t).resize((480, 270)), ((k % 4) * 480, (k // 4) * 270))
        sheet.save(PREVIEW_OUT)
        print("preview", PREVIEW_OUT)
        return

    n = round(TOTAL * FPS)
    for i in range(n):
        render_frame(i / FPS).save(os.path.join(frames, f"{i:05d}.jpg"), quality=92)
        if i % 300 == 0:
            print(f"frame {i}/{n}")

    music = os.path.join(work, "music.wav")
    promo_music.make(TOTAL, music, riser_at=4.8)
    subprocess.run(["swift", os.path.join(HERE, "encode_video.swift"), frames, OUT, str(FPS), music], check=True)
    shutil.rmtree(work)
    print("made", OUT)


PREVIEW, PREVIEW_OUT = [], None

if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "--preview":
        PREVIEW = [float(x) for x in sys.argv[2].split(",")]
        PREVIEW_OUT = sys.argv[3]
    main()
