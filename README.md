# AO3Chat fanfic forum

AO3Chat is a privacy-first fanfic reader forum with topic metadata and room structure for:

- fandom tags
- pairing and ship tags
- spoiler labels and spoiler-safe filtering
- fic recommendation topics
- chapter discussion topics
- looking-for-a-fic topics
- content warning tags and exclusion filters
- supporter-only private fandom rooms
- long posts and quote-heavy replies

## Runtime Requirements

- Ruby 3.4+
- PostgreSQL 15+
- Redis 7+
- Node and package tooling required by the host forum runtime
- Optional: Stripe keys for the paid supporter tier

## Setup

Run migrations, then apply AO3Chat defaults:

```bash
bin/rake db:migrate
bin/rake ao3_fanfic_forum:configure
```

The configure task:

- enables AO3Chat topic metadata
- enables local AO3Chat accounts
- disables third-party/social sign-in methods
- creates public reader categories
- creates the `ao3chat_supporters` group
- creates the supporter-only private fandom rooms category
- hides public powered-by branding

After Stripe keys are configured, create or verify the paid supporter product:

```bash
bin/rake ao3_fanfic_forum:setup_paid_tier
```

Successful payments should grant the `ao3chat_supporters` group, which unlocks the private fandom rooms category.

If importing or editing AO3 metadata outside the composer:

```bash
bin/rake ao3_fanfic_forum:backfill
```

## Filtering API

The plugin exposes:

```text
GET /ao3-fanfic/topics.json
```

Supported query params:

- `discussion_type`: `general`, `fic_recommendation`, `chapter_discussion`, `looking_for_fic`
- `fandom`: comma-separated fandom tags
- `ship`: comma-separated ship tags
- `warning`: comma-separated required warnings
- `exclude_warning`: comma-separated warnings to hide
- `visibility`: `public`, `members`, `space`
- `spoiler_safe`: `true` hides topics with active spoiler windows
- `page`, `per_page`

All results still use normal topic visibility checks. The plugin does not bypass category or group permissions.

## Privacy Model

Readers can use anonymous posting for public-facing discussions. Administrators can still audit the real account behind anonymous activity. Private fandom spaces are enforced through category permissions and the configured supporter group; the plugin stores the chosen group as metadata for filtering and labeling.
