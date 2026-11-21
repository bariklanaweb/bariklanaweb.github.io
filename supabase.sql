-- BARIKLANA: jalankan di Supabase > SQL Editor
create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  price numeric(14,2) not null default 0 check (price >= 0),
  stock integer not null default 0 check (stock >= 0),
  category text default 'Umum',
  image_url text default '',
  pinned boolean not null default false,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.store_settings (
  id integer primary key default 1 check (id = 1),
  store_name text not null default 'BARIKLANA',
  whatsapp_number text not null default '',
  updated_at timestamptz not null default now()
);
insert into public.store_settings(id,store_name,whatsapp_number)
values(1,'BARIKLANA','628xxxxxxxxxx')
on conflict(id) do nothing;

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  customer_address text not null,
  note text default '',
  items jsonb not null default '[]'::jsonb,
  total numeric(14,2) not null default 0,
  status text not null default 'baru',
  created_at timestamptz not null default now()
);

-- Daftar akun yang benar-benar berhak menjadi admin.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists(select 1 from public.admin_users where user_id = auth.uid());
$$;

-- Admin boleh membaca daftar admin miliknya sendiri; pengelolaan admin dilakukan dari SQL Editor.
drop policy if exists "Admin can read own admin record" on public.admin_users;
create policy "Admin can read own admin record" on public.admin_users
for select to authenticated using (user_id = auth.uid());

alter table public.products enable row level security;
alter table public.store_settings enable row level security;
alter table public.orders enable row level security;

drop policy if exists "Public read active products" on public.products;
create policy "Public read active products" on public.products
for select to anon, authenticated using (active = true);

drop policy if exists "Admin read all products" on public.products;
create policy "Admin read all products" on public.products
for select to authenticated using (public.is_admin());

drop policy if exists "Admin manage products" on public.products;
create policy "Admin manage products" on public.products
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public read store settings" on public.store_settings;
create policy "Public read store settings" on public.store_settings
for select to anon, authenticated using (true);

drop policy if exists "Admin manage store settings" on public.store_settings;
create policy "Admin manage store settings" on public.store_settings
for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Public create orders" on public.orders;
create policy "Public create orders" on public.orders
for insert to anon, authenticated with check (true);

drop policy if exists "Admin read and manage orders" on public.orders;
create policy "Admin read and manage orders" on public.orders
for all to authenticated using (public.is_admin()) with check (public.is_admin());

do $$ begin
  alter publication supabase_realtime add table public.products;
exception when duplicate_object then null;
when undefined_object then null;
end $$;

-- LANGKAH WAJIB UNTUK LOGIN EMAIL + PASSWORD:
-- 1) Di Supabase > Authentication > Users, buat akun admin dengan email dan password yang kuat.
-- 2) Jalankan perintah di bawah, ganti alamat email dengan email akun admin tersebut:
-- insert into public.admin_users(user_id,email)
-- select id,email from auth.users where email = 'admin@bariklana.id'
-- on conflict(user_id) do nothing;


-- Banner toko untuk tampilan katalog Android/mobile.
alter table public.store_settings add column if not exists banner_title text default 'Belanja kebutuhan Anda lebih mudah.';
alter table public.store_settings add column if not exists banner_subtitle text default 'Temukan produk pilihan dengan harga terbaik. Pesan praktis langsung melalui WhatsApp.';
alter table public.store_settings add column if not exists banner_url text default '';

-- Bucket foto produk dan banner. Foto bersifat publik agar dapat tampil di katalog pelanggan.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('product-images', 'product-images', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Public can view catalog images" on storage.objects;
create policy "Public can view catalog images" on storage.objects
for select to anon, authenticated using (bucket_id = 'product-images');

drop policy if exists "Admins upload catalog images" on storage.objects;
create policy "Admins upload catalog images" on storage.objects
for insert to authenticated with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "Admins update catalog images" on storage.objects;
create policy "Admins update catalog images" on storage.objects
for update to authenticated using (bucket_id = 'product-images' and public.is_admin())
with check (bucket_id = 'product-images' and public.is_admin());

drop policy if exists "Admins delete catalog images" on storage.objects;
create policy "Admins delete catalog images" on storage.objects
for delete to authenticated using (bucket_id = 'product-images' and public.is_admin());


-- Identitas brand BARIKLANA: slogan dan logo yang dapat diatur dari panel admin.
alter table public.store_settings add column if not exists tagline text default 'Produk pilihan · Harga bersahabat · Pesan via WhatsApp';
alter table public.store_settings add column if not exists logo_url text default '';


-- Pastikan kolom identitas toko, logo, dan banner promo tersedia.
alter table public.store_settings add column if not exists tagline text default 'Produk pilihan · Harga bersahabat · Pesan via WhatsApp';
alter table public.store_settings add column if not exists logo_url text default '';
alter table public.store_settings add column if not exists banner_url text default '';

-- Sinkronkan perubahan identitas dan banner toko ke halaman katalog yang sedang dibuka.
do $$ begin
  alter publication supabase_realtime add table public.store_settings;
exception when duplicate_object then null;
when undefined_object then null;
end $$;
