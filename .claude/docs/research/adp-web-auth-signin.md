# CloudKit JS web-auth sign-in fails for Advanced Data Protection accounts

**Date:** 2026-09-14
**Container:** `iCloud.com.brightdigit.MistDemo` / `development` (MistDemo `auth-token` browser flow, which
embeds CloudKit JS from `https://cdn.apple-cloudkit.com/ck/2/cloudkit.js`)
**Question:** Why does the CloudKit JS sign-in popup (`container.setUpAuth()` → Apple ID sign-in →
`ckWebAuthToken` for `api.apple-cloudkit.com`) fail for an iCloud account with Advanced Data Protection
(ADP) enabled, and is there any supported way to obtain a `ckWebAuthToken` for such an account?
**Issue:** #392 — this is the B1a / B2 result from the test protocol in the issue's addendum comment.

**Bottom line:** There is **no supported way** to obtain a usable `ckWebAuthToken` for a third-party
container while ADP is on. Apple never says so in one sentence, but it follows from three things Apple
*does* state: (1) ADP deletes the CloudKit Service keys from Apple's HSMs, so web servers can no longer
decrypt anything in the private database; (2) the trusted-device "web access" window re-uploads keys
"only [for] an allow list of services normally accessible on iCloud.com", and only encrypted to "an
ephemeral key bound to the web session that the user authorized"; (3) that session is an **iCloud.com**
session, and a third-party CloudKit container is neither an iCloud.com service nor party to that session.
The popup's two messages are the iCloud.com web-access gate (first) and CloudKit JS's generic sign-in
catch-all (second). The only way to get web-auth working is to **turn ADP off** on the account.
Server-to-server access to the **public** database is unaffected.

---

## 1. Observed

Observed today, 2026-09-14, against container `iCloud.com.brightdigit.MistDemo` (development
environment), using MistDemo's `auth-token` browser flow (Examples/MistDemo, which embeds CloudKit JS):

1. With ADP on and iCloud web access off, the popup shows: "iCloud Data Web Access is Off — To access
   your data, turn on Allow iCloud Data Access on the Web. From your Apple device, go to Apple ID
   settings > iCloud."
2. After turning "Access iCloud Data on the Web" on AND arming a trusted device (signing in at
   icloud.com and approving on the device), the same popup shows: "Authentication Error — This action
   could not be completed. Please close the window and try again."
3. A standard-protection account signs in fine through the identical flow within a minute, so the API
   token and flow are healthy.

Observation 2 is, by itself, the **B2 result**: the one-hour trusted-device window was armed and the
sign-in still failed. Observation 1 is the **B1a result**: with ADP on and web access off, no token is
issued at all. Both mean B1b/B1c/B3 (reads, writes, asset download under ADP via web-auth) are moot —
there is no token to make those requests with.

### 1.1 Chrome HAR of observation 2 (2026-09-14, experiment 1 run)

Two HAR exports (no bodies) of the failing sign-in in Chrome 153, ADP account, web access on,
trusted device armed. Chrome behaves exactly like Safari, which closes the browser-variant question.
Sequence in the popup, all times UTC:

| # | Request | Status | Note |
|---|---|---|---|
| 17:11:11 | `GET idmsa.apple.com/IDMSWebAuth/auth?oauth_token=…` | 200 | Apple ID sign-in page opened by CloudKit JS |
| 17:11:44 | `POST idmsa.apple.com/appleauth/auth/signin/init` | 200 | password step |
| 17:12:02 | `POST …/signin/complete` | 409 | normal two-factor handoff |
| 17:12:04–19 | `POST …/auth/bridge/step/0,2,4`, `…/bridge/code/validate` | 200 | trusted-device push approval (one trailing `step/4` returns 400 after `code/validate` succeeded) |
| 17:12:19 | `POST idmsa.apple.com/auth` | **302** | `Location: https://cdn.apple-cloudkit.com/ck-auth/?prtn=54&host=setup.apple-cloudkit.com&oauth_token=…&oauth_verifier=…` — Apple ID **did** issue an OAuth token + verifier for CloudKit |
| 17:12:19 | `GET cdn.apple-cloudkit.com/ck-auth/` | 200 | the CloudKit auth landing page |
| 17:12:20 | `GET setup.apple-cloudkit.com/setup/ws/1/oauth/validateToken?prtn=54&host=…&oauth_token=…&oauth_verifier=…` | **200, 13-byte JSON body** | no `X-Apple-CloudKit-Web-Auth-Token` header, no `Set-Cookie`, `x-apple-user-partition: 45` |
| 17:12:21 | `POST feedbackws.icloud.com/reportStats` | 200 | body `{"stats":[{"statName":"CKAUTHunknownError","appName":"CKAUTH","httpMethod":"GET"}]}` |

In the opener window CloudKit JS then called `GET api.apple-cloudkit.com/…/development/public/users/caller`
→ **421** (no session), and reported
`{"statName":"CKJSUnexpectedAuthError","appName":"CKJS","ckjsBuildVersion":"2420ProjectDev22"}`.

**Reading.** Apple ID authentication and the two-factor device approval both succeed and hand
CloudKit an OAuth token. The step that fails is CloudKit's own token exchange, `validateToken` on
`setup.apple-cloudkit.com`: it answers 200 with a 13-byte JSON body and mints no web-auth session,
after which the `ck-auth` page shows the generic "Authentication Error" and logs `CKAUTHunknownError`.
So the ADP gate sits inside CloudKit's session setup, not in Apple ID sign-in and not in the
Web Services API. The 13-byte body was not in the export (HAR saved without content); capturing it
is the remaining cheap step. HAR copies (session tokens inside — never commit) are kept outside the repo.

### 1.2 The 13-byte body and what the auth page does with it (2026-09-14)

Leo read the `validateToken` response in DevTools: **`{"status":13}`**.

Apple's auth landing page script, `https://cdn.apple-cloudkit.com/ck-auth/scripts/ckauth.js`
(fetched 2026-09-14, 9.5 KB, minified), handles the `status` of a `validateToken` /
`repair` / `requestPCS` response like this — quoted from the script, deobfuscated only by
whitespace:

| `status` | Handling in `ckauth.js` | User sees |
|---|---|---|
| `0` | `isSuccessResponse` → `sendCKSession`: posts `{ckSession, …}` to the opener (`postToOpener`) or redirects to `appInfo.DevUrl?ckWebAuthToken=…&ckSession=…` | popup closes, CloudKit JS has a token |
| `7` | `confirmTOS`: fetches `oauth/getLiteTerms`, shows the terms dialog, then `oauth/repair` with `acceptedICloudTerms` | iCloud terms prompt |
| `11` | `isPollingResponse`: waits `callbackDuration` s (default 5), then `POST oauth/requestPCS {accountsToken, appInfo}` and re-evaluates, at most 10 retries ("Polling cancelled after 10 retries") | spinner while the account's trusted devices are asked to release keys (PCS = Protected Cloud Storage) |
| `12` | `accessErrorHandler`: shows `#accessError` (`Error.WebAccess.Title` / `Error.WebAccess.Message`, link to `https://support.apple.com/kb/HT212523`), posts `{errorMessage:"accessError"}` to the opener | **"iCloud Data Web Access is Off"** (observation 1) |
| anything else | `throw new Error("Error status received: " + e.status)` → the shared `.catch`: shows `#error` (`Error.Generic.Title` / `Error.Generic.Message`), posts `{errorMessage:"unknownError"}` to the opener, telemetry `CKAUTHunknownError` | **"Authentication Error — This action could not be completed."** (observation 2) |

The page's entire English string table (`ck-auth/l10n/en-us.lproj/strings.json`, 22 keys) contains
exactly two error states: `Error.Generic.*` ("Authentication Error / This action could not be
completed…") and `Error.WebAccess.*` ("iCloud Data Web Access is Off…"). There is no ADP-specific
message anywhere in the page.

So `{"status":13}` is a status the auth page has **no handler and no localized text for**. It is
returned by `validateToken` itself, immediately — the HAR shows no `requestPCS` call, so the
polling/key-release path was never entered. It is distinct from `12` (web access off), which is
exactly the state that changed between observation 1 and observation 2 when web access was turned
on. The `requestPCS` name confirms that a successful web-auth session depends on Protected Cloud
Storage keys being released for the account, which is the mechanism ADP removes from Apple's
servers (§2.2).

**Inference (marked as such):** `13` is CloudKit's "account keys unavailable / ADP" terminal
status. Apple publishes no table of these status values; the closest primary confirmation would be a
standard-protection account's `validateToken` returning `0` or `11` through the same page (see
experiment 1b below).

### 1.3 Control: how iCloud.com itself gets keys for the same ADP account (2026-09-14)

Sanitized Chrome HAR (no bodies, no cookies) of icloud.com with the **same ADP account**, web access
on, opening Notes. Same Apple ID steps as §1.1 (password, `signin/complete` 409, trusted-device
`bridge/step/*`), then iCloud's own session setup on `setup.icloud.com/setup/ws/1/` — the same
`ws/1` API family the CloudKit popup uses on `setup.apple-cloudkit.com`:

| time (UTC) | Request | Resp size | Note |
|---|---|---|---|
| 17:36:08 | `POST setup/ws/1/accountLogin` (`dsWebAuthToken`, `trustToken`) | 6.6 KB | iCloud session |
| 17:36:11 | `GET setup/ws/1/generateSessionIdToken` | 397 B | |
| 17:36:13 | `POST setup/ws/1/requestWebAccessState` | 131 B | polled |
| 17:36:13 | `POST setup/ws/1/enableDeviceConsentForPCS` | 151 B | asks the trusted device |
| 17:36:23 | `POST setup/ws/1/requestWebAccessState` | 131 B | still pending |
| 17:36:34 | `POST setup/ws/1/requestWebAccessState` | 142 B | state changed — device approved |
| 17:36:34 | `POST setup/ws/1/requestPCS` `{"appName":"notes3","derivedFromUserAction":true,"isFinalAttempt":false}` | 194 B | per-app key release |
| 17:36:42 | `POST setup/ws/1/requestPCS` `{"appName":"notes3","derivedFromUserAction":false,…}` | 172 B | second poll |
| 17:36:43→45 | 13 × `POST p42-ckdatabasews.icloud.com/database/1/com.apple.notes/production/private/…` (`records/query`, `records/lookup`, `zones/lookup`, `changes/zone`, `subscriptions/modify`) | all **200**, up to 4 KB | Notes reads its **encrypted** fields (`desiredKeys` include `TitleEncrypted`, `SnippetEncrypted`) — server-side decryption working for an allow-listed app inside the armed window |

**What this settles.**
- Web-services decryption *does* work for an ADP account — for Apple's own container
  (`com.apple.notes`), through the exact `/database/1/{container}/{env}/private/…` API shape
  MistKit speaks, once `requestPCS` has released that app's keys for the session. That is Apple's
  "allow list of services normally accessible on iCloud.com" (§2.3) in action.
- The key release is **per app** (`appName: "notes3"`) and only starts after `requestWebAccessState`
  reports device consent. The CloudKit popup's equivalent (`oauth/requestPCS` with `appInfo`, §1.2)
  is never reached, because `validateToken` returns `{"status":13}` first. A third-party container
  is therefore refused one step *before* the key-release loop that first-party apps go through.
- Nothing in the iCloud.com flow is reusable by a third-party web-auth session: the consent and the
  PCS release are bound to the icloud.com session, and the CloudKit popup runs its own session on
  `setup.apple-cloudkit.com`.

Bodies of the six `setup/ws/1` calls were not in the export (Chrome's "Export HAR (sanitized)"
drops bodies and cookies; the "with sensitive data" variant keeps them). They would only add
the status vocabulary iCloud.com uses, which may or may not share CloudKit's numbering.

## 2. What Apple states

Claims in this section are quoted from Apple pages that were fetched and read directly in this session.

### 2.1 Why web-services access works at all under standard protection

> "Available-after-authentication service keys: For other services, such as Photos and iCloud Drive,
> the service keys are stored in iCloud Hardware Security Modules in Apple data centers, and can be
> accessed by some Apple services."
> — *iCloud encryption* (Apple Platform Security, May 7 2024)

> "Each container's private database is protected by a key hierarchy, rooted in an asymmetric key
> called a CloudKit Service key."
> — *iCloud encryption*

Public databases are not in this key hierarchy (per the issue's addendum, quoting the same page: they
"are globally shared, typically used for generic assets, and aren't encrypted").

### 2.2 What ADP does to those keys

> "All CloudKit Service keys that were generated on device and later uploaded to the
> available-after-authentication iCloud Hardware Security Modules (HSMs) in Apple data centers are
> deleted from those HSMs, and instead kept entirely within the Apple Account's iCloud Keychain
> protection domain."
> — *Advanced Data Protection for iCloud* (Apple Platform Security, Dec 7 2022)

> "After the keys are deleted, Apple can no longer access any of the data protected by the user's
> service keys. At this time, the device begins an asynchronous key rotation operation, which creates
> a new service key for each service whose key was previously available to Apple servers."
> — *Advanced Data Protection for iCloud* (quoted in issue #392 addendum; same page)

### 2.3 Web access under ADP — the allow list and the session binding

This is the paragraph that decides the question. Verbatim:

> "After turning on web access, the user needs to authorize the web sign-in on one of their trusted
> devices each time they visit iCloud.com. The authorization arms the device for web access. For the
> next hour, this device accepts requests from specific Apple servers to upload individual service
> keys, but only those corresponding to an allow list of services normally accessible on iCloud.com.
> In other words, even after the user authorizes a web sign-in, a server request is unable to induce
> the user's device to upload service keys for data that isn't intended to be viewed on iCloud.com,
> (such as Health data or passwords in iCloud Keychain). Apple servers request only the service keys
> needed to decrypt the specific data that the user is requesting to access on the web. Every time a
> service key is uploaded, it is encrypted using an ephemeral key bound to the web session that the
> user authorized, and a notification is displayed on the user's device, showing the iCloud service
> whose data is temporarily being made available to Apple servers."
> — *Advanced Data Protection for iCloud*

And the reason web access is off by default:

> "When a user first turns on Advanced Data Protection, web access to their data at iCloud.com is
> automatically turned off. This is because iCloud web servers no longer have access to the keys
> required to decrypt and display the user's data."
> — *Advanced Data Protection for iCloud*

The user-facing support page enumerates what "web access" covers and confirms the approval is
**per data category** on iCloud.com:

> "Mail, contacts, calendar, photos, notes, reminders, files, and documents" can be accessed only on
> trusted devices when web access is off.
> "For the next hour, your device provides approval each time that you access a new category of data."
> — *Manage web access to your iCloud data* (support.apple.com/102630, Mar 24 2026)

The same page documents the exact alert seen in observation 1 — as an **iCloud.com** alert:

> "…when you sign in to iCloud.com, you see an alert confirming that iCloud Data Web Access is Off and
> you can't access your data."
> — *Manage web access to your iCloud data*

Neither page mentions third-party apps, developers, or CloudKit containers in the web-access context.
(Checked explicitly; the fetch of 102630 returned "No mentions of third-party applications".)

### 2.4 What ADP says about third-party CloudKit data

> "Advanced Data Protection also automatically protects CloudKit fields that third-party developers
> choose to mark as encrypted, and all CloudKit assets."
> — *Advanced Data Protection for iCloud*

> "When you turn on Advanced Data Protection, third-party app data stored in iCloud Backup and CloudKit
> encrypted fields and assets are end-to-end encrypted."
> — *iCloud data security overview* (support.apple.com/102651, Jan 5 2026)

### 2.5 Turning ADP off restores standard protection

> "The device uploads both the original service keys, generated before Advanced Data Protection had
> been turned on, and the new service keys that were generated after the user turned on the feature.
> This makes all data in these services accessible after authentication and returns the account to
> standard data protection."
> — *Advanced Data Protection for iCloud* (quoted in issue #392 addendum; same page)

### 2.6 What Apple's developer documentation says — nothing

Every developer-facing source was checked for any ADP / web-access statement:

| Source | ADP / web-access mention? |
|---|---|
| *Encrypting user data* — "Use CloudKit Web Services" section (read via livingston/apple-docs mirror) | **None.** The section documents `isEncrypted` on `records/modify` and says "The web services handle the encryption and decryption for you." No preconditions on the user's protection mode. |
| CloudKit JS `setUpAuth` reference (`.claude/docs/cloudkitjs.md:6418`) | **None.** Documents only: resolves to `UserIdentity` or `null`; "If an error occurs, a `Promise` object that rejects to a `CKError` object." No enumerated failure conditions. The live `developer.apple.com` page and its DocC JSON returned 404 for the paths tried; the offline copy is the source used. |
| Archived *CloudKit Web Services Reference* (`.claude/docs/webservices.md`) | **None** (predates ADP by ~7 years). |
| CKTool / CKTool JS docs (`.claude/docs/cktool*.md`, `cktooljs*.md`) | **None.** They distinguish *management* tokens (schema commands) from *user* tokens (data "on behalf of the user", obtained via CloudKit Console sign-in). |
| WWDC23 *What's new in privacy* (10053) | ADP section says only: "By adopting CloudKit, you can end-to-end encrypt data stored in CloudKit by your app whenever someone enables Advanced Data Protection… use encrypted data types for all fields in your CloudKit schema." No transcript sentence mentions iCloud.com, web, or trusted devices. |
| WWDC22 *What's new in CloudKit Console* (10115) | Introduces "Act As iCloud"; states "Encrypted fields remain unreadable to you when acting as another account. Only the original user who owns the data can decrypt it." No ADP mention (it shipped six months later). |

**Apple states** nothing, anywhere found, that explicitly says "CloudKit JS / CloudKit Web Services /
CloudKit Console cannot sign in an ADP account." The conclusion is inference from §2.2–2.3.

## 3. What Apple staff state

No Apple staff reply found addresses ADP + web-auth head on. The closest:

- **Thread 741011** ("Advanced Data Protection and CloudKit Console", Nov 2023): reporter enabled ADP
  and "this (understandably) broke access to my private records in CloudKit Console"; disabling ADP
  did not restore it. A **Developer Tools Engineer (Apple)** replied only: "Have you tried signing out
  of CloudKit Console, and signing in back?" No further staff follow-up; reporters say it stayed broken
  ("Mine's been broken for nearly a year", Aug 2024) and a new +1 arrived Jun 2026.
- **Thread 772544** (keychain reset testing, Jan 2025): **DTS Engineer Ziqiao Chen** relayed from the
  CloudKit team: "You need to turn on iCloud Advanced Data Protection… for the testing. With ADP being
  on, a deleted key is un-recoverable, and triggers the zone deletion on the server side." Confirms the
  server has no copy of the user's keys under ADP; says nothing about web access.
- **Thread 764076** (Sep 2024, DTS Engineer Ziqiao Chen): the CloudKit JS web-auth token "expires
  30 minutes after it is created. If the user selects 'Keep me signed in' during the sign-in window,
  the duration of the token is 2 weeks." Relevant to experiment 5 below (a token minted *before* ADP
  is switched on).
- **Thread 795097** (Jul 2025, DTS): for `setUpAuth()` returning null, "Confirm your Apple ID works by
  running `.setUpAuth()` in the CloudKit Catalog authentication page:
  `https://cdn.apple-cloudkit.com/cloudkit-catalog/#authentication`". Useful as a flow-independent
  control for experiment 1.

## 4. Community reports

- **Thread 723945** ("CloudKit JS issue with Advanced Data Protection", Jan 2023): after enabling ADP
  *and* "Access iCloud Data on the Web", `…/production/private/records/lookup` returned
  `serverErrorCode: "ACCESS_DENIED"`, `reason: "private db access disabled for this account"`. Note
  two things: it was **production**, and the **sign-in succeeded** — the failure surfaced on the first
  API call. Reply (deeje, no badge): re-enabling web access requires the trusted-device approval,
  "Unclear to me so far if this extends to all/any CloudKit JS clients."
- **Thread 844105** (CloudKit Console, ~Aug 2026): "Act as iCloud User… I get an authentication
  error." Reply (deeje): "fwiw I need to disable Advanced Data Protection and enable iCloud.com in
  order to log into the iCloud developer console."
- **Thread 833247** (Jun 2026): "Act as iCloud Account" login "never works… for more than 6 months".
  Unanswered; ADP not mentioned.
- **Thread 101410** (Apr 2018 / Sep 2019): the exact text "Authentication Error — This action could
  not be completed. Please close the window and try again." from the CloudKit JS sign-in page,
  **pre-ADP**. In 2019 the browser console showed the popup being refused a connection to
  `https://setup.apple-cloudkit.com/setup/ws/1/oauth/validateToken?…` by CSP; it "started working…
  today. Looks like Apple has resolved the issue." So this page is the widget's generic failure page
  for the token-validation / session-setup step, not an ADP-specific message.
- **icloud_photos_downloader #687 / #1024, docker-icloudpd #250** (2022–2026): the same
  `ACCESS_DENIED` / `"private db access disabled for this account"` string is what iCloud's *own*
  Photos private-DB endpoints return to an emulated-browser client under ADP. Maintainers document ADP
  as **not supported** because the tool "simulates web access, which is disabled with ADP"; turning
  ADP off resolves it (jkraemer, Mar 2025). Enabling "Access iCloud Data on the Web" alone does not —
  the approval "wasn't triggered until I click the photos icon on iCloud.com" (Sep 2023).
- **steilerDev/icloud-photos-sync #202** (2023): the only third-party client that tried to drive the
  window mechanically. Findings: under ADP, iCloud.com obtains per-service **PCS cookies** after the
  trusted-device approval; they require a `X-APPLE-WEBAUTH-HSA-LOGIN` cookie from the iCloud.com
  login, and "the PCS cookies seem to be valid for" about an hour. That is the client-side shape of
  Apple's "ephemeral key bound to the web session" statement — and it is bound to the **iCloud.com**
  session, for iCloud.com services.

## 5. Answers to the sub-questions

### 5.1 Is the one-hour window limited to an allow list, and does that exclude third-party containers?

**Apple states** the window uploads keys "only [for] an allow list of services normally accessible on
iCloud.com", that servers "request only the service keys needed to decrypt the specific data that the
user is requesting to access on the web", and that each upload is "encrypted using an ephemeral key
bound to the web session that the user authorized" (§2.3). **Apple states** the categories web access
covers are mail, contacts, calendar, photos, notes, reminders, files, documents (§2.3).

**Inference** (from the above plus §4): a third-party CloudKit container is not "a service normally
accessible on iCloud.com", nothing on iCloud.com ever "requests" its data, and the CloudKit JS popup
(`cdn.apple-cloudkit.com` / `setup.apple-cloudkit.com`) is a different web session from the one the
device armed at `icloud.com`. Each of the three conditions independently prevents the container's
service key from reaching Apple's servers on behalf of a CloudKit JS session. So yes — under ADP,
third-party web-auth against the private/shared database is impossible **by design of the key model**,
not by a bug or a missing switch. Apple does not say this in so many words.

### 5.2 Does Apple document it anywhere?

**No** (§2.6). Not in *Encrypting user data*, the CloudKit JS reference, the archived Web Services
reference, the CKTool / CKTool JS docs, or the WWDC21/22/23 sessions checked. Apple's only relevant
statements are in the Platform Security guide and the two consumer support pages, and they are written
about iCloud.com, not about developer containers. No Apple staff forum reply addresses it (§3).

### 5.3 Is the CloudKit Console affected the same way?

**Community reports** say yes (threads 741011, 844105, 833247): "Act as iCloud Account" and the
private/shared database views fail to sign in for ADP accounts, and the only reported fix is disabling
ADP (with one report that access stayed broken for a year afterwards). **Inference:** the Console's
Act-As sign-in is the same iCloud web sign-in machinery and needs the same service keys, so it is
gated identically. Separately, **Apple states** (WWDC22) that even under standard protection encrypted
fields "remain unreadable to you when acting as another account".

### 5.4 Known workarounds

| Workaround | Verdict | Basis |
|---|---|---|
| Sign in at icloud.com first, approve on device, then use the CloudKit JS popup | **Does not work — tested (observation 2).** | Apple states the uploaded keys are bound to the iCloud.com session and allow-listed services (§2.3). |
| Wait for the asynchronous key rotation to finish | **Not expected to help.** Rotation mints *new* keys that also never go to the HSMs. Worth one cheap retry after 24 h only to rule out a transient. | Apple states rotation is asynchronous (§2.2); inference on the rest. |
| Safari vs Chrome | **Does not help — tested (§1.1).** Chrome 153 fails at the same `validateToken` step. Thread 741011 saw the same across Firefox/Chrome/Safari for the Console. | Tested + community report. |
| Production vs development environment | **Not expected to differ.** Thread 723945 failed against production; today's failure is development. The gate is account-level, not environment-level. | Community report + inference. |
| Temporarily disable ADP | **Works, by design.** Re-uploads old and new service keys and "returns the account to standard data protection". Records written while ADP was on should become readable. Caveat: thread 741011 reports the Console staying broken long after. | Apple states (§2.5); community (844105, icloudpd #1024). |
| CKTool JS with a management token | **Not a workaround.** Management tokens are for schema commands; reading user data needs a *user* token, which is obtained by signing in through CloudKit Console — the same gated path. | Apple states (cktool docs, `.claude/docs/cktool-full.md:40-73`). |
| Server-to-server key | **Public database only** — CloudKit rejects S2S on private/shared. Public DB has no user key hierarchy, so it is unaffected by ADP. | Apple states (§2.1); MistKit auth model (CLAUDE.md). |
| Token minted before ADP was enabled ("Keep me signed in", 2-week token) | **Untested.** Would not decrypt anything (keys are gone) but is the only way to observe the *API-side* error shape MistKit would surface. See experiment 5. | DTS statement on token lifetime (thread 764076); inference. |

### 5.5 What does the "Authentication Error — This action could not be completed" page correspond to?

**Not documented by Apple.** **Community report** (thread 101410) places the same text on the CloudKit
JS sign-in page in 2018–2019 with a non-ADP cause (a blocked call to
`setup.apple-cloudkit.com/setup/ws/1/oauth/validateToken`), fixed server-side. **Inference:** it is the
widget's generic catch-all for a failed post-Apple-ID step — token validation / CloudKit session setup
at `setup.apple-cloudkit.com`. Under ADP the Apple ID login itself succeeds (that is why the message
changes once web access is on), but the step that establishes a private-database session for the
container cannot complete, and the widget shows its generic page. Contrast with thread 723945 (Jan
2023), where sign-in *succeeded* and the denial arrived as `ACCESS_DENIED` on the first API call —
suggesting Apple has since moved the enforcement earlier, into session setup. The failing request and
its response body are the one thing this session could not observe; experiment 1 captures it.

## 6. Verdict

**Web-auth (`ckWebAuthToken`) for a third-party container is unobtainable while ADP is on, and there is
no supported workaround other than turning ADP off.**

1. **Apple states** the private database's keys leave Apple's servers under ADP and "Apple can no
   longer access any of the data protected by the user's service keys" (§2.2).
2. **Apple states** the only re-upload path is allow-listed to "services normally accessible on
   iCloud.com", scoped to "the specific data that the user is requesting to access on the web", and
   bound to the iCloud.com web session (§2.3). A third-party container fails all three.
3. **Observed** (§1): arming the window does not change the outcome — the popup fails at session
   setup instead of at the web-access gate.
4. **Community reports** (§4) show the same for the CloudKit Console and for Apple's own Photos private
   DB via emulated clients, with "disable ADP" the only reported fix.
5. **Apple documents none of this for developers** (§2.6); the failure surfaces as a generic widget
   page, and — when a token exists — as `ACCESS_DENIED` / `"private db access disabled for this
   account"`.

## 7. What this means for MistKit

- **B1a and B2 are answered: fail, by design.** B1b, B1c and B3 (encrypted reads/writes and asset
  download under ADP via web-auth) cannot be exercised because no token is issued. The scenario matrix
  in #392 should mark them "unreachable — no web-auth token under ADP" rather than "code TBD".
- **Nothing to fix in MistKit's request/response path.** The failure happens in the browser before
  any `api.apple-cloudkit.com` call. The `isEncrypted` feature (#392) should proceed on the standard-
  protection assumption Apple's *Encrypting user data* page implicitly makes.
- **The one API-side shape MistKit could meet** is `HTTP 403` `ACCESS_DENIED` with reason
  `"private db access disabled for this account"` (thread 723945), if a caller holds a token minted
  before ADP was enabled. MistKit already maps this to `CloudKitError.accessDenied(reason:)`
  (`Sources/MistKit/CloudKitService/CloudKitError.swift:59`) and preserves the `reason` string, so a
  caller can pattern-match it. Do **not** add an ADP-specific error case on the strength of one
  2023 report; document the string on `accessDenied` once experiment 5 confirms it.
- **Documentation:** MistDemo's `auth-token` / `auth-tokens` docs and the MistKit web-auth docs should
  state that ADP-enabled Apple Accounts cannot complete web-auth sign-in and that the two popup
  messages above are the symptom; the fix is a standard-protection test account or turning ADP off.
- **Public database + server-to-server is unaffected** — the public DB is outside the user key
  hierarchy. Any "works under ADP" claim for MistKit must be scoped to that path.
- **Test-account hygiene:** keep the integration accounts on standard protection. An ADP account is
  useful only for experiments 1–5 below.

## 8. Recommended next experiments (ranked by cost)

1. **Done (§1.1–1.2).** The failing request is `validateToken` → `{"status":13}`, unhandled by `ckauth.js`.
1b. **Control capture with the standard account** (minutes). Same DevTools capture, standard account: record whether `validateToken` returns `status 0` directly or `11` followed by `requestPCS` polling. That fixes what "healthy" looks like and makes the reading of `13` a comparison rather than an inference.
1c. **Original — capture the popup's failing request** (minutes). Open the sign-in URL the CloudKit JS button
   opens in a normal tab with DevTools → Network ("Preserve log"), reproduce observation 2, and record
   the request to `setup.apple-cloudkit.com` (or `idmsa.apple.com`) that returns non-2xx, with status
   and body. This is the only way to turn §5.5 from inference into fact. Also run the same account
   through Apple's own control page, `https://cdn.apple-cloudkit.com/cloudkit-catalog/#authentication`,
   to rule out anything MistDemo-specific.
2. **Browser and environment variants** (minutes). Safari vs Chrome; a production-environment API
   token. Expected: no change.
3. **CloudKit Console "Act as iCloud Account"** with the ADP account (minutes). Expected: authentication
   error, matching threads 741011/844105. Confirms the Console shares the gate.
4. **Retry after 24 h** (minutes, one day later). Rules out the asynchronous key rotation as a
   transient factor. Expected: no change.
5. **Token-before-ADP** (about an hour, needs toggling ADP twice). Turn ADP off, sign in with "Keep me
   signed in" (2-week token per DTS), turn ADP back on, then call `records/lookup` on the private DB
   with that token via `curl` and via MistKit. Captures the API-side error shape (expected
   `ACCESS_DENIED` / `"private db access disabled for this account"`) — the one thing MistKit could
   actually surface. Also try a `zones/list` and a public-DB query with the same token to see whether
   the token is dead or only the private DB is gated.
6. **Recovery check** (hours). Turn ADP off, wait for the key re-upload, confirm sign-in works again
   and that any records written before are readable. Validates §2.5 for test-data recovery.
7. **Ask Apple** (days). File Feedback / a DTS TSI asking for a documented statement that CloudKit
   Web Services and CloudKit JS cannot authenticate ADP accounts, and whether that is intended. Cite
   threads 723945 and 741011.

## 9. Draft comment for issue #392 (B1a / B2 result)

> **B1a/B2 result (2026-09-14, `iCloud.com.brightdigit.MistDemo`/development, MistDemo `auth-token`):
> web-auth sign-in fails for an ADP account, and arming the trusted-device window does not help.** With
> ADP on and web access off, the CloudKit JS popup shows the iCloud.com gate ("iCloud Data Web Access
> is Off…"); with web access on and a trusted device armed (signed in at icloud.com, approved on
> device), the same popup shows the widget's generic "Authentication Error — This action could not be
> completed" page; a standard-protection account signs in fine through the identical flow. This is by
> design of the key model rather than a bug: Apple states ADP deletes the CloudKit Service keys from
> its HSMs, and that the one-hour window re-uploads keys "only [for] an allow list of services normally
> accessible on iCloud.com", scoped to "the specific data that the user is requesting to access on the
> web" and "encrypted using an ephemeral key bound to the web session that the user authorized" — a
> third-party container is none of those, and the CloudKit JS popup is not that session. Apple documents
> none of this for developers (checked *Encrypting user data*, the CloudKit JS and Web Services
> references, CKTool docs, WWDC21/22/23), and no Apple-staff forum reply addresses it; community
> reports show the CloudKit Console "Act as iCloud Account" fails the same way (threads 741011, 844105)
> and that the only fix is turning ADP off. Consequences: B1b/B1c/B2/B3 are unreachable (no token);
> nothing changes in MistKit's request/response path; the only API-side shape we could ever meet is
> `ACCESS_DENIED` / `"private db access disabled for this account"` (thread 723945, Jan 2023) with a
> token minted *before* ADP was enabled, which `CloudKitError.accessDenied(reason:)` already carries.
> Public DB + server-to-server is unaffected. Full write-up with quotes and next experiments:
> `.claude/docs/research/adp-web-auth-signin.md`.

## 10. Sources

Apple (read directly this session unless noted):

- *Advanced Data Protection for iCloud*, Apple Platform Security guide (Dec 7 2022):
  https://support.apple.com/guide/security/advanced-data-protection-for-icloud-sec973254c5f/web
- *iCloud encryption*, Apple Platform Security guide (May 7 2024):
  https://support.apple.com/guide/security/icloud-encryption-sec3cac31735/web
- *iCloud data security overview* (Jan 5 2026): https://support.apple.com/en-us/102651
- *Manage web access to your iCloud data* (Mar 24 2026): https://support.apple.com/en-us/102630
- *Encrypting user data* — "Use CloudKit Web Services" (read via the livingston/apple-docs mirror;
  developer.apple.com renders client-side):
  https://github.com/livingston/apple-docs/blob/main/documentation/CloudKit/encrypting-user-data.md
  (canonical: https://developer.apple.com/documentation/cloudkit/encrypting-user-data)
- CloudKit JS `setUpAuth` — offline copy `.claude/docs/cloudkitjs.md:6418` (live page and DocC JSON
  paths tried returned 404: `…/cloudkitjs/cloudkit/container/setupauth`,
  `…/tutorials/data/documentation/cloudkitjs/cloudkit/container/setupauth.json`)
- WWDC23 *What's new in privacy* (10053): https://developer.apple.com/videos/play/wwdc2023/10053/
- WWDC22 *What's new in CloudKit Console* (10115): https://developer.apple.com/videos/play/wwdc2022/10115/
- CKTool docs — offline copies `.claude/docs/cktool-full.md`, `.claude/docs/cktooljs-full.md`

Apple Developer Forums:

- 723945 — CloudKit JS issue with Advanced Data Protection (Jan 2023, no staff reply):
  https://developer.apple.com/forums/thread/723945
- 741011 — Advanced Data Protection and CloudKit Console (Nov 2023; Developer Tools Engineer reply):
  https://developer.apple.com/forums/thread/741011
- 844105 — CloudKit won't sign in for Private Database (2026): https://developer.apple.com/forums/thread/844105
- 833247 — Consistent login issues in CloudKit console "Act as iCloud Account" (Jun 2026):
  https://developer.apple.com/forums/thread/833247
- 101410 — "Authentication Error" (2018/2019, pre-ADP, same page text): https://developer.apple.com/forums/thread/101410
- 764076 — Issues with Apple Authentication in CloudKit JS (Sep 2024, DTS on token lifetime):
  https://developer.apple.com/forums/thread/764076
- 795097 — setUpAuth returns null (Jul 2025, DTS pointing at CloudKit Catalog):
  https://developer.apple.com/forums/thread/795097
- 772544 — keychain reset testing (Jan 2025, DTS relaying CloudKit team on ADP):
  https://developer.apple.com/forums/thread/772544
- 689463 — Frameworks Engineer on CKTool JS + encrypted fields (already cited in #392):
  https://developer.apple.com/forums/thread/689463

Community:

- icloud_photos_downloader #687 "[ADP] Is Advanced Data Protection Supported?":
  https://github.com/icloud-photos-downloader/icloud_photos_downloader/issues/687
- icloud_photos_downloader #1024 "private db access disabled for this account (probably ADP)":
  https://github.com/icloud-photos-downloader/icloud_photos_downloader/issues/1024
- docker-icloudpd #250: https://github.com/boredazfcuk/docker-icloudpd/issues/250
- steilerDev/icloud-photos-sync #202 "Advanced Data Protection Support" (PCS-cookie mechanics):
  https://github.com/steilerDev/icloud-photos-sync/issues/202
- Tact blog, *What Advanced Data Protection for iCloud means for Tact and other apps that use CloudKit*
  (Dec 14 2022; native-only, no web-services content): https://blog.justtact.com/advanced-data-protection/

Repo context: GitHub issue #392 comments (prior research and the B-scenario test protocol);
`Examples/MistDemo/Sources/MistDemoKit/Resources/js/auth.js` and `Resources/index.html` (the flow
under test: `CloudKit.configure` → `setUpAuth` → `whenUserSignsIn` → `_auth._ckSession`).

Unreachable this session: `sosumi.net` (DNS failure), the live `developer.apple.com/documentation/cloudkitjs` page for `setUpAuth` (404 on both paths tried; offline copy used instead), and `fatbobman.com`'s Act-As write-up (reachable but contains nothing on ADP).
