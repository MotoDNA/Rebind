-- ═══════════════════════════════════════════════════════════════
-- 고객사(공급받는자) 정보를 넓힙니다
--
-- 지금까지 고객사로 담고 있던 것은 상호 · 담당자 · 연락처 셋뿐이었습니다.
-- 거래명세서의 "공급받는자" 칸에 상호와 담당자만 찍히고, 정작 서류에서
-- 제일 먼저 확인하는 등록번호 자리가 비어 있었습니다.
--
-- 전자세금계산서를 붙일 생각이 없더라도 이 네 칸은 필요합니다.
-- 세금계산서를 끊으려면 공급받는자의 **사업자등록번호가 반드시** 있어야 하고,
-- 대표자 · 업태 · 종목은 서식에 들어가는 칸입니다.
-- 지금은 그 값이 사람 머릿속이나 딴 엑셀에 있습니다.
--
-- 거래처를 따로 표로 만들지 않는 이유는 client_favorites(0006) 와 같습니다.
-- 표를 하나 더 만들면 프로젝트의 client_company 와 늘 맞춰 두는 일이
-- 새로 생깁니다. 대신 화면에서 **지난 프로젝트의 값을 끌어와 미리 채웁니다** —
-- 같은 고객사를 다시 고르면 이 네 칸도 함께 따라옵니다.
--
-- client_email 은 이미 있습니다(세금계산서를 받을 곳). 화면에 칸이 없었을 뿐입니다.
--
-- 금액 표(project_money)로 보내지 않는 이유
--   등록번호 · 대표자 · 업태 · 종목은 거래명세서에 그대로 찍혀 고객사에도
--   나가는 값입니다. 단가처럼 회사 안에서 가릴 것이 아닙니다.
--   projects 에 두면 직원도 명세서를 그릴 수 있습니다.
-- ═══════════════════════════════════════════════════════════════
alter table public.projects
  add column if not exists client_biz_no   text,
  add column if not exists client_ceo      text,
  add column if not exists client_biz_type text,
  add column if not exists client_biz_item text;

comment on column public.projects.client_biz_no is
  '공급받는자 사업자등록번호. 숫자 10자리를 그대로 담습니다(하이픈 없이). '
  '화면에서 000-00-00000 으로 보여 줍니다. 세금계산서 발행에 반드시 필요합니다.';
comment on column public.projects.client_ceo is
  '공급받는자 대표자 이름';
comment on column public.projects.client_biz_type is
  '공급받는자 업태 (예: 도소매)';
comment on column public.projects.client_biz_item is
  '공급받는자 종목 (예: 문구)';

-- 접근 규칙은 손대지 않습니다. projects 의 정책을 그대로 따릅니다
-- (같은 회사 사람은 읽고, 담당자와 관리자가 씁니다 — 0015 · 0019).
