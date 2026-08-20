---
name: skip-history-on-repo-extraction
description: "When extracting code from MistKit to a new subrepo, do a clean copy — don't bother with git subtree split / filter-repo to preserve history"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d1a72739-76ad-474a-b439-878e9f9f41e3
---

When extracting a module from MistKit (or its Examples/) into its own subrepo, do a clean copy of the files. Do **not** propose `git subtree split` / `git filter-repo` to preserve history.

**Why:** Leo explicitly said "we don't want any history really" for the ConfigKeyKit extraction (issue #267). The extra ceremony of preserving history isn't worth it for these splits.

**How to apply:** In migration plans for code being lifted out to a new repo, omit the history-preservation step entirely. Just copy, commit fresh in the new repo, tag an initial version. Save the planning effort for the parts that matter (API surface, public access, CI scaffolding, consumer rewiring).
