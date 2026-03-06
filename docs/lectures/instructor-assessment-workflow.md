# Instructor Assessment Workflow (Private Artifacts)

This repository is student-facing.
Homework tasks and Moodle concept tests should not be committed here.

## Recommended Storage Model

Use a separate private repository for:

1. Homework briefs and rubrics
2. Moodle question banks (`.gift`)
3. Answer keys

## When to Extract Assessment Files

Use this timing rule:

1. Generate draft questions/tasks while working on lecture materials.
2. Move/copy them to the private repo immediately after draft creation.
3. Before every commit in this repo, verify no assessment files are staged.

Do not wait until the end of the day to move them.

## Safe Working Pattern

### Option A (best): generate directly in private repo

1. Keep this repo open for context/reference.
2. Create assessments in another editor window rooted at the private repo.

### Option B: temporary local drafts in this working tree

1. Place drafts only under `.instructor-private/` in this repository.
2. Copy to private repo when draft is ready.
3. Remove local draft copies if no longer needed.

Example copy command:

```bash
cp .instructor-private/lecture-01-concepts.gift /path/to/private-repo/assessments/
cp .instructor-private/lecture-01-homework.md /path/to/private-repo/homework/
```

## Pre-Commit Safety Check

Run this before each commit:

```bash
git status --short
```

Expected:

1. Only student-facing docs/code are listed.
2. No homework/test artifacts appear.

If unsafe files are staged:

```bash
git restore --staged <path>
```

Then move them to the private repository.

