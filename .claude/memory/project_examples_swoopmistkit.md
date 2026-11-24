---
name: project_examples_swoopmistkit
description: "On 2026-11-24 Examples/BushelCloud became Examples/SwoopMistKit (repo renamed) and Examples/CelestraCloud was removed from MistKit"
metadata:
  type: project
---

On 2026-11-24 (PR #511) the BushelCloud example moved to `Examples/SwoopMistKit/`: GitHub's `brightdigit/BushelCloud` was renamed `brightdigit/SwoopMistKit`, and the subrepo's `.gitrepo` remote now points there (branch `mistkit`). The code inside is unchanged and still the `BushelCloud` package (`BushelCloudKit`, `bushel-cloud`, workflow file `BushelCloud.yml`). `Examples/CelestraCloud/` was removed from MistKit at the same time; CelestraCloud lives on only as its standalone repo (`brightdigit/CelestraCloud`, branch `mistkit`).

**Why:** Leo asked to drop CelestraCloud from the examples and to use the renamed SwoopMistKit repo instead of BushelCloud.
**How to apply:** Paths, CI (`examples.yml`, `Scripts/release.sh` PIN_FILES, `Scripts/update-subrepo.sh`) and `git subrepo push` target `Examples/SwoopMistKit`. Don't rename the package or its targets from MistKit; that's the subrepo's own content ([[feedback_subrepo_fixes_belong_in_subrepo]]). Talk and deployment prose about the Bushel and Celestra apps stays; only links and paths changed. Older memory notes that mention `Examples/BushelCloud` or `Examples/CelestraCloud` describe history before this date ([[project_examples_dir_is_for_mistkit_dev]]).
