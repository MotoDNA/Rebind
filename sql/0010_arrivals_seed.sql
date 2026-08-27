-- ═══════════════════════════════════════════════════════════════
-- 입고에 표지·내지 두 줄을 기본으로 놓습니다
--
-- 제본소에 오는 종이는 표지와 내지가 기본입니다. 지금까지는 "사양에서
-- 가져오기" 를 눌러야 줄이 생겼는데, 누르지 않으면 입고 칸이 계속 비어
-- 있었습니다. 앞으로 만드는 프로젝트는 앱이 두 줄을 넣어 주고,
-- 이미 있는 것들은 여기서 한 번 채워 둡니다.
--
-- 사양에 적힌 용지가 있으면 그 값을, 없으면 빈칸으로 둡니다.
-- 빈칸은 입고 화면에서 바로 칠 수 있습니다 (평량을 적을 데가 거기뿐입니다).
-- 이미 줄이 있는 프로젝트와 견적서는 건드리지 않습니다.
-- ═══════════════════════════════════════════════════════════════
update public.projects p
   set arrivals = jsonb_build_array(
         jsonb_build_object('n','표지 용지','s',coalesce(nullif(p.spec_paper_cover,''),''),'on',null),
         jsonb_build_object('n','내지 용지','s',coalesce(nullif(p.spec_paper_inner,''), nullif(p.spec_paper,''),''),'on',null)
       )
 where coalesce(p.kind,'project') = 'project'
   and not p.deleted
   and coalesce(jsonb_array_length(p.arrivals), 0) = 0;
