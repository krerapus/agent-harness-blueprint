Create a pull request for the current branch on **this blueprint package** (GitHub — use `gh`, not `glab`).

This playbook is for package contributors only. It is unrelated to consumer/target GitLab overlays.

**One-time auth:** `blueprint auth login github` then `blueprint auth status` (tokens stay in `gh`).

---

1. Write a clear title:
   - Format: `type(scope): description`
   - Types: feat|fix|refactor|test|docs|chore
   - Keep under 72 chars
   - **No JIRA number**

2. Generate the PR body using this template (fill every relevant section):

```markdown
## Summary

<!-- Why this change exists (1–3 bullets). -->

-

## Release notes

<!-- Short Keep a Changelog bullets for CHANGELOG.md [Unreleased]. -->
<!-- Prefer outcome/intent. Do not list filenames. -->

-

## Type of change

- [ ] Bug fix
- [ ] New feature / enhancement
- [ ] Documentation
- [ ] Chore / refactor (no behavior change)

## Test plan

- [ ] `./tests/cli/smoke.sh`
- [ ] `./tests/cli/harness.sh` (if harness/CLI ownership touched)
- [ ] `./blueprint doctor`
- [ ] Manual check on a throwaway `--target` (if install/sync/del changed)
- [ ] `./blueprint install-contributor` checked (if contributor harness touched)

## Notes for reviewers

<!-- Breaking changes, follow-ups, or screenshots. -->
```

**Release notes** rules:
- Maximum **1–3 short bullets**
- Suitable to paste under `CHANGELOG.md` → `## [Unreleased]` (Added / Changed / Fixed as appropriate)
- Prefer outcome/intent over file lists
- **Do not** include filenames
- After drafting release notes, apply the `update-changelog` skill so `CHANGELOG.md` `[Unreleased]` matches (required for agent-harness / assets / homebrew package repos)

3. Push branch if needed:
   ```bash
   git push -u origin HEAD
   ```

4. Check for an existing open PR on this branch:
   ```bash
   gh pr view --json url,state 2>/dev/null || true
   ```
   If one exists and is open, return its URL and stop.

5. Create the PR:
   ```bash
   gh pr create \
     --title "type(scope): description" \
     --body "$(cat <<'EOF'
   ## Summary

   - <outcome line 1>
   - <outcome line 2 if needed>

   ## Release notes

   - <changelog-ready bullet>

   ## Type of change

   - [ ] Bug fix
   - [ ] New feature / enhancement
   - [ ] Documentation
   - [ ] Chore / refactor (no behavior change)

   ## Test plan

   - [ ] `./tests/cli/smoke.sh`
   - [ ] `./tests/cli/harness.sh` (if harness/CLI ownership touched)
   - [ ] `./blueprint doctor`
   - [ ] Manual check on a throwaway `--target` (if install/sync/del changed)

   ## Notes for reviewers

   EOF
   )" \
     --label "ai-generated"
   ```

6. Return the PR URL.

## Rules

- Never target `main` or `master` as the source branch for direct pushes; open a PR instead
- Default target branch is the repository default (usually `main`)
- PR title: `type(scope): description` (no JIRA)
- Label `ai-generated` on AI-created PRs
- Do not create a duplicate if an open PR already exists for the branch
- Release notes: max 1–3 lines; never list filenames
