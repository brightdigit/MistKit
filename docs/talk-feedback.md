# Talk Feedback — CloudKit as Your Backend (dry run, 2026-05-05)

Notes from the Riverside dry run with Evan and Josh. The Keynote deck lives outside the repo, so this file is the durable home for talk-level feedback. Sibling to [`why-mistkit.md`](why-mistkit.md).

## Source

- Riverside dry run with Evan + Josh
- Raw transcript: [`transcriptions/transcript.txt`](transcriptions/transcript.txt)
- Self-reported deck completeness during the run: ~60%

## What's Working

- The **Heart Witch** Apple-Watch origin story (no login on a watch face → CloudKit) is the single best hook in the deck.
- The **"two and a half authentication methods"** framing is sharper than Apple's three-equal-methods presentation. API Token alone barely qualifies as a method — it's a prerequisite.
- The **GitHub Actions / Bushel / Celestra deployment story** is the strongest section. It's the part of the talk that does not exist in Apple's docs anywhere.
- The **CloudKit Dashboard walkthrough** (Tokens & Keys → openssl command → paste public key → done) is concrete and audience-friendly.

## Structural Changes

- **Open with Heart Witch.** Currently it shows up roughly five minutes in. Lead with the problem ("watch user can't type a password"), not company background.
- **Make the public-vs-private + auth-method a 2D matrix slide**, not a bullet list. It's the structure people will remember.
- **Move the deployment / GitHub Actions section earlier** and give it more time. It's defensible content; the intro is not.
- **Fold API Token into the Web Auth Token section.** "Two and a half" is honest framing for the intro, but a full slide on it is overkill — it's a prerequisite, not a peer method.

## Cuts

- **General CloudKit / NoSQL intro** — covered by the Part 1 article; assume the audience.
- **MistKit origin / Claude-Code rebuild deep dive** — that's Part 1/2 article territory; one slide max.
- **Field-type polymorphism deep dive** — same; ~30 seconds.
- **Error-handling deep dive** — same; ~30 seconds.
- **WASM / browser-extension tangent** — off-topic for backend services. Replace with one line: "running in a browser? Use CloudKit JS, not MistKit."
- **Roadmap / "what's next" closing** — the Part 2 article covers it; keep one slide for "where to follow along."

## Expand / Add

- **`CKFetchWebAuthTokenOperation`** — the iOS-app-to-backend handoff path. Audience members building iOS+server stacks will ask about it in Q&A. At minimum one slide saying "the other way to get a web auth token is from inside an iOS app via `CKFetchWebAuthTokenOperation`; haven't shipped this pattern personally but here's the documented flow."
- **The signing payload format** — the talk hand-waves "Claude figured it out from the docs." Show the canonical string (HTTP method + ISO 8601 timestamp + SHA-256 body hash + path) and the `Authorization` header format. Pull straight from `Sources/MistKit/Service/AuthenticationMiddleware.swift`.
- **Web-auth-token lifetime / refresh** — one bullet. If unknown, spend 15 minutes in the dashboard before the live talk.

## Audio / Delivery Cleanup (for the recorded version)

Lines from the transcript to clean up:

- "Sorry, just going into Do Not Disturb mode."
- "I hate Teams."
- "Surprised? I mean, I know they have an app."
- Multiple "sorry, slides aren't done" asides — replace with confidence in the recorded take.

## Brand / Spelling

The auto-transcription introduces several errors that would propagate if the transcript is fed back into Claude as source material:

- "Heart Witch" → mangled as "Hart Twitch" / "Hardwitch" throughout. Confirm the on-screen spelling and the slide title before recording.
- "MistKit" → consistently transcribed as "Miskit." Search-and-replace before reuse.
- Around the WASM tangent (line 135), "WASM" gets transcribed as "awesome."

## Q&A Prep — Likely Audience Questions

- **"How do I get a web auth token from inside my iOS app?"** → `CKFetchWebAuthTokenOperation`. (See *Expand* above.)
- **"Can I use this from a browser extension?"** → Yes for non-Safari, but use CloudKit JS unless you specifically need Swift.
- **"What's the production story for key storage?"** → GitHub Actions Secrets in Bushel / Celestra; secrets manager or env-var injection in general.
- **"Does this work on Linux?"** → Yes — that's the whole point. Also Windows and Android. Not WASM yet (no transport).
- **"How does this compare to using Vapor + the CloudKit framework?"** → The CloudKit framework only runs on Apple platforms. MistKit runs anywhere Swift runs.
