---
name: Capture follow-up findings in issues, not code
description: When verification surfaces a fix or improvement outside the current task's scope, default to writing it up in the relevant GitHub issue rather than implementing
type: feedback
originSessionId: e3d4831a-ab91-4deb-96ac-dbf3b9ff1412
---
When investigation during one task surfaces a fix or improvement that lives outside the task's approved scope (e.g. a library-level API improvement discovered while working on a docs/test refactor), the user prefers to capture the finding in the relevant GitHub issue and stop, rather than expanding the current PR to implement it.

**Why:** Twice in the same session — first when I tried to delete `DiscoverUserIdentitiesPhase.swift`, then when I started editing `CloudKitService+Initialization.swift` to add `database:` overrides — the user interrupted and redirected me to "add details to the issue" / "just edit the github issue with details." They want the current PR scope kept tight; library API changes get their own issue/PR.

**How to apply:** When the user says something like "we should also …" about something outside the current task, treat it as "capture this in the tracker," not "implement it now." Write a clear comment on the existing issue (or open a new one) with: what's true today (file/line citations), the proposed change, and why it's separable from current work. Don't start editing source files unless the user explicitly says "go implement it" or "do it now."
