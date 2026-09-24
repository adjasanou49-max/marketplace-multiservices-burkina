begin;

alter table public.seller_ledger
  drop constraint if exists seller_ledger_amount_nonnegative;

alter table public.seller_ledger
  drop constraint if exists seller_ledger_entry_type_check;

alter table public.seller_ledger
  add constraint seller_ledger_entry_type_check
  check (
    entry_type = any (
      array[
        'SALE'::text,
        'COMMISSION'::text,
        'REFUND'::text,
        'PAYOUT'::text,
        'ADJUSTMENT'::text,
        'COMMISSION_REVERSAL'::text,
        'SALE_REVERSAL'::text
      ]
    )
  );

commit;