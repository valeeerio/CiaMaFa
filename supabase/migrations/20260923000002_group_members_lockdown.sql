-- sync_group_membership() è una funzione trigger, non va chiamata via RPC:
-- revocata anche da authenticated (dimenticato nella migrazione precedente),
-- come per le altre funzioni trigger pure (plans_before_delete_notify, ecc.).
revoke execute on function public.sync_group_membership() from authenticated;
