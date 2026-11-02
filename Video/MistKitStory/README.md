# The Story of MistKit — YouTube Video

Working folder for a YouTube video based on the talk **"CloudKit as Your Backend: From iOS to Server-Side Swift"** (Swift Craft and iOSDevUK 2026): the story of MistKit and CloudKit Web Services.

Only text sources (outline, script, shot list, motion specs, metadata) live in git. Raw footage, audio, renders and NLE caches are ignored — see [`.gitignore`](.gitignore).

## Branch model

| Branch | Role |
|--------|------|
| `video/mistkit-story` | Base branch for the video project. Each phase branches from here and merges back. |
| `video/mistkit-story-NN-<phase>` | One branch per phase, e.g. `video/mistkit-story-01-scaffolding`, `video/mistkit-story-02-outline`. |

Phase branches use a `-NN-<phase>` suffix rather than `video/mistkit-story/<phase>` because Git can't hold a ref and a sub-ref with the same prefix.

## Workflow

1. **Sources** — gather the article, slides, recording and transcript → [`sources/`](sources/)
2. **Outline** — chapter structure with source references → [`outline/outline.md`](outline/outline.md)
3. **Script** — one file per chapter, VO | Visual → [`script/`](script/)
4. **Shots** — shot list and B-roll captures → [`shots/`](shots/)
5. **Motion** — diagram/animation specs (and project files) → [`motion/`](motion/)
6. **Edit** — done outside git
7. **Publish** — thumbnail, title, description, chapters → [`thumbnails/`](thumbnails/), [`youtube/`](youtube/)

## Folder map

```
Video/MistKitStory/
├── sources/      pointers to source material; transcript/ drop spot
├── outline/      chapter skeleton
├── script/       per-chapter script files
├── shots/        shot list, B-roll ideas
├── motion/       motion-graphics specs (specs/) and project files (project/)
├── thumbnails/   thumbnail brief
└── youtube/      metadata and chapter markers
```

## Conventions

- Chapter IDs are two-digit and shared across outline, script and shots: `00`, `01`, …
- Shot IDs: `<chapter>-<nn>`, e.g. `03-04`.
- Motion spec IDs: `M-<slug>`, e.g. `M-three-layers`.
- Status values: `todo` · `draft` · `review` · `final`.
