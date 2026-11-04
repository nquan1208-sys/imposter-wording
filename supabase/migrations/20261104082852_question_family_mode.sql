begin;

alter table public.game_categories drop constraint family_word_categories_only;

-- Only the three authored seed categories are approved; other questions stay opt-in.
update public.game_categories set is_family_friendly = true
where game_type = 'question' and (id, slug) in (
  ('5eed0003-0000-0000-0000-000000000001'::uuid, 'family-mealtime'),
  ('5eed0003-0000-0000-0000-000000000002'::uuid, 'family-together'),
  ('5eed0003-0000-0000-0000-000000000003'::uuid, 'family-imagination')
);

commit;
