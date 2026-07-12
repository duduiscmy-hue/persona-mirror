-- ============================================================
-- 人格镜像馆 · Supabase 云端数据库 Schema
-- 在 Supabase 控制台 → SQL Editor 中粘贴全部执行一次
--
-- 重要：把下面所有 'a095c54b-2c5b-4d76-bdfd-224701f76b01' 替换成你的【主人账号】的 auth.uid()
--   （先注册主人账号，再到 Authentication → Users 复制其 ID）
-- ============================================================

-- 1) 用户资料（注册时自动写入 nickname）
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text unique not null,
  created_at timestamptz default now()
);
alter table public.profiles enable row level security;
create policy "profiles_read" on public.profiles for select using (true);
create policy "profiles_insert" on public.profiles for insert with check (auth.uid() = id);
create policy "profiles_update" on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

-- 2) 私有数据（每人一份，按 uid 隔离）
--    键约定：pm_vpriv / pm_chats_v_<昵称> / pm_tarot_v_<昵称> / pm_match_v_<昵称>
create table if not exists public.user_store (
  id uuid primary key default gen_random_uuid(),
  uid uuid not null references auth.users(id) on delete cascade,
  key text not null,
  value jsonb,
  unique (uid, key)
);
alter table public.user_store enable row level security;
create policy "us_select" on public.user_store for select
  using (auth.uid() = uid OR auth.uid() = 'a095c54b-2c5b-4d76-bdfd-224701f76b01');
create policy "us_write" on public.user_store for insert with check (auth.uid() = uid);
create policy "us_update" on public.user_store for update using (auth.uid() = uid) with check (auth.uid() = uid);
create policy "us_delete" on public.user_store for delete using (auth.uid() = uid);

-- 3) 公开访客档案（全站可读，仅作者可改）
create table if not exists public.public_store (
  id uuid primary key default gen_random_uuid(),
  uid uuid not null references auth.users(id) on delete cascade,
  key text not null,
  value jsonb,
  created_at timestamptz default now()
);
alter table public.public_store enable row level security;
create policy "ps_select" on public.public_store for select using (true);
create policy "ps_insert" on public.public_store for insert with check (auth.uid() = uid);
create policy "ps_update" on public.public_store for update using (auth.uid() = uid) with check (auth.uid() = uid);
create policy "ps_delete" on public.public_store for delete using (auth.uid() = uid);

-- 4) 主人分身预设（全站可读，仅主人可写）
create table if not exists public.shadow_store (
  id text primary key default 'owner',
  value jsonb,
  updated_at timestamptz default now()
);
alter table public.shadow_store enable row level security;
create policy "sh_select" on public.shadow_store for select using (true);
create policy "sh_write" on public.shadow_store for insert with check (auth.uid() = 'a095c54b-2c5b-4d76-bdfd-224701f76b01');
create policy "sh_update" on public.shadow_store for update using (auth.uid() = 'a095c54b-2c5b-4d76-bdfd-224701f76b01') with check (auth.uid() = 'a095c54b-2c5b-4d76-bdfd-224701f76b01');
