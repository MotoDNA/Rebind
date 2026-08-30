# Re:Bind — 한 장으로 보는 전부

제본소·인쇄소가 쓰는 **제조 공정과 거래명세서** 앱입니다.
공정을 기록하고, 고객사는 링크로 진행도를 보고, 끝나면 거래명세서·청구서·견적서를 뽑습니다.

이 문서는 **지금 상태**만 적습니다. "언제 무엇을 왜 그렇게 했는가"는 [진행상황.md](진행상황.md)에
날짜순으로 있습니다. 설치는 [설치방법.md](설치방법.md).

*기준 2026-08-30*

---

## 1. 어디에 있나

| | |
|---|---|
| 운영 | **https://dnalabs.kr/bind** (권장) · https://rebind.dnalabs.kr/ (옛 주소, 살아 있음) |
| 저장소 | https://github.com/MotoDNA/Rebind — GitHub Pages, `main` 에 push 하면 1~2분 뒤 반영 |
| 폴더 | `~/Desktop/Rebind` |

**옛 주소를 끄지 마세요.** 고객사 공유 링크(`?t=`)가 이미 그 주소로 나가 있고,
`dnalabs.kr/bind` 는 그 주소에서 내용을 **가져다 비추는 것**(Vercel rewrite)이라
끄면 새 주소도 함께 멈춥니다.

---

## 2. 형제 서비스 셋

DNA Labs 가 만드는 서비스가 셋이고, **같은 Supabase 프로젝트·같은 계정 목록**을 씁니다.

| 서비스 | 하는 일 | 새 주소 | 옛 주소 | 폴더 |
|---|---|---|---|---|
| **Re:Bind** | 프로젝트별 공정 관리 | `dnalabs.kr/bind` | `rebind.dnalabs.kr` | `~/Desktop/Rebind` |
| **Re:Call** | 고객관리 | `dnalabs.kr/call` | `recall.dnalabs.kr` | `~/Desktop/network-dna` |
| **Re:Store** | 가맹점 발주·정산 | `dnalabs.kr/store` | `restore.dnalabs.kr` | `~/Desktop/Restore` |
| 회사 홈페이지 | | `dnalabs.kr` (Vercel) | | `~/Desktop/network-dna/web` |

**한 지붕 아래(`dnalabs.kr/*`)에서는 로그인을 나눠 씁니다.** 주소가 하나라
브라우저가 로그인 흔적을 함께 보기 때문입니다. 옛 주소끼리는 주소가 달라 못 나눕니다.

⚠ **셋이 얽혀 있는 것 셋** — 하나만 보고 고치면 다른 쪽이 멈춥니다.
1. `ALLOWED_ORIGIN` (아래 6장)
2. `companies.apps` (아래 5장)
3. 로그인 화면의 서비스 토글 — 세 앱이 같은 차례·같은 문구를 씁니다

---

## 3. 파일 구조

```
bindery.html          앱 전부. 이 파일 하나입니다 (HTML+CSS+JS 한 덩어리, 5,279줄 / 303KB)
                      직원 화면과 고객사 화면이 같은 파일입니다.
                      주소에 ?t=토큰 이 붙으면 고객사 화면으로 갈립니다.
index.html            bindery.html 로 넘겨 주기만 합니다 (?t= 를 실어서)
sql/000N_*.sql        표 만들기. 번호 순서대로 적용합니다 (0003~0019)
supabase/functions/
  share-view/         고객사 공개 링크를 읽어 줍니다 (--no-verify-jwt)
  read-order/         작업의뢰서 사진을 읽어 칸을 채웁니다
  _shared/cors.ts     두 함수가 함께 쓰는 CORS. Re:Call 쪽에도 같은 파일이 있습니다
make-logo.py          DNA Labs 마크를 세 앱과 홈페이지에 박아 넣습니다
logo-source.png       마크 원본 (이 그림을 잘라서 씁니다)
dnalabs-vercel/       dnalabs.kr 에 올릴 설정 (vercel.json · bind.webmanifest)
manifest.webmanifest  안드로이드 홈 화면 설치용 (make-logo.py 가 만듭니다)
```

### 화면 다섯 · 시트 열하나

| 탭 | id | |
|---|---|---|
| 프로젝트 | `p-list` | 목록·검색·상태칩·고르기 |
| 새로 만들기 | `p-new` | 프로젝트/견적서 겸용 |
| 현황 | `p-board` | 한눈에 보기 |
| 견적서 | `p-quote` | 관리자만 |
| 설정 | `p-set` | 계정·팀원·공개범위·공급자·업종 |

상세는 탭이 아니라 덮는 화면(`#detail`), 서류는 `#inv`,
고객사 공개 화면은 `#pub` 입니다.

시트: `sheetStep` `sheetSpec` `sheetMoney` `sheetShare` `sheetSettle`
`sheetMyPw` `sheetUser` `sheetSend` `sheetQuotePick` `sheetMore` `sheetPick`

---

## 4. 데이터 모양

`projects` **한 표에 프로젝트와 견적서가 함께** 있고 `kind` 로 가릅니다.
표를 나누면 "견적을 프로젝트로 옮기기" 가 표 사이를 건너다니는 일이 되고
서류 그리는 코드도 두 벌이 됩니다.

### projects

| 칸 | |
|---|---|
| `kind` | `project` · `quote` |
| `spec_paper_cover` / `spec_paper_inner` | 표지·내지 용지 (예전 `spec_paper` 도 그대로 보여 줍니다) |
| `options` jsonb | 사용자가 이름부터 직접 적는 항목 |
| `arrivals` jsonb | 자재 입고 `[{n,s,on}]`. `on` 이 비면 아직 안 들어온 것 |
| `share_token` / `share_on` | 고객사 공개 링크 |
| `order_photo` | 작업의뢰서 원본. 완성본 사진(`photos`)과 따로 — 그건 명세서에 나갑니다 |
| `hidden_on` | **숨김**. 목록·칩·현황·미수금에서 모두 빠집니다. `deleted` 와 다릅니다 |
| `quote_of` | 견적서에서 옮겨 온 프로젝트면 그 견적서 id |
| `deleted` | 지운 표시. 서버가 아예 안 내려 줍니다 |

### project_money — 금액은 딴 표입니다

`projects` 는 회사 사람 누구나 읽습니다. 금액을 거기 두면 화면에서 가려 봐야
데이터베이스가 그대로 내려 줍니다. 그래서 **표를 나눴고 그 표는 관리자만** 읽고 씁니다.

`unit_price` `vat_rate` `extra_items` `cost_items` `billed_on` `taxed_on` `paid_on` `memo`

- 정산 세 단계(`billed_on` 청구서 발송 · `taxed_on` 세금계산서 · `paid_on` 수금)는
  **날짜**입니다. 체크만 하면 며칠째 묵었는지 못 셉니다
- `cost_items` 는 견적 원가 내역. 총비용 ÷ 부수 로 부당 단가를 셈해 단가 칸에 넣습니다.
  **고객에게 나가는 종이에는 부당 단가만** 찍힙니다

### 그 밖

| 표 | |
|---|---|
| `project_steps` | 공정 기록. `percent` `at` `note` `photo_path` |
| `companies` | `code` `name` **`apps`**(5장) `disabled` |
| `company_settings` | 공급자 정보 · `vat_rate` · 직원 공개범위 3개 · **`trade`/`preset`**(7장) |
| `profiles` | 사람. `login_id` `name` `role`(admin/user) `disabled` |
| `client_favorites` | 거래처 즐겨찾기 — **사람 단위**입니다 |
| `audit_log` | 감사 기록 |

보관함(비공개 셋): `works`(Re:Bind) · `cards`(Re:Call) · `supply`(Re:Store).
경로가 곧 권한입니다 — `{회사id}/{프로젝트id}/{사진id}.jpg`

---

## 5. 누가 무엇을 볼 수 있나

### 회사 단위 — 어느 서비스를 샀나 (`companies.apps`)

```
apps text[]   {rebind} · {recall} · {restore} · 여러 개 가능
```

**비어 있으면 아무 데도 못 들어갑니다.** 새 회사를 만들 때 꼭 함께 넣으세요.
안 판 것까지 열리는 것보다 막히는 쪽이 낫습니다 — 막히면 바로 알아채지만
열려 있는 것은 아무도 모릅니다.

지금: `ACTIVA {rebind,recall}` · `BKT {rebind}` · `9DORO {restore}`

**화면이 아니라 데이터베이스가 막습니다.** 정책이 스무 개라 조건을 하나씩 늘려 쓰면
한 군데만 빠뜨려도 그 표가 열립니다. 함수 하나로 감쌌습니다.

```sql
company_for_app('rebind')   -- 산 서비스면 회사 id, 아니면 null
```

정책마다 `company_id = current_company_id()` 를 이것으로 바꿨습니다.
null 과의 비교는 참이 되지 않아 그대로 닫힙니다. (`sql/0019_apps.sql`)

| Re:Bind 의 표 | `projects` · `project_steps` · `project_money` · `client_favorites` |
|---|---|
| Re:Call 의 표 | `customers` · `activities` |
| 공용 | `companies` · `profiles` · `company_settings` · `audit_log` |

### 사람 단위 — 관리자와 직원

**관리자만:** 금액 · 내부 메모 · 고객사 공유 · 거래명세서 · 청구서 · 견적서 · 정산 · 묶어서 청구 · 계정 관리

**직원에게 열어 줄 수 있는 셋** (설정 → 직원에게 보일 것):
`staff_money` · `staff_settle` · `staff_memo`
화면에서만 가리는 게 아니라 **금액이 딴 표에 있어 서버가 아예 안 내려 줍니다**.
열어 주어도 **고치는 것은 관리자만** 입니다.

한 회사 안에서 "제본 직원에게 영업 고객을 감추기" 같은 **서비스별 사람 단위 구분은
아직 없습니다.** 그건 사람 단위 칸이 하나 더 있어야 합니다.

---

## 6. 접속과 서버

```
Project ref  izrtclsqhsgkuwsffifn
회사코드 BKT    / admin   ← 제본소 것 (프로젝트 8건)
회사코드 ACTIVA / admin   ← 시연 자료 (프로젝트 16건)
```

회사가 다르면 서로의 자료가 안 보입니다. 데이터베이스가 회사로 가릅니다.

`supabase` CLI 가 link 되어 있어 **SQL 을 직접 돌릴 수 있습니다.**

```bash
cd ~/Desktop/Rebind
supabase db query --linked "select ..."              # 읽기·쓰기 모두
supabase db query --linked -f sql/0020_xxx.sql       # 새 표 적용
supabase functions deploy read-order  --project-ref izrtclsqhsgkuwsffifn
supabase functions deploy share-view  --no-verify-jwt --project-ref izrtclsqhsgkuwsffifn
```

`share-view` 는 `--no-verify-jwt` 를 빠뜨리면 고객사가 링크를 못 엽니다.

### ⚠ ALLOWED_ORIGIN — 가장 자주 어긋나는 것

**네 서비스가 함께 쓰는 값 하나입니다.** 이 세션에서만 두 번 어긋났습니다.
한 번은 값이 안 들어갔고, 한 번은 `restore` 를 넣으면서 `dnalabs.kr` 이 빠졌습니다.
**틀려도 조용합니다** — 화면은 멀쩡히 뜨고 로그인도 되는데 서버 함수만 막힙니다.

```bash
supabase secrets set ALLOWED_ORIGIN="https://rebind.dnalabs.kr,https://recall.dnalabs.kr,https://restore.dnalabs.kr,https://dnalabs.kr" \
  --project-ref izrtclsqhsgkuwsffifn
```

바꾼 뒤 **함수 넷을 모두 다시 배포**해야 반영됩니다 —
`share-view` `read-order` (Re:Bind) · `read-card` `admin-user` (Re:Call, `~/Desktop/network-dna`).

**넣고 끝내지 말고 되읽어 확인하세요.**

```bash
curl -s -o /dev/null -D - -X OPTIONS \
  https://izrtclsqhsgkuwsffifn.supabase.co/functions/v1/share-view \
  -H "Origin: https://dnalabs.kr" -H "Access-Control-Request-Method: POST" \
  | grep -i access-control-allow-origin
# → 부른 주소가 그대로 돌아오면 통과, 다른 주소가 오면 막힌 것입니다
```

### 서버 함수 둘

| `share-view` | 고객사 링크를 토큰으로 확인하고 대신 읽어 줍니다. 로그인 없이 부릅니다.<br>금액은 `project_money` 에서 꺼내되 **정산일·내부메모는 빼고** 보냅니다.<br>사진은 한시적 주소로 서명해 주고, 다른 회사 폴더는 절대 서명하지 않습니다.<br>회사의 `preset` 도 함께 내려 줍니다 — 고객사도 같은 이름표를 봐야 합니다 |
|---|---|
| `read-order` | 작업의뢰서 사진을 Claude 로 읽어 칸을 채웁니다. 하루 한도가 있습니다.<br>지시문에 **부른 사람의 회사 상호·코드를 끼워 넣습니다** — 예전엔 "BKT" 가 박혀 있어서 다른 회사가 쓰면 자기 상호를 고객사로 읽었습니다 |

---

## 7. 업종별로 말을 바꿔 씁니다

앱이 "책 만드는 말" 로만 쓰여 있었습니다. 인쇄소는 안 쓰는 칸을 계속 비워 두고 써야 했습니다.
그 목록들을 코드에서 꺼내 **회사 설정으로 옮겼습니다.**

```
company_settings.trade    업종 이름 ('제본소' · '인쇄소')
company_settings.preset   이 회사가 실제로 쓰는 말 (jsonb)
                          { steps, arrivals, arrivalAdd, costs, labels, hints }
```

`TRADE_PRESETS`(`bindery.html:1577`)에 제본소·인쇄소 두 벌이 있고,
`tradeOf()`가 **회사 preset → 없으면 제본소 기본값**을 돌려줍니다. 화면은 그것만 봅니다.

업종을 하나 더 받으려면 `TRADE_PRESETS` 에 한 벌 더합니다.
**설정 → 업종과 용어** 에서 관리자가 목록 넷과 칸 이름표를 고칩니다.
업종은 시작 틀일 뿐 — 고른 뒤에는 회사가 자기 말로 씁니다.

**칸 이름은 이름표만 바뀝니다.** 인쇄소가 "용지" 라고 부르는 것도
데이터베이스에는 그대로 `spec_paper_cover` 로 들어갑니다.
칸 자체를 자유 항목으로 일반화하는 것은 훨씬 큰 일이라 안 했습니다.

지금 두 회사 다 `preset` 이 비어 있어 **제본소 기본값**으로 돕니다.

---

## 8. 로그인 화면

세 서비스 토글이 있습니다. 세 앱이 **같은 차례·같은 문구**를 씁니다 —
같은 자리를 눌렀는데 다른 것이 골라지면 안 됩니다.

```js
const APPS     = ['rebind','recall','restore'];        // 차례가 곧 토글의 차례
const ONE_ROOF = {rebind:'/bind', recall:'/call', restore:'/store'};
const AWAY     = {rebind:'https://rebind.dnalabs.kr/', ...};
const underOneRoof = ONE_ROOF[APP_KEY] === location.pathname.replace(/\/+$/,'');
```

서비스가 늘면 **세 파일에서 이 표에 한 줄씩** 더하면 됩니다.

| 어디서 열렸나 | 다른 것을 고르면 |
|---|---|
| `dnalabs.kr/bind` | **로그인 칸이 그대로.** 여기서 로그인하고 그쪽으로 넘어갑니다 |
| `rebind.dnalabs.kr` | 칸을 감추고 이동 단추만. 흔적을 못 넘기니 **엉뚱한 앱에 비밀번호를 치면 안 됩니다** |

- 고른 것은 기기에 남습니다(`localStorage['dnalabs-app']`). 한 지붕이면 세 앱이 함께 봅니다
- 안 산 것을 고르고 로그인하면 → 토글을 되돌리고 "○○ 를 쓰는 회사가 아닙니다"
- 산 것이 옆에 있으면 → 내쫓지 않고 그리로 보내고, `sessionStorage` 로 이유를 넘겨 알려 줍니다
- PC(가로 900 · 세로 600 이상)는 두 칸으로 펼칩니다. 왼쪽 마크+토글, 오른쪽 로그인 칸

**로그인 정보는 세 서비스가 똑같습니다** — 회사 코드·아이디·비밀번호 한 벌.
`아이디@회사코드.ndna.invalid` 로 만든 이메일로 Supabase 에 로그인합니다.
로그인 보관 자리도 셋 다 `ndna-auth` 로 같습니다.

---

## 9. 고칠 때 지키는 것

**1. 문법 검사만으로는 부족합니다.** 한 파일이라 `node --check` 로 안 걸러지는
초기화 순서 오류(TDZ)가 납니다. 실제로 앱이 안 열린 적이 있습니다.

```bash
# 문법
python3 -c "
import io,re
s=io.open('bindery.html',encoding='utf-8').read()
io.open('/tmp/app.js','w',encoding='utf-8').write(re.findall(r'<script>(.*?)</script>',s,re.S)[-1])
" && node --check /tmp/app.js

# id 빠뜨린 것
python3 -c "
import io,re
s=io.open('bindery.html',encoding='utf-8').read()
ids=set(re.findall(r'\bid=\"([^\"]+)\"',s)); used=set(re.findall(r\"\\\$\\('([^']+)'\\)\",s))
print(sorted(u for u in used if u not in ids))"
# readNote 는 화면에서 만들어지는 것이라 정상입니다
```

**2. 반드시 브라우저로 열어 봅니다.** `python3 -m http.server` 로 띄우고
`me`·`prjs`·`allSteps` 를 손으로 넣어 화면을 그려 본 뒤 콘솔까지 봅니다.
로그인이 필요한 부분은 `sb` 를 흉내 낸 객체로 막아 두고 화면만 확인합니다.
한 지붕 동작을 볼 때는 `/bind`·`/call`·`/store` 를 한 주소에서 내려 주는
작은 서버를 띄웁니다(그래야 `underOneRoof` 가 켜집니다).

**3. 올린 뒤에도 열어 봅니다.** 글자만 grep 하지 말고 운영 주소를 띄워 콘솔을 봅니다.
GitHub Pages 는 1~2분 걸리고, **브라우저가 옛 파일을 한동안 보여 줍니다** —
안 바뀐 것 같으면 주소 뒤에 `?v=2` 를 붙여 보세요.

**4. 파이썬으로 고칩니다.** 파일이 커서 통째로 다시 쓰지 않습니다.
`assert old in s` 로 자리를 확인하고 `replace(old,new,1)` 합니다.

---

## 10. 배포

| 무엇 | 어떻게 |
|---|---|
| 앱 (`bindery.html`) | `git push` → GitHub Pages 1~2분 |
| 서버 함수 | `supabase functions deploy …` (위 6장) |
| SQL | `supabase db query --linked -f sql/00NN_….sql` |
| 홈페이지 · rewrite | `cd ~/Desktop/network-dna && npx vercel --prod --scope chhanj40-5991s-projects` |
| 로고 | `python3 ~/Desktop/Rebind/make-logo.py` → 세 앱과 홈페이지 파비콘까지. **저장소 셋을 각각 커밋** |

`--scope` 를 빼면 `Not authorized` 가 납니다 — `.vercel/project.json` 의 `orgId` 와
로그인 계정의 팀 이름이 달라서입니다.

`dnalabs.kr/bind` 는 rewrite 라 **GitHub Pages 만 반영되면 함께 바뀝니다.**
Vercel 을 다시 배포할 필요가 없습니다.

---

## 11. 함정 모음

| | |
|---|---|
| `ALLOWED_ORIGIN` | 넷을 다 적고 **되읽어 확인**. 틀려도 조용합니다 (6장) |
| 옛 주소 끄기 | 끄면 공유 링크가 죽고 새 주소도 함께 멈춥니다 |
| `id::text` | `projects.id` 가 uuid 라 `like` 를 쓰려면 `::text` 를 붙여야 합니다 |
| `companies` 조인 | 그냥 붙이면 후보가 둘(`client_favorites` 때문)이라 서버가 300 을 돌려줍니다. `companies!profiles_company_id_fkey` 로 못 박습니다 |
| 새 회사 | `apps` 를 꼭 함께 넣으세요. 안 넣으면 아무도 못 들어갑니다 |
| 금액 | 화면에서 가리는 것으로는 부족합니다. `project_money` 로 나눠 두었으니 그 원칙을 깨지 마세요 |
| 플렉스 가운데정렬 | `align-items:center` 는 넘친 부분에 스크롤이 안 닿습니다. `margin:auto` 를 씁니다 |

---

## 12. 시연 자료 지우기

```bash
# ACTIVA 것 (예전 시연 자료)
supabase db query --linked "delete from projects where id::text like 'b2000000-%'"
# BKT 것 (2026-08-28 에 넣은 예시 다섯 건)
supabase db query --linked "delete from projects where id::text like 'c3000000-%'"
```

금액과 공정 기록은 딸려서 같이 지워집니다.

---

## 13. 아직 안 한 것

- **회사 개설 화면이 없습니다.** `SETUP_SECRET` 을 아는 사람만 손으로 엽니다
- **`read-order` 지시문 본문이 제본소 말입니다** (면수·제본 방식·면지…).
  인쇄소 의뢰서 샘플이 없어 손대면 넘겨짚는 일이 됩니다
- **업종을 화면에서 새로 만들 수는 없습니다.** `TRADE_PRESETS` 에 코드로 더합니다
- **한 회사 안에서 사람마다 서비스를 가르는 것** — 사람 단위 칸이 하나 더 있어야 합니다
- **셋을 다 산 회사**가 생기면 "어디로 갈까요" 를 물어야 합니다. 지금은 첫 번째로 보냅니다
- **공급자 정보가 아직 예시입니다.** 설정 → 공급자 정보를 관리자 계정으로 채워야
  거래명세서 왼쪽 "공급자" 칸이 찹니다
- **백업이 하나**라 한 회사 자료만 되돌릴 방법이 없습니다

---

## 14. 말투

한국어로 씁니다. **무엇을 했는지가 아니라 왜 그렇게 했는지**를 적습니다.
과장하지 않고, 안 된 것은 안 됐다고 적습니다.
사용자는 개발자가 아닙니다 — 전문 용어를 쓸 때는 무엇인지 한 줄로 풀어 줍니다.
커밋 메시지도 같은 결로. 제목은 무엇을 고쳤는지, 본문은 왜 그랬는지.
