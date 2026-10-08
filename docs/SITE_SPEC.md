# LSI Corp website specification

*Revised 6 October 2026. Replaces "LSI Tools Website Developer Specification".*

## What changed and why

The first specification described a toolbox: a catalogue of LSI's products with documentation
and downloads. The site is now about **LSI Corp as a digital service provider**. The company and
what it offers come first; the products LSI has built are its **portfolio**, the evidence for
those services. Downloads and documentation remain, as supporting material for the portfolio
rather than the reason the site exists.

## Purpose and outcome

A visitor should leave knowing who LSI Corp is, what it can do for them, what it has already
built, and how to start a conversation. Success is an enquiry from a prospective client or
partner, not a download.

The facts on the site come from the LSI company profile: founded in 2016; working across
technology, logistics and finance; a mission to simplify and enable commerce.

## Audiences

| Audience | What they need |
| --- | --- |
| Prospective clients and partners | What LSI offers, proof it can deliver, and a way to get in touch. |
| Merchants, investors and the press | Who LSI is and what it is building. |
| Users of an LSI product | Its status, documentation and official downloads. |
| LSI staff | To keep all of the above current without a developer. |

## Site map

| Page | Address | Purpose |
| --- | --- | --- |
| Home | `/` | Positioning statement, the services, how LSI creates value, selected work, call to enquire. |
| Services | `/services` | Each service: what it is, what it includes, and the portfolio work that demonstrates it. |
| Work | `/work` | The portfolio: searchable, and filterable by service, status and platform. The address carries the view (`/work?q=gold&status=available`). Each item shows its true status. |
| Work item | `/work/{slug}` | One product as a piece of work: overview, audiences, capabilities, requirements, getting started, help, release history. |
| About | `/about` | Company profile, mission, how LSI creates value, key facts. |
| Contact | `/contact` | Published contact details and an enquiry form. |
| Downloads | `/downloads` | Official releases by product and platform. Linked from the footer and from work items. |
| Documentation | `/docs`, `/docs/{product}/{page}` | Product guides. Linked from the footer and from work items. |
| Support and policies | `/support`, `/support/{policy}` | Product help, privacy notice, terms, accessibility statement. |
| Staff | `/admin` | Sign-in and content management. |

Main navigation: **Services, Work, About, Contact**. Everything else is in the footer.
Addresses are URL fragments (`/#/work/1145`). The earlier `/products` addresses still work.

## Primary journeys

1. **Evaluate LSI:** Home → Services → the work behind a service → Contact.
2. **Check the portfolio:** Home → Work → a work item → Contact, or its documentation.
3. **Enquire:** any page → Contact → send an enquiry → staff reply by email.
4. **Use a product:** Work item or Downloads → verified download or web app (unchanged).
5. **Maintain the site:** staff sign in → edit services, work, pages; handle enquiries; publish releases.

## Content rules

These carry over from the first specification and still hold.

- **Truthful status.** Every portfolio item shows Available, In Development, Coming Soon or
  Maintenance, in words. A planned capability is never described as available.
- **Verified links only.** A download or launch button appears only for a release that has been
  reviewed by a second person and published, pointing to an allowlisted HTTPS destination.
- **One record per product.** 1145Hz Player is the public name; LSI Player is its internal name.
- **Market analysis is not advice.** LSI Gold Digger carries its risk statement wherever it appears.
- **Claims match the profile.** Service descriptions describe capabilities demonstrated by the
  portfolio. Do not add client names, figures or guarantees that LSI has not approved.

## Content model

| Entity | Purpose |
| --- | --- |
| Site settings | Name, tagline, description, contact details, support details, allowed external domains. |
| Service | Name, tagline, summary, what it includes, order. |
| Work item (product) | The portfolio entry, including which services it demonstrates. |
| Documentation page, FAQ, page | As before. |
| Release | As before: draft → review → available → superseded or withdrawn. |
| Enquiry | Name, email, organisation, service of interest, message, consent, handling status and notes. |
| Staff, audit log | As before. |

## Enquiries and privacy

The contact form collects a name, an email address, an optional organisation and a message, with
explicit consent to be contacted. A visitor can send an enquiry and nothing else: enquiries can
be read only by signed-in staff, are not published, and are not written to the audit log. The
privacy notice says this. There is still no analytics or tracking.

## Technical basis

- **Front end:** a Qt Quick (QML) application compiled to WebAssembly.
- **Back end:** Supabase. The site's tables live in their own `lsicorp` schema inside the
  Supabase project that also serves 1145, and never touch that application's objects.
- **Hosting:** AWS Amplify Hosting.
- **Brand:** navy `#01245d` and gold `#ddab22`, the LSI mark and the LSI Corp wordmark.

Known limits of the WebAssembly approach (search indexing, screen-reader support, download size)
are listed in [OPERATIONS.md](OPERATIONS.md) and are unchanged by this revision. They matter more
now than they did for a toolbox: a company site that wants to be found by prospective clients is
the case that depends most on search engines being able to read it.

## Acceptance criteria

- The home page leads with LSI Corp and its services; the portfolio follows as supporting evidence.
- Every service lists the work that demonstrates it, and every work item lists its services.
- A visitor can send an enquiry; staff can read it, record notes and mark it handled; nobody else can read it.
- Portfolio status, documentation, downloads and the release workflow behave as in the first specification.
- Staff can change services, work, pages, contact details and releases without editing code.
- Installing the site's database changes nothing outside the `lsicorp` schema and its own storage bucket.

## To confirm with LSI

- **Service names and wording.** The four services (digital platforms, logistics technology,
  financial technology, market intelligence) are drawn from the company profile's focus areas and
  portfolio. LSI should confirm they are the services it wants to sell.
- **Whether LSI takes on client work** in each area, or presents these as in-house capabilities.
  The copy is written to be true either way; it can be made more direct once this is settled.
- **Contact details** (email, phone, location): empty until entered under Site settings.
- **Portfolio status.** 1145 has a live site at 1145.io, but its item still says In Development
  with no published release, because a release must be drafted and reviewed by staff.
