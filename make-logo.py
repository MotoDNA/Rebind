# DNA Labs 마크를 앱에 넣습니다.
#
# 2026-08-30 부터는 그림을 **그리지 않고** 받아 온 원본(logo-source.png)을 씁니다.
# 그 전까지는 이 파일이 Helvetica 로 DNA·LABS 를 직접 그렸습니다.
# 그 코드가 필요하면 git 기록에서 꺼내 쓰세요 (213fe51 이전).
#
# 그림을 앱 파일 안에 박아 두는 이유: 브라우저 탭 아이콘과 홈 화면 아이콘은
# PNG 만 받습니다. 앱 안에서도 같은 그림을 써야 어디서 보든 같아집니다.
#
# 안드로이드 홈 화면에 얹을 때 쓰는 아이콘과 manifest 도 함께 만듭니다.
# 안드로이드 크롬은 apple-touch-icon 을 보지 않고 manifest 만 봅니다.
# 그래서 manifest 가 없으면 홈 화면에 얹어도 마크가 안 나오고
# 크롬 기본 조각 아이콘이 붙습니다.
#
#   python3 ~/Desktop/Rebind/make-logo.py        어느 폴더에서 불러도 됩니다
#   python3 ~/Desktop/Rebind/make-logo.py 512    logo.png 을 더 크게
import sys, os
from PIL import Image, ImageDraw

HERE   = '/Users/motodna/Desktop/Rebind'
SOURCE = os.path.join(HERE, 'logo-source.png')
OUT    = os.path.join(HERE, 'logo.png')
N      = int(sys.argv[1]) if len(sys.argv) > 1 else 180
SS     = 4                       # 크게 다듬은 뒤 줄여서 가장자리를 부드럽게


def find_ring(im):
    """원본에서 테두리 링의 자리를 찾습니다.

       원본은 남색 네모 배경 한가운데에 원이 그려져 있습니다. 앱은 원만
       필요하므로 그 원을 찾아 잘라내야 합니다.

       링은 밝기 85 쯤, 배경은 22 쯤, 흰 글자는 250 쯤입니다.
       가운데 가로줄·세로줄에서 가장 밝은 지점을 링의 한가운데로 봅니다.
       바깥 가장자리까지 담으려면 링 두께의 절반을 더 넓혀야 합니다."""
    g = im.convert('L')
    w, h = g.size
    px = g.load()
    cx, cy = w // 2, h // 2
    peak = lambda vals: max(vals, key=lambda t: t[1])[0]
    lo, hi = int(w * 0.12), int(w * 0.26)
    l = peak([(x, px[x, cy]) for x in range(lo, hi)])
    r = peak([(x, px[x, cy]) for x in range(w - hi, w - lo)])
    t = peak([(y, px[cx, y]) for y in range(lo, hi)])
    b = peak([(y, px[cx, y]) for y in range(h - hi, h - lo)])
    return l, t, r, b


def mark(size, square=False):
    """마크를 만들어 돌려줍니다.

       square=True 면 원 대신 네모를 꽉 채웁니다 — 안드로이드가 제 모양대로
       (원·사각·물방울) 잘라 쓰는 아이콘(maskable)이라, 원을 그려 두면
       두 번 잘려 글자까지 먹힙니다. 원 지름의 1.25 배로 잘라 두면
       안드로이드가 어떻게 잘라도 원이 온전히 남습니다(안전지대 80%).

       ⚠ 원본의 링은 정원이 아니라 852×893 타원입니다(그림을 만들 때 생긴
         일그러짐). 앱은 이 그림을 `border-radius:50%` 로 정원으로 잘라
         쓰기 때문에, 타원인 채로 넣으면 테두리가 원 밖으로 삐져나가거나
         안쪽에서 떠 보입니다. 그래서 타원을 네모로 눌러 정원으로 폅니다.
         세로가 4.6% 줄어들지만 100px 안팎으로 보는 크기에서는 안 보이고,
         테두리가 어긋나는 쪽이 훨씬 눈에 띕니다."""
    src = Image.open(SOURCE).convert('RGBA')
    l, t, r, b = find_ring(src)
    pad = round((r - l) * 0.012)          # 링 바깥선까지 담을 여유

    if square:
        # 원 지름의 1.25 배를 배경째로 잘라 냅니다
        cx, cy = (l + r) / 2, (t + b) / 2
        half = max(r - l, b - t) * 0.625
        box = (round(cx - half), round(cy - half), round(cx + half), round(cy + half))
        # 배경 그라데이션이 계단처럼 끊기지 않게 색을 넉넉히 줍니다
        return slim(src.crop(box).resize((size, size), Image.LANCZOS), 128)

    w = size * SS
    im = src.crop((l - pad, t - pad, r + pad, b + pad)).resize((w, w), Image.LANCZOS)

    # 원 바깥은 비웁니다. 앱이 흰 상단바 위에도 이 그림을 얹기 때문에
    # 네모 배경이 남아 있으면 그 자리만 남색 네모가 됩니다.
    m = Image.new('L', (w, w), 0)
    ImageDraw.Draw(m).ellipse([0, 0, w - 1, w - 1], fill=255)
    im.putalpha(m)
    return slim(im.resize((size, size), Image.LANCZOS))


def slim(im, colors=48):
    """색 수를 줄입니다.

       원본은 그림으로 만들어진 것이라 눈에 안 보이는 잡티와 옅은 그라데이션이
       가득합니다. 그대로 쓰면 180px 한 장이 34KB 이고, 앱마다 세 곳에
       글자로 박히니 파일이 134KB 씩 무거워집니다. 폰에서 그대로 내려받는 짐입니다.

       마크는 사실상 검정·회색·흰색 셋뿐이라 48색이면 눈으로 차이가 안 납니다.
       34KB → 4KB 로 줄어듭니다. 예전에 그려서 만들던 것(12KB)보다도 가볍습니다."""
    return im.quantize(colors=colors, method=Image.FASTOCTREE).convert('RGBA')


mark(N).save(OUT)
print('만들었습니다:', OUT, N, 'x', N)

# ── 만든 그림을 앱 파일에 박아 넣습니다 ──
# 두 앱은 파일 하나로 도는 앱이라 그림도 그 안에 들어 있어야 합니다.
# 앱마다 세 곳에 같은 값이 들어갑니다: 홈 화면 아이콘 · 탭 아이콘 · 화면 안의 로고
#
# 한동안 Re:Call 이 예전 마크를 따로 쓰고 있었습니다. 로그인 화면에 두
# 서비스를 나란히 놓으니 마크가 달라 보였습니다 — 같은 회사 마크인데
# 어느 쪽이 진짜인지 알 수 없습니다. 그래서 두 앱을 함께 다룹니다.
import base64, io, re

APPS = [
    '/Users/motodna/Desktop/Rebind/bindery.html',              # Re:Bind
    '/Users/motodna/Desktop/network-dna/network-dna.html',     # Re:Call
    '/Users/motodna/Desktop/Restore/store.html',               # Re:Store
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
# 아이폰은 위에서 앱 파일 안에 박아 넣은 apple-touch-icon 을 씁니다.
# 안드로이드 크롬은 그것을 보지 않고 manifest 의 icons 만 봅니다.
import json

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
    # 상대 주소로 둡니다. 나중에 다른 곳으로 옮겨도 그대로 맞습니다.
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


# ── 회사 홈페이지(dnalabs.kr) ──
# 홈페이지는 앱과 달리 파일 하나가 아니라 web/ 폴더입니다.
# 그림을 따로 두고 여러 쪽이 함께 봅니다.
#
# 파비콘이 오래도록 **파란 네모에 D** 였습니다. 회사 마크와 아무 상관이
# 없는 그림이라 탭에 떠 있으면 다른 회사 사이트처럼 보였습니다.
#
# 파일 이름을 favicon.png 로 바꾸지 않고 favicon.svg 안에 그림을 넣는 이유:
# 일곱 쪽이 favicon.svg 를 가리키고 있어서, 이름을 바꾸면 그 일곱 군데를
# 다 고쳐야 합니다. 한 군데라도 빠뜨리면 그 쪽만 아이콘이 사라집니다.
WEB = '/Users/motodna/Desktop/network-dna/web'
if os.path.isdir(WEB):
    p = os.path.join(WEB, 'logo.png')
    mark(192).save(p)                    # 공유카드가 46px 로 씁니다. 192 면 넉넉합니다
    print('만들었습니다: web/logo.png')

    # 파비콘은 쪽마다 받아 갑니다. 16~32px 로 보이므로 96px 이면 충분하고,
    # 180px 을 넣으면 파비콘 하나가 몇십 KB 가 됩니다.
    fav = io.BytesIO(); mark(96).save(fav, format='PNG')
    f96 = base64.b64encode(fav.getvalue()).decode()
    svg = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">'
           '<image href="data:image/png;base64,' + f96 + '" width="96" height="96"/>'
           '</svg>\n')
    io.open(os.path.join(WEB, 'favicon.svg'), 'w', encoding='utf-8').write(svg)
    print('만들었습니다: web/favicon.svg (마크를 담았습니다)')
else:
    print('건너뜁니다 (폴더 없음): web/')
