# DNA Labs 마크를 그립니다.
#
# 원 한가운데에 DNA, 그 아래 빈 공간에 LABS.
# 글자를 그림에 박아 두는 이유: 브라우저 탭 아이콘과 홈 화면 아이콘은
# PNG 만 받습니다. 앱 안에서도 같은 그림을 써야 어디서 보든 같아집니다.
#
#   python3 make-logo.py            → logo.png (180×180)
#   python3 make-logo.py 512        → 큰 것도 만들 수 있습니다
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

img  = Image.new('RGBA', (W, W), (0, 0, 0, 0))
d    = ImageDraw.Draw(img)
d.ellipse([0, 0, W - 1, W - 1], fill=BG)

f_dna  = ImageFont.truetype(FONT, int(DNA_SIZE  * k), index=BOLD)
f_labs = ImageFont.truetype(FONT, int(LABS_SIZE * k), index=BOLD)

# DNA 를 원 한가운데에 — 글자 윗선과 밑선의 중간이 원의 중심에 오도록 기준선을 내립니다
dna_base = (48 + 0.72 * DNA_SIZE / 2) * k
tracked(d, 'DNA',  f_dna,  DNA_TRACK  * k, W / 2, dna_base,        (255, 255, 255, 255))
tracked(d, 'LABS', f_labs, LABS_TRACK * k, W / 2, LABS_BASE * k,   (255, 255, 255, 235))

img.resize((N, N), Image.LANCZOS).save(OUT)
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
