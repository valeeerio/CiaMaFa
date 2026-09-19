-- Gruppo unico dell'MVP (stesso UUID di public.default_group_id()).
insert into public.groups (id, name)
values ('00000000-0000-0000-0000-00000000c1a0', 'CiaMaFa')
on conflict (id) do nothing;
