# dnalabs.kr 아래로 두 앱을 모으기

## 왜

브라우저는 로그인한 흔적을 **주소마다 따로** 보관합니다.
`rebind.dnalabs.kr` 에서 로그인해도 `recall.dnalabs.kr` 은 그것을 못 봅니다.
남의 주소 보관함을 읽는 것은 브라우저가 막습니다 — 그래야 아무 사이트나
내 은행 로그인을 훔쳐보지 못합니다.

두 앱을 **한 주소 아래**로 두면 그 흔적을 나눠 씁니다.
한 번 로그인하면 둘 다 열리고, 서로 건너뛸 때 다시 묻지 않습니다.

```
dnalabs.kr/bind   →  Re:Bind
dnalabs.kr/call   →  Re:Call
```

파일은 지금 저장소에 그대로 둡니다. Vercel 이 그 주소로 **비춰 주기만**
합니다(rewrite — 주소는 안 바뀌고 내용만 가져옵니다).
GitHub Pages 배포 방식도 그대로입니다.

## 올릴 것 — 세 가지

1. **`vercel.json` 의 `rewrites` 두 줄**
   지금 쓰시는 `web/vercel.json` 에 `rewrites` 항목을 더하세요.
   이 폴더의 `vercel.json` 은 그 두 줄만 담은 예시입니다.
   **기존 `headers` · `cleanUrls` 설정은 지우지 말고 그대로 두세요.**

2. **`bind.webmanifest`** — 홈 화면에 깔 때 쓰는 설명서입니다.
   Vercel 이 내보내는 폴더(`web/`) 맨 위에 그대로 두면
   `dnalabs.kr/bind.webmanifest` 로 열립니다.
   Re:Call 은 아직 홈 화면 설치를 안 쓰므로 `call.webmanifest` 는 없습니다.

3. 올린 뒤 **`https://dnalabs.kr/bind`** 와 **`/call`** 을 열어 보세요.

## 이미 해 둔 것

- `ALLOWED_ORIGIN` 에 `https://dnalabs.kr` 을 더하고 함수 넷을 다시 배포했습니다
  (`share-view` · `read-order` · `read-card` · `admin-user`).
  **옛 주소 둘도 그대로 남겨 두었습니다** — 하나만 적으면 다른 쪽이 멈춥니다.
- 두 앱이 자기가 어디에 놓였는지 스스로 알아봅니다.
  `/bind` · `/call` 로 열리면 한 지붕으로 보고 로그인을 나눠 쓰고,
  옛 주소로 열리면 지금까지처럼 굽니다.

## 옛 주소는 그대로 둡니다

`rebind.dnalabs.kr` 과 `recall.dnalabs.kr` 을 **끄지 마세요.**

- **고객사 공유 링크(`?t=`)가 이미 그 주소로 나가 있습니다.** 끄면 열리지 않습니다
- 폰 홈 화면에 깔아 둔 아이콘도 그 주소를 가리킵니다
- Vercel 이 그 주소에서 내용을 가져오므로, 끄면 새 주소도 함께 멈춥니다

새로 만드는 공유 링크는 **연 주소를 그대로 따릅니다** —
`/bind` 에서 만들면 `dnalabs.kr/bind?t=…` 가 됩니다.

## 잘 안 될 때

| 증상 | 볼 곳 |
|---|---|
| `/bind` 가 404 | `rewrites` 가 올라갔는지. Vercel 배포 로그 |
| 로그인이 저쪽으로 안 이어짐 | 주소창이 정말 `dnalabs.kr/bind` 인지. `rebind.dnalabs.kr` 로 튕겼다면 rewrite 가 아니라 redirect 로 걸린 것입니다 |
| 서버 함수 호출 실패 | `ALLOWED_ORIGIN` 에 `https://dnalabs.kr` 이 있는지. 바꾸면 함수 넷을 다시 배포해야 반영됩니다 |
