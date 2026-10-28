# Createch mobile app (Flutter)

The kids' app, in Armenian by default (English with the ՀԱՅ/EN button), light or dark (follows the phone until the
moon/sun button is used; both choices are remembered).

## Who signs in

One login field, three kinds of account:

| Typed in the field | Account | Made in the admin panel |
| --- | --- | --- |
| a login, e.g. `aram.p` | child: sees their own page, orders from the TechCoins shop | Child accounts |
| a phone number, e.g. `091 23 45 67` | parent: picks a child, sees the shop without ordering | Parents |
| an email | parent with an email login | Parents |

Children are `<login>@child.createch.invalid` in Supabase Auth, parents' phone logins `<374…>@phone.createch.invalid`.
Data comes from Supabase: parents through `my_children` / `parent_child_overview` (same as the website's parent
portal), children through `child_home`, the shop through the `shop_items` table and the `shop_request` /
`shop_cancel` functions.

**Needs `supabase/033_shop_and_child_accounts.sql`** (child accounts and the shop) to be run in the Supabase SQL
Editor. Before that, parents still work and the shop is simply hidden.

## Run

```bash
cp env.example.json env.json   # fill in the Supabase URL and anon key (same as src/environments/environment.ts)
flutter run --dart-define-from-file=env.json
```

Keep the project out of iCloud-synced folders (Desktop/Documents): there codesign rejects the Finder attributes iCloud
adds ("resource fork, Finder information, or similar detritus not allowed") and iOS builds fail.
