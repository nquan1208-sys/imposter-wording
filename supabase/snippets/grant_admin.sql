insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'nquan1208@gmail.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;