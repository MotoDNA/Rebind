---
name: rebind
description: Re:Bind(제본소 공정·거래명세서 앱) 작업을 이어서 합니다. bindery.html 을 고치거나, Supabase 표·서버 함수를 손대거나, 운영(GitHub Pages)에 올리거나, 시연 자료를 넣을 때 씁니다. "리바인드 이어서", "제본소 앱", "bindery.html", "청구서/견적서/명세서 고쳐줘" 같은 말에서 부릅니다.
---

# Re:Bind — 이어서 작업하기

제본소(BKT)가 쓰는 앱입니다. 공정을 기록하고, 고객사는 링크로 진행도를 보고,
끝나면 거래명세서·청구서·견적서를 뽑습니다.

**운영** https://rebind.dnalabs.kr/ · **저장소** https://github.com/MotoDNA/Rebind

## 먼저 읽을 것

`진행상황.md` 에 지금까지 무엇을 왜 그렇게 만들었는지 전부 있습니다. **작업 전에 반드시 읽습니다.**

## 구조

```
bindery.html      앱 전부. 이 파일 하나입니다 (HTML+CSS+JS 한 덩어리, 5천 줄쯤)
                  직원 화면과 고객사 화면이 같은 파일입니다.
                  주소에 ?t=토큰 이 붙으면 고객사 화면으로 갈립니다.
sql/000N_*.sql    표 만들기. 순서대로 번호가 붙습니다
supabase/functions/
  share-view/     고객사 공개 링크를 읽어 줍니다 (--no-verify-jwt)
  read-order/     작업의뢰서 사진을 읽어 칸을 채웁니다
make-logo.py      DNA Labs 마크를 그려 bindery.html 에 박아 넣습니다
```

Re:Call(`~/Desktop/network-dna`)과 **같은 Supabase 프로젝트, 같은 로그인**을 씁니다.
Re:Call 은 건드리지 않습니다. 로고도 서로 다릅니다.

## 접속

```
Project ref  izrtclsqhsgkuwsffifn
회사코드     ACTIVA / 아이디 admin
```

`supabase` CLI 가 이미 link 되어 있습니다. **SQL 을 직접 돌릴 수 있습니다.**

```bash
cd /Users/motodna/Desktop/Rebind
supabase db query --linked "select ..."            # 읽기·쓰기 모두
supabase db query --linked -f sql/0009_xxx.sql     # 새 표 적용
supabase functions deploy read-order  --project-ref izrtclsqhsgkuwsffifn
supabase functions deploy share-view  --no-verify-jwt --project-ref izrtclsqhsgkuwsffifn
```

`share-view` 는 `--no-verify-jwt` 를 빠뜨리면 고객사가 링크를 못 엽니다.

## 고칠 때 지키는 것

**1. 문법 검사만으로는 부족합니다.** 한 파일이라 `node --check` 로 걸러지지 않는
초기화 순서 오류(TDZ)가 납니다. 실제로 한 번 앱이 안 열린 적이 있습니다.

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
```

**2. 반드시 브라우저로 열어 봅니다.** 로컬(`python3 -m http.server 8791`)에 띄우고
`me`·`prjs`·`allSteps` 를 손으로 넣어 화면을 그려 본 뒤, 콘솔 오류까지 봅니다.
로그인이 필요한 부분은 `sb` 를 흉내 낸 객체로 막아 두고 화면만 확인합니다.

**3. 올린 뒤에도 열어 봅니다.** 글자만 grep 하지 말고 운영 주소를 실제로 띄워
콘솔을 봅니다. GitHub Pages 는 반영에 1~2분 걸립니다.

**4. 파이썬으로 고칩니다.** 파일이 커서 통째로 다시 쓰지 않습니다.
`python3` 에서 `assert old in s` 로 자리를 확인하고 `replace(old,new,1)` 합니다.

## 말투와 코드 주석

한국어로 씁니다. **무엇을 했는지가 아니라 왜 그렇게 했는지**를 적습니다.
과장하지 않고, 안 된 것은 안 됐다고 적습니다. 사용자는 개발자가 아닙니다 —
전문 용어를 쓸 때는 무엇인지 한 줄로 풀어 줍니다.

커밋 메시지도 같은 결로 씁니다. 제목은 무엇을 고쳤는지, 본문은 왜 그랬는지.
끝에 `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.

## 데이터 모양

`projects` 한 표에 프로젝트와 견적서가 함께 있고 `kind` 로 가릅니다.
표를 나누면 "견적을 프로젝트로 옮기기" 가 표 사이를 건너다니는 일이 되고
서류 그리는 코드도 두 벌이 되기 때문입니다.

| 칸 | |
|---|---|
| `kind` | project · quote |
| `spec_paper_cover` / `spec_paper_inner` | 표지·내지 용지 (예전 `spec_paper` 도 그대로 보여 줍니다) |
| `options` jsonb | 사용자가 이름부터 직접 적는 항목 |
| `extra_items` jsonb | 명세서에 줄로 붙는 추가 품목 |
| `arrivals` jsonb | 자재 입고 `[{n,s,on}]`. `on` 이 비면 아직 안 들어온 것 |
| `billed_on` / `taxed_on` / `paid_on` | 정산 세 단계. 날짜로 둡니다 (체크만 하면 며칠째인지 못 셉니다) |
| `share_token` / `share_on` | 고객사 공개 링크 |
| `order_photo` | 작업의뢰서 원본. 완성본 사진(`photos`)과 따로 — 그건 명세서에 나갑니다 |

`client_favorites` 는 사람 단위입니다.

## 권한

관리자만: 금액 · 내부 메모 · 고객사 공유 · 거래명세서 · 청구서 · 견적서 · 정산 · 묶어서 청구.

⚠ **화면에서 가리는 것뿐입니다.** 데이터베이스는 회사 사람 모두에게 금액 칸을
내려 줍니다. 진짜로 막으려면 금액을 딴 표로 빼야 합니다. 아직 안 했습니다.

## 시연 자료

`b2000000-…` 으로 시작하는 10건, `a1000000-…` 으로 시작하는 3건이 들어 있습니다.

```bash
supabase db query --linked "delete from projects where id like 'b2000000-%'"
```
