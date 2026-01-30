-- Create services table
create table public.services (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text null,
  price numeric not null,
  price_unit text not null default 'serv', -- 'h', 'serv', etc
  category text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  
  constraint services_pkey primary key (id)
);

-- Enable RLS
alter table public.services enable row level security;

-- Policies
create policy "Users can view their own services" on public.services
  for select using (auth.uid() = user_id);

create policy "Users can insert their own services" on public.services
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own services" on public.services
  for update using (auth.uid() = user_id);

create policy "Users can delete their own services" on public.services
  for delete using (auth.uid() = user_id);
