# RPP Maker (clone)

Aplikasi satu file (`index.html`) yang memakai Supabase:
`https://fveuvjfgghqulniwtnmm.supabase.co`

## Setup Supabase (sekali saja)
1. **SQL Editor** → tempel isi `supabase/schema.sql` → Run. (Membuat tabel, RLS, dan bucket `tanda-tangan`.)
2. **Edge Functions** → buat function `gemini-proxy`, isi dengan `supabase/functions/gemini-proxy/index.ts`, lalu **matikan "Verify JWT"**.
3. **Edge Functions → Secrets** → tambah `GEMINI_API_KEY` (dari Google AI Studio).
4. Upload `index.html` ke GitHub Pages / hosting.

## Data guru
Tidak ada sinkron E-Rapor. Admin mengisi lewat **Portal Admin → Data guru**:
tambah satu per satu, atau tempel banyak guru dari Excel (format `Nama | Mapel 1; Mapel 2`).

## Format dokumen
- Tanpa kop dan tanpa logo apa pun (netral untuk semua jenjang). Judul biru miring + subjudul, tabel identitas, banner bagian (Identifikasi, Desain Pembelajaran, Langkah-Langkah Kegiatan Pembelajaran, Asesmen Pembelajaran, Lampiran), lencana huruf/angka oranye, dan blok tanda tangan sebelum Lampiran.
- LKPD dan Asesmen memakai gaya tampilan yang sama.
