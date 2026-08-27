-- ═══════════════════════════════════════════════════════════════
-- Re:Bind — 정산 체크 (청구서 발송 · 세금계산서 발행 · 수금)
--
-- 켜고 끄는 값(boolean)이 아니라 날짜로 둡니다.
-- "했다/안 했다"만 남기면 나중에 "언제 청구했더라", "수금이 며칠째지"
-- 를 셀 수 없습니다. 비어 있으면 아직 안 한 것입니다.
-- ═══════════════════════════════════════════════════════════════

alter table public.projects
  add column if not exists billed_on date,   -- 청구서 발송
  add column if not exists taxed_on  date,   -- 전자세금계산서 발행
  add column if not exists paid_on   date;   -- 수금

-- 월말에 "납품은 됐는데 아직 못 받은 것" 을 자주 훑습니다
create index if not exists projects_unpaid_idx
  on public.projects(company_id, done_on)
  where not deleted and kind='project' and paid_on is null;
