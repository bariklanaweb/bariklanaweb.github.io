-- BARIKLANA MARKETPLACE — Supabase SQL
-- Jalankan seluruh file ini di Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.stores (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 whatsapp text not null,
 address text not null,
 image_url text,
 description text,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.products (
 id uuid primary key default gen_random_uuid(),
 store_id uuid not null references public.stores(id),
 name text not null,
 category text,
 price numeric(14,2) not null default 0 check(price >= 0),
 stock integer not null default 0 check(stock >= 0),
 image_url text,
 is_featured boolean not null default false,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
-- Aman dijalankan juga pada database yang sudah pernah dibuat.
alter table public.products add column if not exists is_featured boolean not null default false;
create table if not exists public.orders (
 id uuid primary key default gen_random_uuid(),
 store_id uuid not null references public.stores(id),
 customer_name text not null,
 customer_address text,
 total numeric(14,2) not null default 0,
 status text not null default 'baru',
 created_at timestamptz not null default now()
);
create table if not exists public.order_items (
 id uuid primary key default gen_random_uuid(),
 order_id uuid not null references public.orders(id) on delete cascade,
 product_id uuid not null references public.products(id),
 product_name text not null,
 unit_price numeric(14,2) not null,
 quantity integer not null check(quantity > 0),
 subtotal numeric(14,2) not null
);

-- ADMIN BERDASARKAN EMAIL SUPABASE AUTH
-- 1) Buat akun admin terlebih dahulu di Authentication > Users.
-- 2) Ganti email pada bagian SEED ADMIN di bawah dengan email admin yang sebenarnya.
-- 3) Jalankan SQL ini. Jika akun admin belum dibuat, jalankan ulang bagian SEED ADMIN
--    setelah akun dibuat.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;

-- Fungsi ini memeriksa user yang sedang login berdasarkan UUID akun Auth,
-- bukan mempercayai email yang dikirim dari aplikasi.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated;

alter table public.stores enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Bersihkan policy lama dan policy versi email sebelumnya.
drop policy if exists "public read active stores" on public.stores;
drop policy if exists "admin manage stores" on public.stores;
drop policy if exists "public read active products" on public.products;
drop policy if exists "admin manage products" on public.products;
drop policy if exists "admin read orders" on public.orders;
drop policy if exists "admin update orders" on public.orders;
drop policy if exists "admin read order items" on public.order_items;

-- Katalog dapat dibaca pengunjung; hanya admin terdaftar yang dapat mengubah.
create policy "public read active stores" on public.stores
  for select to anon, authenticated
  using (is_active = true or (select public.is_admin()));

create policy "admin manage stores" on public.stores
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "public read active products" on public.products
  for select to anon, authenticated
  using (is_active = true or (select public.is_admin()));

create policy "admin manage products" on public.products
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "admin read orders" on public.orders
  for select to authenticated
  using ((select public.is_admin()));

create policy "admin update orders" on public.orders
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy "admin read order items" on public.order_items
  for select to authenticated
  using ((select public.is_admin()));

-- SEED ADMIN:
-- Ganti alamat email di bawah dengan email yang dipakai login ke aplikasi.
-- Perintah ini hanya menambahkan admin jika email sudah ada di Authentication > Users.
insert into public.admin_users (user_id, email)
select id, email
from auth.users
where lower(email) = lower('GANTI_DENGAN_EMAIL_ADMIN_ANDA@gmail.com')
on conflict (user_id) do update
set email = excluded.email;

create or replace function public.checkout_order(
 p_store_id uuid,
 p_customer_name text,
 p_customer_address text,
 p_items jsonb
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
 v_order_id uuid;
 v_total numeric(14,2) := 0;
 v_item jsonb;
 v_product public.products%rowtype;
 v_qty integer;
begin
 if coalesce(trim(p_customer_name),'') = '' then
   raise exception 'Nama pemesan wajib diisi';
 end if;
 if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
   raise exception 'Keranjang kosong';
 end if;
 if not exists(select 1 from public.stores where id=p_store_id and is_active=true) then
   raise exception 'Toko tidak tersedia';
 end if;

 insert into public.orders(store_id,customer_name,customer_address,total,status)
 values(p_store_id,trim(p_customer_name),p_customer_address,0,'baru')
 returning id into v_order_id;

 for v_item in select value from jsonb_array_elements(p_items)
 loop
   v_qty := (v_item->>'quantity')::integer;
   if v_qty is null or v_qty < 1 then raise exception 'Jumlah produk tidak valid'; end if;

   select * into v_product from public.products
   where id = (v_item->>'product_id')::uuid
     and store_id = p_store_id and is_active = true
   for update;
   if not found then raise exception 'Produk tidak ditemukan'; end if;
   if v_product.stock < v_qty then
     raise exception 'Stok tidak cukup untuk produk: %',v_product.name;
   end if;

   update public.products set stock = stock - v_qty where id = v_product.id;
   insert into public.order_items(order_id,product_id,product_name,unit_price,quantity,subtotal)
   values(v_order_id,v_product.id,v_product.name,v_product.price,v_qty,v_product.price*v_qty);
   v_total := v_total + v_product.price*v_qty;
 end loop;

 update public.orders set total=v_total where id=v_order_id;
 return v_order_id;
end;
$$;

revoke all on function public.checkout_order(uuid,text,text,jsonb) from public;
grant execute on function public.checkout_order(uuid,text,text,jsonb) to anon, authenticated;
grant select on public.stores, public.products to anon, authenticated;
grant select, insert, update, delete on public.stores, public.products to authenticated;
grant select, update on public.orders to authenticated;
grant select on public.order_items to authenticated;

-- Tabel admin_users tidak diberi akses langsung kepada anon/authenticated.
-- Jangan aktifkan sign-up publik dan jangan pernah taruh service_role key di HTML.
-- Untuk menambah admin lain, masukkan user_id dan email akun tersebut ke admin_users
-- melalui SQL Editor (setelah akun dibuat di Authentication > Users).
