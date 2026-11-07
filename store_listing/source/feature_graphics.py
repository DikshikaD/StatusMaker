"""Three feature graphic options (1024x500) in different colour styles.

Run from the repo root:  python3 store_listing/source/feature_graphics.py
Output: store_listing/PLAY_STORE_UPLOAD/feature_graphic_options/
"""
import os
import sys

from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render import C1, C2, FONTS, ROOT, glyph, page, render_html, svg  # noqa: E402
from play_screenshots import ACCENT, ICONS, raw, uri  # noqa: E402

OUT = os.path.join(ROOT, "store_listing", "PLAY_STORE_UPLOAD", "feature_graphic_options")
W, H = 1024, 500

THEMES = {
    "A_light": dict(bg="linear-gradient(120deg,#FFF8F4 0%,#FDEBE2 100%)", ink="#17181C",
                    muted="#626773", accent=ACCENT, glow="rgba(239,90,54,.20)", logo_bg=True),
    "B_coral": dict(bg=f"linear-gradient(135deg,{C1} 0%,{C2} 100%)", ink="#FFFFFF",
                    muted="rgba(255,255,255,.88)", accent="#FFE3A3", glow="rgba(255,255,255,.22)",
                    logo_bg=False),
    "C_dark": dict(bg="linear-gradient(135deg,#1B1D23 0%,#121317 100%)", ink="#FFFFFF",
                   muted="#B4B8C2", accent="#FF7A55", glow="rgba(239,90,54,.35)", logo_bg=True),
}


def card(name, box, cw, x, y, rot, z):
    img = raw(name).crop(box)
    ch = round(cw * img.height / img.width)
    img = img.resize((cw * 2, ch * 2), Image.LANCZOS)
    return (f'<div style="position:absolute;left:{x}px;top:{y}px;width:{cw}px;height:{ch}px;'
            f'transform:rotate({rot}deg);z-index:{z};border-radius:22px;overflow:hidden;'
            f'border:5px solid #fff;box-shadow:0 22px 44px rgba(40,15,5,.32)">'
            f'<img src="{uri(img)}" style="width:100%;height:100%;display:block"></div>')


def logo(t):
    if t["logo_bg"]:
        inner = (f'<defs><linearGradient id="lg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" '
                 f'stop-color="{C1}"/><stop offset="1" stop-color="{C2}"/></linearGradient></defs>'
                 f'<rect width="64" height="64" rx="16" fill="url(#lg)"/>' + glyph(32, 32, 19))
    else:
        inner = ('<rect width="64" height="64" rx="16" fill="rgba(255,255,255,.18)"/>'
                 + glyph(32, 32, 19))
    return svg(64, 64, inner)


def graphic(name, t):
    body = f"""
    <div style="position:absolute;inset:0;background:{t['bg']}"></div>
    <div style="position:absolute;right:-120px;top:-160px;width:640px;height:640px;border-radius:50%;
      background:radial-gradient(closest-side,{t['glow']},rgba(0,0,0,0))"></div>
    <div style="position:absolute;left:64px;top:72px;width:480px;font-family:Poppins,sans-serif;color:{t['ink']}">
      <div style="display:flex;align-items:center;gap:16px;font-size:28px;font-weight:600">{logo(t)}Status Maker</div>
      <div style="margin-top:34px;font-size:50px;line-height:1.08;font-weight:600;letter-spacing:-1.4px">
        Beautiful statuses,<br>ready in <span style="color:{t['accent']}">seconds</span></div>
      <div style="margin-top:20px;font-size:21px;line-height:1.45;color:{t['muted']}">
        Good Morning, festivals and birthdays.<br>In Hindi and English. Free.</div>
    </div>
    {card("03_create.png", (55, 1500, 515, 2315), 172, 560, 118, -9, 1)}
    {card("01_home.png", (55, 570, 1225, 2560), 226, 690, 54, -1, 3)}
    {card("04_dark.png", (55, 320, 1225, 2165), 196, 812, 112, 8, 2)}
    <div style="position:absolute;left:600px;top:398px;z-index:4;display:flex;align-items:center;gap:10px;
      padding:9px 20px 9px 9px;background:#fff;border-radius:999px;font:500 18px Poppins,sans-serif;
      color:#17181C;box-shadow:0 12px 28px rgba(40,15,5,.22)">
      <span style="width:34px;height:34px;border-radius:50%;background:#FFEDE6;display:flex;
        align-items:center;justify-content:center"><svg viewBox="0 0 24 24" width="18" height="18"
        style="fill:none;stroke:{ACCENT};stroke-width:2.2;stroke-linecap:round;stroke-linejoin:round">
        {ICONS['check']}</svg></span>Add your photo &amp; name</div>"""
    dest = os.path.join(OUT, f"feature_graphic_{name}.png")
    render_html(page(body, W, H, FONTS), W, H, dest)
    Image.open(dest).convert("RGB").save(dest, optimize=True)
    print("made", dest)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for name, theme in THEMES.items():
        graphic(name, theme)
