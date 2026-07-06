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
- creates the AO3Chat category structure
- creates the `ao3chat_supporters` group
- creates the supporter-only private fandom rooms category
- hides public powered-by branding
- disables and visually suppresses stock owner onboarding and tutorial-style welcome messages
- adds AO3Chat-branded account panels to login and signup
- relabels public navigation around AO3Chat rooms and discussions

## Category Structure

AO3Chat uses categories for reader workflows, not for every fandom or ship. Fandoms, ships, warnings, spoiler labels, fic titles, authors, and chapter references belong in AO3Chat metadata fields and tags so the forum can scale.

The configure task creates:

- `Welcome Desk`
- `Fic Recs`
- `Looking for a Fic`
- `Chapter Discussions`
- `Spoiler Zone`
- `Content Warnings`
- `Fandom Spaces`
- `Reader Lounge`
- `Site Help`
- `Private Fandom Rooms`
- `Announcements`
- `Guidelines`
- `Moderation`

`Private Fandom Rooms` is restricted to staff and the configured supporter group. `Announcements` and `Guidelines` are public read-only rooms managed by staff. `Moderation` is staff-only.

After Stripe keys are configured, create or verify the paid supporter product:

```bash
bin/rake ao3_fanfic_forum:setup_paid_tier
```

Successful payments should grant the `ao3chat_supporters` group, which unlocks the private fandom rooms category.

Supporters can request new private fandom rooms from the AO3Chat home page. Requests create topics inside `Private Fandom Rooms`, so staff can review, reply, rename, split, approve, or archive them using the normal moderation workflow. Non-supporters receive the configured subscription URL instead of access to the restricted category.

If importing or editing AO3 metadata outside the composer:

```bash
bin/rake ao3_fanfic_forum:backfill
```

## Filtering API

The plugin exposes:

```text
GET /ao3-fanfic/topics.json
GET /ao3-fanfic/terms.json
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

The AO3Chat home page includes a reader-facing browser backed by this endpoint, so fandom, ship, warning, spoiler-safe, and thread-type filtering work without leaving the main discussion view.

`/ao3-fanfic/terms.json` returns visible fandom, ship, and warning terms with topic counts. The home-page browser uses it to show live one-click tag filters; it uses the same topic visibility checks as discussion search.

## Privacy Model

Readers can use anonymous posting for public-facing discussions. Administrators can still audit the real account behind anonymous activity. Private fandom spaces are enforced through category permissions and the configured supporter group; the plugin stores the chosen group as metadata for filtering and labeling.
