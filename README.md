# RPP Maker (clone)

Aplikasi satu file (`index.html`) yang memakai Supabase:
`https://fveuvjfgghqulniwtnmm.supabase.co`

## Setup Supabase
1. **SQL Editor** -> tempel isi `supabase/schema.sql` -> Run. Aman dijalankan ulang; membuat tabel `guru_rpm`, `rpm_hasil` (termasuk kolom `lampiran_html`), `identitas_guru`, `pengaturan_rpm`, `api_key_usage`, `rpm_draft`, RLS, dan bucket `tanda-tangan`.
2. **Edge Functions** -> buat function `gemini-proxy`, isi dengan `supabase/functions/gemini-proxy/index.ts`, lalu **matikan "Verify JWT"**. Function ini harus versi terbaru (mendukung pilihan API key, streaming, dan cadangan key).
3. **Edge Functions -> Secrets** -> tambah satu secret per key dari project Google AI Studio yang berbeda: `GEMINI_API_KEY_1`, `GEMINI_API_KEY_2`, dst (sampai `_20`). Secret lama `GEMINI_API_KEY` tetap dibaca. Opsional: `ALLOWED_ORIGINS` = alamat situs yang boleh memanggil (pisah koma).
4. Upload `index.html` ke GitHub Pages / hosting.

## Fungsi aplikasi
- **Empat dokumen**: RPM, LKPD, Asesmen (diagnostik, formatif, sumatif; lengkap kisi-kisi dan rubrik), dan Lampiran (Glosarium dan Daftar Pustaka).
- **Pilih API KEY** sebelum memproses RPM, LKPD, Asesmen, dan Lampiran: Otomatis (bergiliran, pindah sendiri bila kuota habis) atau API KEY 1/2/dst. Pilihan terakhir diingat di browser.
- **Tulis langsung (streaming)**: teks tampil selagi diterima, ada tombol **Hentikan**, dan progres juga tampil di judul tab browser.
- **Hasil panjang** dikerjakan per potongan dan disambung otomatis. Bila terputus, teks sebagian disimpan sebagai draf dan bisa **dilanjutkan dengan API key lain**.
- **Draf di database** (tabel `rpm_draft`): satu draf per guru per projek, disimpan tiap beberapa detik selama proses, bisa dilanjutkan dari perangkat lain.
- **Pemakaian API key**: sidebar menampilkan jumlah klik hari ini dan rinciannya per API KEY (tabel `api_key_usage`).
- **Mode edit**: tombol Edit, Atur kertas & margin, Muat ulang kepala sekolah, serta **sisipkan gambar** (tombol, seret, atau tempel), geser bebas, ubah ukuran, rata kiri/tengah/kanan.
- **RPP tersimpan**: pilih nama guru, buka (mode baca), edit, hapus, cetak gabungan dengan centang dokumen (termasuk Lampiran), atau susun ulang. Nama file PDF/Word otomatis memakai mapel, topik, dan guru.
- Pemberitahuan berhasil/gagal di tengah layar setelah tiap proses.

## Data guru
Tidak ada sinkron E-Rapor. Admin mengisi lewat **Portal Admin -> Data guru**:
tambah satu per satu, atau tempel banyak guru dari Excel (format `Nama | Mapel 1; Mapel 2`).

## Format dokumen
- Tanpa kop dan tanpa logo apa pun (netral untuk semua jenjang). Judul biru miring + subjudul, tabel identitas, banner bagian (Identifikasi, Desain Pembelajaran, Langkah-Langkah Kegiatan Pembelajaran, Asesmen Pembelajaran, Lampiran), lencana huruf/angka oranye, dan blok tanda tangan sebelum Lampiran.
- LKPD, Asesmen, dan Lampiran (Glosarium dan Daftar Pustaka) memakai gaya tampilan yang sama.
