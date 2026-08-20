---
name: feedback-no-silent-policy-defaults
description: "For parameters that encode a meaningful policy choice (e.g., signing method, auth attribution), don't add a defaulted value — make every caller explicit. If source compat ever requires it, prefer a @available(*, deprecated) overload over a silent default."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 02af7a13-9761-4a46-8438-d95718085ac1
---

When a parameter encodes a meaningful policy choice — which credential to sign with, which attribution to use, which side-effect to fire — **do not give it a defaulted value**. Make every caller pass the value explicitly. Verbosity at the call site is acceptable; silent policy is not.

**Why:** The whole motivation for issue #338's `PublicAuthPreference` was that the dispatcher's *implicit* "S2S wins when present" rule silently mis-attributed records. Re-introducing a default like `auth: PublicAuthPreference = .prefers(.serverToServer)` would visibly type-encode the same policy but functionally repeat the silent-default problem. Per the user: "I think we should not have PublicAuthPreference defaults or if we need them make them deprecated."

**How to apply:**
- In MistKit (this codebase), `PublicAuthPreference` parameters MUST be non-defaulted at every call site (public ops, internal funnel `client(for:auth:)`, dispatcher `makeTokenManager(for:auth:)`).
- More broadly: if you're adding a parameter that the dispatcher's behavior visibly depends on, don't default it. Make the caller think about it.
- If you must keep an old call signature working for source-compat reasons, ship a `@available(*, deprecated, message: "pass `auth:` explicitly")` overload that forwards to the explicit form — don't add the default to the new method.
- Pre-1.0 (v1.0.0-beta.X) is breaking-change-friendly; usually you don't even need the deprecated overload — just update call sites in the same PR.

Related: [[feedback-explicit-import-access]] (similar theme — explicit > implicit at the source level).
