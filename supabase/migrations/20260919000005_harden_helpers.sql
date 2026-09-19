-- Hardening dai security advisor: search_path fisso, niente RPC anonima.
alter function public.default_group_id() set search_path = public;
revoke execute on function public.current_group_id() from public, anon;
grant execute on function public.current_group_id() to authenticated;
