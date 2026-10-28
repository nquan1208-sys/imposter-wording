# Sample word images

25 PNG illustrations from [Twemoji v16.0.1](https://github.com/jdecked/twemoji/tree/v16.0.1), graphics copyright Twitter, Inc. and other contributors, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Original graphics, no modifications. Full license: LICENSE-GRAPHICS.

Each filename is its word prompt ID in `../seed.sql`.

Apply pending migrations and seed local content without resetting existing data:

Includes 10 categories and 50 prompts, each published in Vietnamese and English. Both languages share the same 25 word images.

```sh
supabase db push --local
python3 supabase/scripts/seed_local_images.py
```

After `supabase db reset --local`, SQL content is seeded automatically; run the image script again to upload and link images. The script targets only the local stack and verifies published content as an anonymous user.
