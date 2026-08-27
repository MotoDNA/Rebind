# DNA Labs 마크를 그립니다.
#
# 원 한가운데에 DNA, 그 아래 빈 공간에 LABS.
# 글자를 그림에 박아 두는 이유: 브라우저 탭 아이콘과 홈 화면 아이콘은
# PNG 만 받습니다. 앱 안에서도 같은 그림을 써야 어디서 보든 같아집니다.
#
# 안드로이드 홈 화면에 얹을 때 쓰는 아이콘과 manifest 도 함께 만듭니다.
# 안드로이드 크롬은 apple-touch-icon 을 보지 않고 manifest 만 봅니다.
# 그래서 manifest 가 없으면 홈 화면에 얹어도 마크가 안 나오고
# 크롬 기본 조각 아이콘이 붙습니다.
#
#   python3 make-logo.py            → logo.png (180×180) · 아이콘 · manifest
#   python3 make-logo.py 512        → logo.png 을 더 크게
import sys
from PIL import Image, ImageDraw, ImageFont

OUT   = '/Users/motodna/Desktop/Rebind/logo.png'
FONT  = '/System/Library/Fonts/HelveticaNeue.ttc'
BOLD  = 1                       # 위 파일 안의 Bold 자리
BG    = (42, 42, 44, 255)       # #2A2A2C

N     = int(sys.argv[1]) if len(sys.argv) > 1 else 180
S     = 6                       # 여섯 배로 그린 뒤 줄여서 가장자리를 부드럽게
W     = N * S
k     = W / 96.0                # 아래 숫자들은 96 짜리 도안 기준입니다

DNA_SIZE,  DNA_TRACK  = 34, -1.2
LABS_SIZE, LABS_TRACK = 12,  6.5
LABS_BASE = 78                  # LABS 기준선

def tracked(draw, text, font, track, cx, baseline, fill):
    """글자 사이를 벌려 가운데 맞춤으로 그립니다. Pillow 에는 자간이 없어 한 자씩 놓습니다."""
    widths = [draw.textlength(ch, font=font) for ch in text]
    total  = sum(widths) + track * (len(text) - 1)
    x = cx - total / 2
    for ch, w in zip(text, widths):
        draw.text((x, baseline), ch, font=font, fill=fill, anchor='ls')
        x += w + track

def mark(size, square=False):
    """마크를 그려 돌려줍니다.
       square=True 면 원 대신 네모를 꽉 채웁니다 — 안드로이드가 제 모양대로
       잘라 쓰는 아이콘(maskable)이라 원을 그려 두면 두 번 잘려 작아집니다."""
    w  = size * S
    kk = w / 96.0
    im = Image.new('RGBA', (w, w), (0, 0, 0, 0))
    dd = ImageDraw.Draw(im)
    if square: dd.rectangle([0, 0, w - 1, w - 1], fill=BG)
    else:      dd.ellipse(  [0, 0, w - 1, w - 1], fill=BG)
    fd = ImageFont.truetype(FONT, int(DNA_SIZE  * kk), index=BOLD)
    fl = ImageFont.truetype(FONT, int(LABS_SIZE * kk), index=BOLD)
    # DNA 를 한가운데에 — 글자 윗선과 밑선의 중간이 원의 중심에 오도록 기준선을 내립니다
    tracked(dd, 'DNA',  fd, DNA_TRACK  * kk, w / 2,
            (48 + 0.72 * DNA_SIZE / 2) * kk, (255, 255, 255, 255))
    tracked(dd, 'LABS', fl, LABS_TRACK * kk, w / 2,
            LABS_BASE * kk,                  (255, 255, 255, 235))
    return im.resize((size, size), Image.LANCZOS)

mark(N).save(OUT)
print('만들었습니다:', OUT, N, 'x', N)

# ── 만든 그림을 앱 파일에 박아 넣습니다 ──
# bindery.html 은 파일 하나로 도는 앱이라 그림도 그 안에 들어 있어야 합니다.
# 세 곳에 같은 값이 들어갑니다: 홈 화면 아이콘 · 탭 아이콘 · 화면 안의 로고
#
# 여기는 Re:Bind 마크만 다룹니다. Re:Call 은 예전 마크를 그대로 씁니다.
import base64, io, os, re

APPS = [
    '/Users/motodna/Desktop/Rebind/bindery.html',          # Re:Bind
]
PAT = re.compile(r'rel="icon" href="data:image/png;base64,([A-Za-z0-9+/=]+)"')

b64 = base64.b64encode(open(OUT, 'rb').read()).decode()
for app in APPS:
    if not os.path.exists(app):
        print(f'건너뜁니다 (파일 없음): {app}')
        continue
    s = io.open(app, encoding='utf-8').read()
    m = PAT.search(s)
    if not m:
        print(f'건너뜁니다 (마크를 못 찾음): {app}')
    elif m.group(1) == b64:
        print(f'그대로입니다: {os.path.basename(app)}')
    else:
        n = s.count(m.group(1))
        io.open(app, 'w', encoding='utf-8').write(s.replace(m.group(1), b64))
        print(f'넣었습니다: {os.path.basename(app)} — {n} 곳')

# ── 안드로이드 홈 화면용 아이콘과 manifest ──
# 아이폰은 위에서 bindery.html 안에 박아 넣은 apple-touch-icon 을 씁니다.
# 안드로이드 크롬은 그것을 보지 않고 manifest 의 icons 만 봅니다.
# 그래서 이 두 장과 manifest 파일이 따로 필요합니다.
#
# maskable 한 장을 더 두는 이유: 안드로이드는 기기마다 아이콘을 제 모양대로
# (원 · 사각 · 물방울) 잘라 냅니다. 원으로 그린 마크를 주면 한 번 더 잘려
# 글자가 잘립니다. 네모를 꽉 채운 것을 주면 어떻게 잘려도 온전합니다.
import json

HERE = os.path.dirname(OUT)
for px in (192, 512):
    p = os.path.join(HERE, f'icon-{px}.png')
    mark(px).save(p)
    print('만들었습니다:', os.path.basename(p))

p = os.path.join(HERE, 'icon-maskable-512.png')
mark(512, square=True).save(p)
print('만들었습니다:', os.path.basename(p))

MANIFEST = {
    'name': 'Re:Bind · 제조 공정과 거래명세서',
    'short_name': 'Re:Bind',
    'description': '제본소의 공정 기록과 거래명세서',
    'lang': 'ko',
    # 상대 주소로 둡니다. GitHub Pages 는 /Rebind/ 아래에 있고
    # 나중에 다른 곳으로 옮겨도 그대로 맞습니다.
    'start_url': 'bindery.html',
    'scope': './',
    'display': 'standalone',
    'orientation': 'portrait',
    'background_color': '#F2F4F6',
    'theme_color': '#FFFFFF',
    'icons': [
        {'src': 'icon-192.png', 'sizes': '192x192', 'type': 'image/png', 'purpose': 'any'},
        {'src': 'icon-512.png', 'sizes': '512x512', 'type': 'image/png', 'purpose': 'any'},
        {'src': 'icon-maskable-512.png', 'sizes': '512x512', 'type': 'image/png', 'purpose': 'maskable'},
    ],
}
p = os.path.join(HERE, 'manifest.webmanifest')
io.open(p, 'w', encoding='utf-8').write(json.dumps(MANIFEST, ensure_ascii=False, indent=2) + '\n')
print('만들었습니다: manifest.webmanifest')
