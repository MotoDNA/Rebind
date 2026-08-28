-- ═══════════════════════════════════════════════════════════════
-- 업종 — 회사마다 다른 말을 씁니다
--
-- 지금까지 앱은 "책 만드는 말" 로만 쓰여 있었습니다. 공정 순서에 접지·
-- 정합·제본이 박혀 있고, 자재 입고는 표지 용지·내지 용지로 시작하고,
-- 제조 상세에는 면수와 제본 방식이 있습니다. 제본소에는 맞지만 전단지를
-- 찍는 인쇄소에는 안 맞습니다. 안 쓰는 칸을 계속 비워 두고 써야 합니다.
--
-- 그래서 그 목록들을 코드에서 꺼내 회사 설정으로 옮깁니다.
--
--   trade   업종 이름. '제본소' · '인쇄소' 처럼 사람이 읽는 말입니다.
--           고르면 그 업종의 기본값이 preset 에 깔립니다. 그 뒤로는
--           회사가 자기 말로 고칩니다 — 업종은 시작점일 뿐입니다.
--
--   preset  이 회사가 실제로 쓰는 말. 비어 있으면 앱이 제본소 기본값을
--           씁니다(지금까지와 같습니다). 모양은 이렇습니다.
--             { "steps":   ["파일 입고","인쇄", …],
--               "arrivals":["표지 용지","내지 용지"],      ← 처음부터 놓이는 줄
--               "arrivalAdd":["면지","띠지", …],           ← 눌러서 더하는 것
--               "costs":  ["표지 인쇄","재단", …],
--               "labels": { "pages":"면수", "paperCover":"표지 용지", … } }
--
-- 왜 표를 새로 안 만들고 칸 하나(jsonb)에 담나
--   목록의 길이와 개수가 회사마다 다르고, 언제나 그 회사 설정과 함께만
--   읽습니다. 표로 나누면 화면 하나 그리는 데 조회가 여러 번 됩니다.
--   options·extra_items·arrivals 를 담을 때와 같은 판단입니다.
-- ═══════════════════════════════════════════════════════════════
alter table public.company_settings
  add column if not exists trade  text  not null default '',
  add column if not exists preset jsonb not null default '{}'::jsonb;

comment on column public.company_settings.trade  is
  '업종 이름. 고르면 preset 에 그 업종 기본값이 깔립니다. 시작점일 뿐입니다.';
comment on column public.company_settings.preset is
  '이 회사가 쓰는 말 {steps, arrivals, arrivalAdd, costs, labels}. 비면 제본소 기본값.';
