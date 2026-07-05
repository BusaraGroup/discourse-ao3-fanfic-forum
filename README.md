# Discourse AO3 Fanfic Forum

This plugin turns the Discourse fork into a fanfic-reader forum with real topic metadata for:

- fandom tags
- pairing/ship tags
- spoiler labels and spoiler-safe filtering
- fic recommendation topics
- chapter discussion topics
- looking-for-a-fic topics
- content warning tags and exclusion filters
- private or semi-private fandom space labels backed by Discourse groups/categories
- long posts and quote-heavy replies through Discourse settings

## Runtime Requirements

Use the standard Discourse stack:

- Ruby 3.4+
- PostgreSQL 15+
- Redis 7+
- Node/Yarn as required by Discourse

This workspace currently contains the Discourse fork plus the plugin. The local machine still needs the Discourse runtime installed before the forum can boot.

## Setup

After installing Discourse dependencies and running migrations:

```bash
bundle exec rails db:migrate
bundle exec rake ao3_fanfic_forum:configure
```

If importing or editing AO3 metadata outside the composer:

```bash
bundle exec rake ao3_fanfic_forum:backfill
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

All results still use Discourse topic visibility checks. The plugin does not bypass category or group permissions.

## Privacy Model

Normal users see Discourse anonymous identities when anonymous mode is used. Administrators can still audit the real account behind an anonymous account through Discourse's built-in anonymous mode records. Private and semi-private fandom spaces should be enforced with Discourse category permissions and groups; the plugin stores the chosen group as metadata for filtering and labeling.
