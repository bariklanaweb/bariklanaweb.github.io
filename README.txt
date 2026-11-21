BARIKLANA KATALOG ONLINE — KATALOG, PROMO, DAN ADMIN

Isi paket:
- index.html: katalog pelanggan responsif Android/desktop, contoh produk, pencarian, kategori, keranjang, checkout WhatsApp, login admin email/password, dashboard admin, produk disematkan, pengaturan identitas toko, logo, banner promo, dan nomor WhatsApp.
- supabase.sql: tabel database, aturan akses admin, bucket penyimpanan gambar, serta sinkronisasi realtime.
- logo-bariklana.svg: logo vektor bawaan BARIKLANA.

PEMASANGAN / PEMBARUAN
1. Buka project Supabase yang digunakan aplikasi.
2. Jalankan seluruh isi supabase.sql di menu SQL Editor. Script dibuat agar dapat dijalankan ulang untuk menambahkan kolom logo/banner dan mengaktifkan realtime.
3. Pastikan akun admin telah dibuat pada Authentication > Users dan terdaftar pada tabel public.admin_users.
4. Isi SUPABASE_URL dan SUPABASE_ANON_KEY pada bagian atas index.html menggunakan Project URL dan anon/public key dari Supabase. Jangan pernah memakai service_role key di HTML.
5. Upload index.html ke GitHub untuk menggantikan file lama. Aset logo-bariklana.svg opsional karena logo bawaan juga tersedia di HTML.
6. Buka katalog, tekan Admin, lalu login dengan email dan password akun administrator.
7. Pada Dashboard Administrator, tekan Pengaturan Toko & Promo.

PENGATURAN ADMIN
- Nama toko: mengubah nama di header, judul browser, dan footer pelanggan.
- Logo toko: dapat diisi melalui URL gambar atau diunggah langsung dari galeri Android.
- Banner promo: dapat diganti melalui URL atau unggah gambar dari galeri. Banner selalu ditampilkan; bila belum ada gambar khusus atau URL tidak dapat dimuat, aplikasi menampilkan banner promo bawaan. Gambar kustom ditampilkan tanpa teks tambahan dan mengikuti rasio aslinya.
- Nomor WhatsApp: dapat diisi dengan format 08..., 62..., atau +62.... Aplikasi mengubahnya menjadi format internasional untuk tautan WhatsApp.
- Perubahan nama, logo, banner promo, dan nomor WhatsApp disimpan ke tabel store_settings dan disinkronkan ke halaman pelanggan yang sedang terbuka melalui Supabase Realtime.

PENYIMPANAN GAMBAR
- Logo, banner promo, dan foto produk diunggah ke bucket Supabase Storage bernama product-images.
- Bucket bersifat publik agar gambar tampil di katalog. Kebijakan unggah dibatasi bagi akun yang masuk ke tabel admin_users.
- Batas ukuran gambar 5 MB, tipe JPG, PNG, atau WebP.

KEAMANAN
- Perubahan katalog dan pengaturan hanya untuk akun yang terdaftar pada tabel admin_users.
- Gunakan anon/public key di frontend. Jangan pernah menaruh service_role key di HTML.
- Jangan membagikan akun administrator kepada pelanggan.

CATATAN
- Produk dan foto yang tampil saat konfigurasi Supabase belum diisi adalah data contoh/pratinjau, bukan data toko sebenarnya.
- Pesanan disimpan ke tabel orders (jika koneksi tersedia) dan aplikasi membuka WhatsApp dengan rincian pesanan.
