# RetryPolicy deliberately removed

MistKit previously had a client-side `RetryPolicy` (retry-with-jitter). It was **deliberately removed** along the #148 lineage — do not reintroduce it.

Rate-limit honoring (backing off when CloudKit signals limits) is fine. Automatic client retries / jittered retry policies are not.

Zero `RetryPolicy` references remain in `Sources/MistKit` by design. A future agent could easily re-add retries as "hardening"; treat that as a regression unless the human explicitly reverses this decision.
