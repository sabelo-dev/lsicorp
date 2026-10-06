# Editing content and publishing releases

For LSI staff. Everything here is done in the site's admin area; nothing requires a developer.

## Signing in

Open the site, follow **Staff sign-in** in the footer (address `/#/admin`), and sign in with your
staff account. You see a tab for each thing your role can manage. Every list and record has its
own address, so you can send a colleague the link to a release that is waiting for review.

## Editing content

| Tab | What it changes | Notes |
| --- | --- | --- |
| Enquiries | Messages sent from the Contact page. | Set the status as you handle each one and keep notes. Reply by email; the sender's address is shown. |
| Services | What LSI offers: name, tagline, summary and what each includes. | Shown on the home page and the Services page. |
| Work | The portfolio: name, tagline, summary, status, the services each item demonstrates, audiences, capabilities, requirements, limitations. | Mark a capability `"availability": "planned"` until it is really released. |
| Documentation | Guides for each product, written in Markdown. | A page with status Draft is visible to staff only. Update "Last reviewed" when you check a page. |
| FAQs | Questions and answers per product. | Untick "Visible to the public" to hide one. |
| Pages | About, privacy notice, terms, accessibility statement. | |

Changes are live as soon as you save. Rules the site enforces:

- **Links** in content must be a path on this site (`/downloads`) or an `https` address on the
  allowed-domains list. Raw HTML is not accepted.
- **Product status** cannot be moved back to In Development or Coming Soon while the product has
  a published release. Withdraw the release first.
- **Planned means planned.** Do not describe a feature as available before it is. The product
  page lists Available and Planned capabilities separately, in words.

Naming: the media player is **1145Hz Player** in public, with **LSI Player** as its internal
name. It is one product record; do not create a second.

## Publishing a release

A release is one version of one product for one platform. It moves through these steps:

```
Draft  ->  In review  ->  Available  ->  Superseded or Withdrawn
```

### Checklist

**Prepare (release manager A)**

1. If this is the product's first release, set its status to Available (Work tab).
2. For a direct file: upload it to the approved host, then compute its SHA-256 and size from the
   file **as served** (download it back and hash that copy).
3. Releases > New release. Fill in product, platform, version, channel, release date, destination,
   compatibility, install steps, release notes, known issues, licence and support route.
   - Store release: destination type "Official app store listing" and the store URL.
   - Web app: platform "Web", destination type "Web application", the public app URL.
   - Direct file: destination type "Direct file download", plus file name, type, size and SHA-256.
     The URL must end with the file name.
4. Create, then **Submit for review**. Send the reviewer the page address.

**Review (release manager B, a different person)**

5. Open the destination yourself. Confirm it is the right product, version and platform.
6. For a direct file, download it and confirm the size and SHA-256 match the record.
7. Read the install steps and notes as a user would.
8. **Approve and publish**, or **Return to draft** with what needs fixing.

The site will not let the person who prepared (or last edited) a release approve it.

**After publishing**

9. Open the product page and the Downloads page and check the new button and details.
10. If an older version was live on the same platform and channel, it is marked Superseded
    automatically and keeps its own page.

### Changing or removing a published release

| You want to | Do this |
| --- | --- |
| Replace a link or fix details | **Unpublish to edit**, change it, submit for review again. While unpublished, the site shows "No release available" instead of a button. |
| Publish a newer version | Create it as a new release. Approving it supersedes the old one. |
| Pull a release | **Withdraw** and give the reason. The button disappears and the release page shows the reason. |

Published releases are never deleted, so there is always a record of what was offered and when.

## Audit log

The Audit log tab shows who created, changed or deleted each record, and what changed. It is
written by the database and cannot be edited, by anyone.

## Changing the starting content files

`content/` in the repository holds the content the site was first loaded with. It is only used
for a brand-new database and for the preview data bundled into the app. If you change it, run
`npm run seed` and commit the regenerated files. Day-to-day edits belong in the admin area.
