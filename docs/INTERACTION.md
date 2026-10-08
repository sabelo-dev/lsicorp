# Interaction design

How the site behaves when it is used: the states every control has, the keyboard, feedback,
motion, and what was checked. It records the result of working through *LSI Corp Website
Upgrade: Linear-Inspired Interaction Design* against the site as it stands. Linear is the
reference for interaction quality (speed, consistency, keyboard access, clear feedback), not for
appearance: the brand, the light scheme and the wording are LSI's own.

## Decisions that shaped the work

| The specification says | What the site does | Why |
| --- | --- | --- |
| Treat the site as a company and tools website; suggested navigation Home, Tools, About, Support or Contact. | Navigation stays **Services, Work, About, Contact**; the logo is Home. The "tool catalog" is the portfolio at `/work`. | The site was repositioned around LSI as a service provider ([SITE_SPEC.md](SITE_SPEC.md)). The specification asks for navigation that reflects actual content. |
| Preserve the existing framework, routes, content source and deployment. | Unchanged: Qt Quick compiled to WebAssembly, fragment routes, Supabase, AWS Amplify. No dependency was added. | |
| Real links, semantic HTML, indexable content. | Not available in a canvas application. Links are controls with the link role; each has a real, shareable address. | See "Departures" in [OPERATIONS.md](OPERATIONS.md). |
| Record analytics events for search, filters, detail views and downloads. | **Not done.** | The site has no analytics, and the privacy notice says so. Adding measurement needs the owner's decision on purpose, consent and retention first ([OPERATIONS.md](OPERATIONS.md), "Privacy and analytics"). |
| Recently viewed items (if implemented). | Not implemented. | It would store browsing history on the visitor's device, which the privacy notice does not cover. |

## Look

Crisp and flat, on the LSI navy and gold. Surfaces are near-white (or near-black in the dark
scheme) and separated by hairline borders, not shadows; only the search panel, which floats,
casts one. Corners are 8 pixels on surfaces and 6 on controls. Controls are squared: chips and
navigation are rectangles, and the current navigation item is underlined. Buttons and inputs are
40 pixels high with a pointer and 48 on a small screen, where a finger has to hit them. Headings
are tight and semi-bold. Navy carries primary actions and the brand bands; gold is an accent (the
rule under the hero, the rule above a section heading, the primary button on navy). Anything that
is typed into or pressed has a border with at least 3:1 contrast (`Theme.controlBorder`);
decorative hairlines are fainter (`Theme.border`). All of it comes from `app/qml/Theme.qml`.

The home page opens on a flat navy band: the company statement on one side and the portfolio as
a four-line index on the other, each line showing the product's status in words. Below it are a
ruled strip of key facts, the services, the lead piece of work, and how LSI creates value.

## The catalogue (`/work`)

- **Search** filters as you type, with no submit step, across name, internal name, category,
  description, status, platform, service and how the product can be used ("web app", "Windows
  download"). It never changes what was typed and never moves the keyboard focus.
- **Filters** are chips, not drop-downs: service, status and platform. Only values that occur in
  the catalogue are offered. The selected chip is filled, bold and announced as checked. On a
  small screen the filters open from a button that always shows how many are on.
- **Sort**: Featured (the order staff set) or Name: A to Z. There is no "recently updated",
  because products do not carry a reliable update date.
- The line above the results gives the count and the filters in use, and a single "Clear search
  and filters". With no results, the message quotes the search, says why nothing matched and
  offers the same reset.
- **The address carries the view**: `/#/work?q=gold&status=available&platform=windows&sort=name`.
  It can be shared or bookmarked, and Back returns to the same filtered list. Typing updates the
  address after a short pause and does not add history entries, so Back leaves the page rather
  than undoing a keystroke.
- **Cards** give the name, category, a one-sentence purpose, the status in words and, only when
  a release is published, how it is available. The whole card opens the project; the name is
  also a link for the keyboard. A card never moves or resizes under the pointer: its border and
  shadow respond instead. Download controls are not placed on cards; they live on the project
  and release pages, next to the file details.

The catalogue rules (`filterCatalog`, `catalogFacets`, `accessFor`, `parseRoute`, `buildRoute`)
are in `app/qml/rules.mjs` and are covered by `tests/rules.test.mjs`.

## Keyboard

| Key | Where | What it does |
| --- | --- | --- |
| Tab, Shift+Tab | Everywhere | Moves through controls in reading order. The focused control scrolls into view and shows a 2-pixel ring. |
| Enter or Space | A focused control | Activates it. |
| Ctrl+K (Command+K on a Mac) | Anywhere except while typing | Opens the site search. The header shows the shortcut for the device. |
| / | Anywhere except while typing | On `/work`, puts the cursor in the catalogue search. Elsewhere, opens the site search. |
| Esc | Catalogue search | Clears the text. Pressed again on an empty field, releases the field. |
| Up, Down, Enter, Esc | Site search | Move through results, open one, close. |
| Esc | Small-screen menu | Closes it. |
| Page Up, Page Down | A page | Scrolls. |

Shortcuts are written in the interface where they apply (the header button, the hint under the
catalogue search, the foot of the search panel) and are not advertised on small screens.

Focus returns to where it came from: closing the site search gives the keyboard back to the
control that had it, and closing the menu returns it to the menu button. Both panels are modal
and keep focus inside while open.

## States

| Component | States |
| --- | --- |
| `AppButton` | Default, hover, focus ring, pressed (slight scale), disabled (dimmed), **busy** (a spinner beside the label, which stays; keeps the focus; does not act again). |
| `LinkText`, `ListLink`, `NavPill` | Default, hover, focus ring, pressed, current (a bar and bold weight as well as colour). |
| `ChipRow` | Default, hover, focus ring, selected (filled and bold, announced as checked). |
| `Card` | Default, hover (border and shadow), pressed (tint). Never moves. |
| `Input`, `SearchField` | Default, focus, read-only, **invalid** (danger border; the reason is in words above the field). `SearchField` adds a clear button once there is text. |
| `ReleaseAction` | Button for a published, allowlisted release; started (confirmation in words); withdrawn, superseded or unconfirmed (a statement, plus links to the project and to support). |
| Pages | Loading (skeleton in the page layout), error (what happened, and "Try again"), not found, empty. |

## Feedback

- **Downloads.** The text under the button gives the version, channel, platform, file name, file
  type and size, and names the host the link opens. Pressing it shows "Download started" with
  what to do if nothing happens, and a second press within four seconds is ignored, so one file is
  never fetched twice by a double click. Progress is not shown, because the browser, not the
  site, performs the download and reports it. A release whose link is not on the allowlist gets
  no button: it says why, and offers the project page and support.
- **Contact form.** Labels are always visible and say required or optional; placeholders are
  examples only. Problems appear on sending, next to their field, in words ("Problem: ..."), and
  the keyboard goes to the first one. Each clears as its field is corrected. Nothing typed is
  lost. While sending, the button shows progress and cannot be pressed twice. Success replaces
  the form with a confirmation of what happens next; failure shows a notice that stays, says the
  message is still there and that it is safe to try again.
- **Announcements.** Result counts (after typing pauses), "Download started" and the outcome of
  the form are sent to assistive technology with `Accessible.announce`. There are no toasts:
  confirmations appear in place, next to the control that caused them, and do not cover
  anything.

## Motion

Durations come from `Theme.fast` (130 ms), `Theme.medium` and `Theme.slow`, all zero when the
visitor asks their system for reduced motion. A new page is readable from its first frame; a
130 ms fade marks the change. Hover and focus changes are colour only. Nothing loops except the
loading skeleton and the busy spinner, and both are still under reduced motion. Scrolling is
never taken over.

## Verified destinations

`scripts/verify-releases.mjs` fetches every published destination and re-hashes direct files; it
runs daily in CI. A download button can only appear for a release that passed review and points
at an allowlisted HTTPS host, so "validate that targets resolve before release" is part of the
release workflow rather than a manual step.

## What was checked, and what was not

Checked on 8 October 2026:

- `npm test` (rules, database, security, release workflow).
- Desktop build rendered offscreen at 1200, 820 and 390 pixels wide: catalogue, filtered and
  empty views, project page with a download, contact form, menu and site search.
- WebAssembly build in headless Chrome, driven over the debugging protocol by
  `scripts/interaction-check.mjs` (17 checks, all passing, run once normally and once with
  reduced motion requested): "/" and typing in the catalogue, the address updating without new
  history entries, Esc clearing, a shared filtered address reopening as that view, the site
  search opening, closing and navigating from the keyboard, Back, contact-form validation with
  the keyboard moving to the first problem, and a download starting once on a double click and
  confirming itself. The download in that check is answered locally; the real file is not
  fetched.

Screenshots from those runs (desktop, small screen, keyboard and reduced motion) are in
[interaction-record/](interaction-record/).

Not checked, and still required before launch:

- A screen reader. The roles, names and announcements are set, but how a browser exposes a
  canvas application varies, and none has been tested. The WCAG 2.2 AA target is therefore
  **not claimed**; see [OPERATIONS.md](OPERATIONS.md).
- Firefox, Safari (including iOS, and Command+K on a Mac), Edge, and real touch devices.
- Browser zoom and text resizing, which do not behave in a canvas as they do on ordinary pages.
- A real download from the live site after deployment.
