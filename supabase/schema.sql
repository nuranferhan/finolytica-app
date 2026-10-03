create table if not exists public.users (
  id          uuid primary key references auth.users (id) on delete cascade,
  email       text not null,
  full_name   text,
  avatar_url  text,
  currency    text not null default 'TRY',
  created_at  timestamptz not null default now()
);

create table if not exists public.categories (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.users (id) on delete cascade,
  name        text not null,
  icon        text,
  color       text,
  type        text not null check (type in ('income', 'expense')),
  created_at  timestamptz not null default now()
);

create table if not exists public.transactions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.users (id) on delete cascade,
  category_id  uuid references public.categories (id) on delete set null,
  title        text not null,
  amount       numeric(14, 2) not null check (amount > 0),
  type         text not null check (type in ('income', 'expense')),
  description  text,
  date         date not null default current_date,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz
);

create table if not exists public.savings_goals (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.users (id) on delete cascade,
  title           text not null,
  description     text,
  target_amount   numeric(14, 2) not null check (target_amount > 0),
  current_amount  numeric(14, 2) not null default 0 check (current_amount >= 0),
  target_date     date,
  category        text not null default 'other',
  color           text not null default '#2196F3',
  is_completed    boolean not null default false,
  created_at      timestamptz not null default now(),
  completed_at    timestamptz
);

create table if not exists public.goal_transactions (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.users (id) on delete cascade,
  goal_id           uuid not null references public.savings_goals (id) on delete cascade,
  amount            numeric(14, 2) not null check (amount > 0),
  description       text,
  transaction_date  date not null default current_date,
  created_at        timestamptz not null default now()
);

create table if not exists public.investments (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.users (id) on delete cascade,
  symbol          text not null,
  name            text not null,
  type            text not null check (type in ('stock', 'crypto', 'gold', 'forex')),
  amount          numeric(18, 6) not null check (amount > 0),
  purchase_price  numeric(18, 6) not null check (purchase_price >= 0),
  current_price   numeric(18, 6),
  purchase_date   date not null default current_date,
  created_at      timestamptz not null default now()
);

create table if not exists public.watchlist (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null references public.users (id) on delete cascade,
  symbol          text not null,
  name            text not null,
  type            text not null check (type in ('stock', 'crypto', 'gold', 'forex')),
  current_price   numeric(18, 6),
  previous_price  numeric(18, 6),
  last_updated    timestamptz not null default now(),
  created_at      timestamptz not null default now()
);

create table if not exists public.exchange_rates (
  id               uuid primary key default gen_random_uuid(),
  base_currency    text not null,
  target_currency  text not null,
  rate             numeric(18, 8) not null,
  last_updated     timestamptz not null default now(),
  unique (base_currency, target_currency)
);

create index if not exists idx_transactions_user_date
  on public.transactions (user_id, date desc);
create index if not exists idx_categories_user
  on public.categories (user_id);
create index if not exists idx_goal_tx_goal
  on public.goal_transactions (goal_id, transaction_date desc);
create index if not exists idx_investments_user
  on public.investments (user_id, created_at desc);
create index if not exists idx_watchlist_user
  on public.watchlist (user_id, created_at desc);

alter table public.users              enable row level security;
alter table public.categories         enable row level security;
alter table public.transactions       enable row level security;
alter table public.savings_goals      enable row level security;
alter table public.goal_transactions  enable row level security;
alter table public.investments        enable row level security;
alter table public.watchlist          enable row level security;
alter table public.exchange_rates     enable row level security;

drop policy if exists "users_own_row" on public.users;
create policy "users_own_row" on public.users
  for all to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

drop policy if exists "categories_own_rows" on public.categories;
create policy "categories_own_rows" on public.categories
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "transactions_own_rows" on public.transactions;
create policy "transactions_own_rows" on public.transactions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "savings_goals_own_rows" on public.savings_goals;
create policy "savings_goals_own_rows" on public.savings_goals
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "goal_transactions_own_rows" on public.goal_transactions;
create policy "goal_transactions_own_rows" on public.goal_transactions
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "investments_own_rows" on public.investments;
create policy "investments_own_rows" on public.investments
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "watchlist_own_rows" on public.watchlist;
create policy "watchlist_own_rows" on public.watchlist
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "exchange_rates_read" on public.exchange_rates;
create policy "exchange_rates_read" on public.exchange_rates
  for select to authenticated using (true);

drop policy if exists "exchange_rates_write" on public.exchange_rates;
create policy "exchange_rates_write" on public.exchange_rates
  for insert to authenticated with check (true);

drop policy if exists "exchange_rates_update" on public.exchange_rates;
create policy "exchange_rates_update" on public.exchange_rates
  for update to authenticated using (true) with check (true);

create or replace function public.calculate_user_balance(user_uuid uuid)
returns numeric
language sql
stable
set search_path = public
as $$
  select coalesce(
    sum(case when type = 'income' then amount else -amount end),
    0
  )
  from public.transactions
  where user_id = user_uuid;
$$;

create or replace function public.get_financial_summary(user_uuid uuid)
returns table (
  total_goals_target   numeric,
  total_goals_current  numeric,
  completed_goals      integer,
  total_goals          integer,
  goals_progress       numeric
)
language sql
stable
set search_path = public
as $$
  select
    coalesce(sum(target_amount), 0)                         as total_goals_target,
    coalesce(sum(current_amount), 0)                        as total_goals_current,
    count(*) filter (where is_completed)::integer           as completed_goals,
    count(*)::integer                                       as total_goals,
    case
      when coalesce(sum(target_amount), 0) > 0
        then round(sum(current_amount) / sum(target_amount) * 100, 2)
      else 0
    end                                                     as goals_progress
  from public.savings_goals
  where user_id = user_uuid;
$$;

create or replace function public.handle_goal_transaction()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  goal_title text;
begin
  update public.savings_goals
     set current_amount = current_amount + new.amount,
         is_completed   = (current_amount + new.amount) >= target_amount,
         completed_at   = case
                            when (current_amount + new.amount) >= target_amount
                              then coalesce(completed_at, now())
                            else completed_at
                          end
   where id = new.goal_id
  returning title into goal_title;

  insert into public.transactions (user_id, title, amount, type, description, date)
  values (
    new.user_id,
    'Hedefe aktarım: ' || coalesce(goal_title, 'Birikim hedefi'),
    new.amount,
    'expense',
    new.description,
    new.transaction_date
  );

  return new;
end;
$$;

drop trigger if exists trg_goal_transaction_after_insert on public.goal_transactions;
create trigger trg_goal_transaction_after_insert
  after insert on public.goal_transactions
  for each row execute function public.handle_goal_transaction();

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_transactions_updated_at on public.transactions;
create trigger trg_transactions_updated_at
  before update on public.transactions
  for each row execute function public.set_updated_at();
