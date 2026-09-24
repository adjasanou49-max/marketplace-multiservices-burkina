-- Keep a single public review RPC signature.
-- The integer variant is the canonical Flutter-facing contract.
DROP FUNCTION IF EXISTS public.create_review(uuid, uuid, smallint, text);
