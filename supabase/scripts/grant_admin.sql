-- Chạy sau khi Auth user đã tồn tại trong cùng Supabase project.
-- Thay email bên dưới bằng email admin thật trước khi chạy.

insert into public.admin_users (user_id, role, is_active)
select id, 'admin', true
from auth.users
where email = 'admin@example.com'
on conflict (user_id) do update
set role = 'admin',
    is_active = true;
