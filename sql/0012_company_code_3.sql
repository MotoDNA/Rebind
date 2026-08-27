-- ═══════════════════════════════════════════════════════════════
-- 회사 코드를 세 글자부터 받습니다
--
-- 지금까지 4~12자만 받았습니다. 처음 정할 때 별 근거 없이 잡은 값인데,
-- BKT 처럼 세 글자인 회사 이름은 흔합니다. 로그인할 때 치는 값이라
-- 짧을수록 좋고, 비밀이 아니라 어느 회사 자료를 볼지 고르는 이름일 뿐입니다.
-- (비밀은 비밀번호가 맡습니다)
--
-- 느슨하게 푸는 것이라 이미 있는 줄은 하나도 어긋나지 않습니다.
--
-- ⚠ 이 표는 Re:Call 과 함께 씁니다. 앱 쪽에도 같은 규칙이 하나 더 있습니다 —
--   network-dna/supabase/functions/admin-user/index.ts 의 CODE_RE.
--   거기서 회사를 새로 만들 때만 쓰이므로 로그인에는 영향이 없지만,
--   앞으로 세 글자 회사를 앱에서 만들려면 그것도 같이 풀어야 합니다.
-- ═══════════════════════════════════════════════════════════════
alter table public.companies drop constraint if exists companies_code_fmt;
alter table public.companies add  constraint companies_code_fmt
  check (code ~ '^[A-Z0-9]{3,12}$');
