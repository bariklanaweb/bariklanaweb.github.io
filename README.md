# Bariklana Marketplace — Deploy GitHub + Supabase

Paket ini berisi frontend statis dan skrip database. GitHub Pages meng-host tampilan web; Supabase menyediakan database, autentikasi Admin, dan proses pengurangan stok.

## Isi folder
- `index.html` — aplikasi katalog, keranjang, checkout WhatsApp, dan panel Admin.
- `supabase.sql` — struktur database, kebijakan keamanan (RLS), dan fungsi checkout otomatis.
- `.nojekyll` — membantu GitHub Pages menerbitkan file statis.
- `README.md` — panduan instalasi.

## A. Pasang database di Supabase
1. Buat project di https://supabase.com.
2. Buka **SQL Editor → New query**.
3. Buka file `supabase.sql`, salin seluruh isinya, lalu jalankan (**Run**).
4. Buka **Project Settings → API** (atau **Data API / API Keys**, tergantung tampilan dashboard).
5. Salin **Project URL** dan **anon/public key**.

## B. Hubungkan HTML ke Supabase
Buka `index.html`, cari bagian konfigurasi di awal script:
```js
const SUPABASE_URL="https://YOUR_PROJECT.supabase.co";
const SUPABASE_ANON_KEY="YOUR_SUPABASE_ANON_KEY";
```
Ganti dua nilai tersebut dengan Project URL dan anon/public key dari project Anda. Jangan gunakan `service_role` / secret key di file HTML.

## C. Buat Login PIN Admin
1. Di Supabase buka **Authentication → Users → Add user**.
2. Buat user dengan email persis `admin@bariklana.local`.
3. Isi password awal dengan PIN `1234`. Setelah berhasil login, PIN dapat diganti sendiri melalui bagian **Pengaturan PIN Admin** di halaman Admin. PIN baru harus 4–12 angka. Simpan PIN baru secara aman.
4. Nonaktifkan sign-up publik di Authentication settings.
5. Login di aplikasi memakai PIN tersebut.

PIN tidak disimpan sebagai teks di HTML. Aplikasi mengirim PIN ke Supabase Auth sebagai password untuk akun admin khusus. Database hanya mengizinkan email admin tersebut mengelola toko, produk, dan pesanan.

## D. Upload ke GitHub Pages
1. Buat repository GitHub baru, misalnya `bariklana-marketplace`.
2. Upload `index.html` dan `.nojekyll` ke direktori utama repository. README dan SQL boleh ikut diunggah.
3. Buka **Settings → Pages**.
4. Pada **Build and deployment**, pilih **Deploy from a branch**.
5. Pilih branch `main`, folder `/ (root)`, lalu **Save**.
6. Tunggu proses selesai. Buka URL GitHub Pages yang diberikan GitHub.

## E. Tambahkan toko dan produk
1. Buka website GitHub Pages.
2. Tekan **Admin**, masukkan PIN.
3. Tambahkan toko, nomor WhatsApp, alamat toko, dan URL logo.
4. Tambahkan produk beserta harga, stok, kategori, dan URL gambar.

Versi ini menggunakan URL gambar (tautan gambar publik), belum menyediakan upload file foto langsung dari galeri ke Supabase Storage.

## Cara stok otomatis
Ketika pembeli checkout, aplikasi memanggil fungsi database `checkout_order`. Fungsi memeriksa stok dan menguranginya dalam transaksi database dengan penguncian baris produk. Jika stok tidak cukup, checkout ditolak. Setelah order tercatat, aplikasi membuka WhatsApp toko dengan detail pesanan.

## Catatan penting sebelum digunakan publik
- Gunakan hanya **anon/public key** di frontend. Jangan pernah mempublikasikan `service_role` key.
- Email admin dipatok `admin@bariklana.local` di SQL dan frontend. Jika ingin mengganti email admin, ubah nilainya di kedua tempat.
- Simpan PIN dengan aman dan jangan bagikan ke pembeli.
- Checkout mencatat pesanan dan mengurangi stok sebelum WhatsApp dibuka. Admin perlu mengonfirmasi pesanan dan membuat prosedur pengembalian stok jika pesanan dibatalkan.
- Untuk penggunaan produksi, aktifkan proteksi tambahan seperti pembatasan percobaan login, verifikasi pesanan, dan mekanisme refund stok.


## Perubahan Admin pada versi terbaru
- Login Admin menampilkan kolom PIN saja (4–12 angka); PIN awal adalah `1234`, tanpa kolom email.
- PIN dikirim ke Supabase Authentication sebagai password akun admin `admin@bariklana.local`.
- Setelah login, Dashboard, Kelola Toko, Kelola Produk, dan Pesanan tampil dalam satu halaman panjang (bukan menu/tab terpisah).
- Jika kolom PIN belum dapat login, pastikan akun `admin@bariklana.local` sudah dibuat di Supabase Authentication dan password akun tersebut adalah PIN yang dimasukkan.


### Mengubah PIN Admin
Setelah login, gulir ke bagian **Pengaturan PIN Admin** pada halaman Admin. Masukkan PIN baru, ulangi PIN baru, lalu tekan **Simpan PIN Baru**. Perubahan disimpan melalui Supabase Authentication dan berlaku untuk login berikutnya.


## Sematkan Produk (Produk Unggulan)
- Di panel Admin, pada tabel **Kelola Produk**, tekan tombol **📌 Sematkan** untuk menampilkan produk lebih dahulu di katalog Pengguna.
- Produk yang disematkan mendapat label **Produk Disematkan** dan otomatis muncul sebelum produk lainnya.
- Tekan **Lepas Sematan** untuk mengembalikan urutan normal.
- Kolom `is_featured` sudah ditambahkan ke `supabase.sql`. Jika database sudah terlanjur dibuat, jalankan perintah migrasi ini di Supabase SQL Editor:
```sql
alter table public.products add column if not exists is_featured boolean not null default false;
```
