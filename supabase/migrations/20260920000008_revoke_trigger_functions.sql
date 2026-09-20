-- Le funzioni dei trigger non devono essere richiamabili via RPC.
revoke execute on function public.plans_after_insert_points() from public, anon, authenticated;
revoke execute on function public.plans_before_delete_points() from public, anon, authenticated;
revoke execute on function public.votes_points() from public, anon, authenticated;
