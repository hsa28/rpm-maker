-- =========================================================
-- RPP Maker - skema database (Supabase baru)
-- Jalankan sekali di Supabase > SQL Editor > New query > Run
-- =========================================================

-- 1) Daftar guru (diisi manual oleh admin lewat Portal Admin)
create table if not exists public.guru_rpm (
  id         uuid primary key default gen_random_uuid(),
  nama       text not null,
  mapel      text default '',
  created_at timestamptz default now()
);
create unique index if not exists guru_rpm_nama_uniq on public.guru_rpm (lower(nama));

-- 2) RPP / LKPD / asesmen yang tersimpan
create table if not exists public.rpm_hasil (
  id                uuid primary key default gen_random_uuid(),
  created_at        timestamptz default now(),
  updated_at        timestamptz default now(),
  nama_guru         text,
  kepala_sekolah    text,
  satuan_pendidikan text,
  mata_pelajaran    text,
  fase              text,
  semester          text,
  tahun_ajaran      text,
  topik             text,
  jumlah_pertemuan  int,
  model             text,
  rpm_markdown      text,
  rpm_html          text,
  lkpd_html         text,
  asesmen_html      text,
  lampiran_html     text
);
create index if not exists rpm_hasil_guru_idx on public.rpm_hasil (nama_guru, created_at desc);

-- 3) Identitas default tiap guru
create table if not exists public.identitas_guru (
  nama_guru      text primary key,
  mata_pelajaran text,
  fase           text,
  semester       text,
  tahun_ajaran   text,
  updated_at     timestamptz default now()
);

-- 4) Pengaturan (kunci 'sekolah' dan 'kertas')
create table if not exists public.pengaturan_rpm (
  kunci      text primary key,
  nilai      jsonb,
  updated_at timestamptz default now()
);

-- 5) RLS: aplikasi memakai kunci publishable tanpa login Supabase,
--    jadi akses dibuka untuk role anon.
alter table public.guru_rpm        enable row level security;
alter table public.rpm_hasil       enable row level security;
alter table public.identitas_guru  enable row level security;
alter table public.pengaturan_rpm  enable row level security;

do $$
declare t text;
begin
  foreach t in array array['guru_rpm','rpm_hasil','identitas_guru','pengaturan_rpm'] loop
    execute format('drop policy if exists "anon_all" on public.%I', t);
    execute format('create policy "anon_all" on public.%I for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;

-- 6) Storage: bucket publik untuk tanda tangan (PNG/JPG/WebP, maks 1 MB)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('tanda-tangan', 'tanda-tangan', true, 1048576, array['image/png','image/jpeg','image/webp'])
on conflict (id) do update
  set public = true, file_size_limit = 1048576,
      allowed_mime_types = array['image/png','image/jpeg','image/webp'];

drop policy if exists "ttd_read"   on storage.objects;
drop policy if exists "ttd_insert" on storage.objects;
drop policy if exists "ttd_update" on storage.objects;
drop policy if exists "ttd_delete" on storage.objects;
create policy "ttd_read"   on storage.objects for select to anon, authenticated using (bucket_id = 'tanda-tangan');
create policy "ttd_insert" on storage.objects for insert to anon, authenticated with check (bucket_id = 'tanda-tangan');
create policy "ttd_update" on storage.objects for update to anon, authenticated using (bucket_id = 'tanda-tangan') with check (bucket_id = 'tanda-tangan');
create policy "ttd_delete" on storage.objects for delete to anon, authenticated using (bucket_id = 'tanda-tangan');


-- =========================================================
-- Tambahan fungsi (pemilih API key, draf, Lampiran). Aman dijalankan ulang.
-- =========================================================

-- 7) Kolom Lampiran (Glosarium dan Daftar Pustaka) untuk tabel yang sudah terlanjur dibuat
alter table public.rpm_hasil add column if not exists lampiran_html text;

-- 8) Riwayat pemakaian API key: satu baris per klik yang memakai AI
create table if not exists public.api_key_usage (
  id         bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  tanggal    date not null,
  key_slot   text not null default 'auto',
  aksi       text not null default '',
  model      text not null default '',
  nama_guru  text not null default ''
);
alter table public.api_key_usage add column if not exists key_dipakai text not null default '';
create index if not exists api_key_usage_tanggal_idx on public.api_key_usage (tanggal);

-- 9) Draf yang belum selesai (satu draf per guru per projek), bisa dilanjutkan di perangkat lain
create table if not exists public.rpm_draft (
  id           bigint generated always as identity primary key,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  nama_guru    text not null,
  project_id   text not null,
  project_nama text not null default '',
  aksi         text not null default '',
  draft_key    text not null default '',
  prompt       text not null default '',
  teks         text not null default '',
  panjang      int  not null default 0,
  done         jsonb not null default '{}'::jsonb,
  form         jsonb not null default '{}'::jsonb,
  rpm_markdown text,
  model        text not null default '',
  perangkat    text not null default ''
);
create unique index if not exists rpm_draft_guru_projek_uniq on public.rpm_draft (nama_guru, project_id);
create index if not exists rpm_draft_guru_idx on public.rpm_draft (nama_guru, updated_at desc);

alter table public.api_key_usage enable row level security;
alter table public.rpm_draft     enable row level security;
do $$
declare t text;
begin
  foreach t in array array['api_key_usage','rpm_draft'] loop
    execute format('drop policy if exists "anon_all" on public.%I', t);
    execute format('create policy "anon_all" on public.%I for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;
