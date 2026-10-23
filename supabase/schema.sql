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
  asesmen_html      text
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
