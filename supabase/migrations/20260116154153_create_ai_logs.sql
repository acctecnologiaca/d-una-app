-- Create table to track AI request usage globally
create table if not exists public.ai_request_logs (
  id uuid default gen_random_uuid() primary key,
  model text not null, -- e.g. 'gemini-1.5-flash'
  status text not null, -- 'success', 'error_429', 'error_other'
  details text, -- Optional error message or metadata
  created_at timestamptz default now() not null
);

-- Index for efficient counting by model and time
create index idx_ai_logs_model_created on public.ai_request_logs (model, created_at);

-- Enable RLS
alter table public.ai_request_logs enable row level security;

-- Policy: Allow Service Role full access (implicit, but good to be explicit if using user client)
-- We will mostly use Service Role in Edge Function to read ALL logs.
-- But standard users might trigger the insert? No, Edge Function does the insert.
-- So we can leave RLS restrictive or open for read if admins need it.
-- Let's allow authenticated users to view logs (maybe for admin dashboard later).
create policy "Enable read access for authenticated users" on "public"."ai_request_logs"
  as permissive for select to authenticated using (true);

-- Allow insert by authenticated users (if we ever do client-side logging)
create policy "Enable insert for authenticated users" on "public"."ai_request_logs"
  as permissive for insert to authenticated with check (true);
