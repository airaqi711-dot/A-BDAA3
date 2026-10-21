-- نفّذ هذا الملف مرة واحدة في Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.admins (
 user_id uuid primary key references auth.users(id) on delete cascade
);
create table if not exists public.orders (
 id bigint generated always as identity primary key,
 customer_name text not null check (char_length(trim(customer_name)) between 1 and 120),
 phone text not null check (char_length(trim(phone)) between 7 and 20),
 address text not null check (char_length(trim(address)) between 1 and 1000),
 notes text not null default '' check (char_length(notes) <= 2000),
 image_path text not null unique,
 status text not null default 'جديد' check (status in ('جديد','قيد التجهيز','تم التوصيل','ملغي')),
 created_at timestamptz not null default now()
);

alter table public.admins enable row level security;
alter table public.orders enable row level security;

create policy "admin can see own admin row" on public.admins for select to authenticated using (user_id = (select auth.uid()));
create policy "admins can read orders" on public.orders for select to authenticated using (exists (select 1 from public.admins where user_id = (select auth.uid())));
create policy "admins can update orders" on public.orders for update to authenticated using (exists (select 1 from public.admins where user_id = (select auth.uid()))) with check (exists (select 1 from public.admins where user_id = (select auth.uid())));
create policy "admins can delete orders" on public.orders for delete to authenticated using (exists (select 1 from public.admins where user_id = (select auth.uid())));

insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('order-images','order-images',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public=false,file_size_limit=5242880,allowed_mime_types=array['image/jpeg','image/png','image/webp'];

-- يسمح للزائر برفع صورة باسم UUID فقط، دون عرض الصور الخاصة.
create policy "visitors upload order image" on storage.objects for insert to anon,authenticated
with check (bucket_id='order-images' and name ~ '^[0-9a-fA-F-]{36}[.](jpg|png|webp)$');
create policy "admins view order images" on storage.objects for select to authenticated
using (bucket_id='order-images' and exists (select 1 from public.admins where user_id=(select auth.uid())));
create policy "admins delete order images" on storage.objects for delete to authenticated
using (bucket_id='order-images' and exists (select 1 from public.admins where user_id=(select auth.uid())));

-- دالة إدخال طلب دون السماح للزائر باستعراض بيانات الزبائن.
create or replace function public.submit_order(p_name text,p_phone text,p_address text,p_notes text,p_image_path text)
returns bigint language plpgsql security definer set search_path = '' as $$
declare new_id bigint;
begin
 if length(trim(coalesce(p_name,''))) not between 1 and 120
 or length(trim(coalesce(p_phone,''))) not between 7 and 20
 or length(trim(coalesce(p_address,''))) not between 1 and 1000
 or length(coalesce(p_notes,'')) > 2000
 or p_image_path !~ '^[0-9a-fA-F-]{36}[.](jpg|png|webp)$' then
 raise exception 'بيانات الطلب غير صحيحة';
 end if;
 if not exists (select 1 from storage.objects where bucket_id='order-images' and name=p_image_path) then
 raise exception 'صورة الطلب غير موجودة';
 end if;
 insert into public.orders(customer_name,phone,address,notes,image_path)
 values(trim(p_name),trim(p_phone),trim(p_address),coalesce(p_notes,''),p_image_path) returning id into new_id;
 return new_id;
end;$$;
revoke all on function public.submit_order(text,text,text,text,text) from public;
grant execute on function public.submit_order(text,text,text,text,text) to anon,authenticated;

-- بعد إنشاء مستخدم الإدارة في Authentication > Users، أضف UUID الخاص به:
-- insert into public.admins(user_id) values ('PUT_ADMIN_USER_UUID_HERE');
