---
name: create-merge-request
description: Create a GitLab merge request for the current branch by generating a concise title and description from git commit messages and code diff. Squash merge and branch deletion are enabled by default.
argument-hint: ["[--target <branch>] [--draft]"]
---

# /create-merge-request

Analyze the current git branch and open a GitLab merge request with an auto-generated title and description. The description should be a bullet point list giving the reader a clear high-level understanding of what changed and why — without listing every single file or commit in detail.

## Options

- `$ARGUMENTS` may contain:
  - `--target <branch>` — Override the merge target branch (default: `main`)
  - `--draft` — Open the merge request as a draft (Work In Progress)

---

## Phase 0 — Pre-flight

1. **Verify required tools are available:**
   ```bash
   which git && which glab
   ```
   - If `git` is missing, report an error and STOP.
   - If `glab` is missing, report: _"The glab CLI is required. Install it via `brew install glab` or visit https://gitlab.com/gitlab-org/cli, then authenticate with `glab auth login`."_ and STOP.

2. **Verify glab is authenticated:**
   ```bash
   glab auth status
   ```
   If not authenticated, prompt the user to run `glab auth login` and STOP.

3. **Get the current branch name:**
   ```bash
   git rev-parse --abbrev-ref HEAD
   ```
   Store as `$CURRENT_BRANCH`. If the result is `HEAD` (detached HEAD state), report an error and STOP.

4. **Resolve the target branch:**
   - If `--target <branch>` is in `$ARGUMENTS`, use that value as `$TARGET_BRANCH`.
   - Otherwise, default to `main`. Store as `$TARGET_BRANCH`.

5. **Check if current branch has been pushed to remote:**
   ```bash
   git ls-remote --heads origin $CURRENT_BRANCH
   ```
   If the branch does not exist on remote, ask the user: _"Branch `$CURRENT_BRANCH` has not been pushed to remote yet. Push it now? (yes/no)"_
   - If yes: run `git push -u origin HEAD`
   - If no: STOP.

6. **Check that there are commits ahead of the target branch:**
   ```bash
   git log $TARGET_BRANCH..HEAD --oneline
   ```
   If this returns no output, report: _"No commits found ahead of `$TARGET_BRANCH`. Nothing to merge."_ and STOP.

---

## Phase 1 — Extract Context

1. **Collect commit messages:**
   ```bash
   git log $TARGET_BRANCH..HEAD --pretty=format:"%s%n%b"
   ```
   Store as `$COMMIT_MESSAGES`.

2. **Collect one-line commit list (for reference):**
   ```bash
   git log $TARGET_BRANCH..HEAD --oneline
   ```

3. **Collect the diff summary (file-level changes):**
   ```bash
   git diff $TARGET_BRANCH...HEAD --stat
   ```
   Store as `$DIFF_STAT`.

4. **Collect the actual diff for deeper context:**
   ```bash
   git diff $TARGET_BRANCH...HEAD
   ```
   Use this to understand the nature of the changes (e.g., refactor, bug fix, feature addition, CVE fix, config change). Do not include raw diff content in the MR description.

5. **Detect if this is a CVE-related change:**
   - Scan `$COMMIT_MESSAGES`, the branch name (`$CURRENT_BRANCH`), and the diff for CVE identifiers (pattern: `CVE-[0-9]{4}-[0-9]+`).
   - Store any found CVE identifiers as `$CVE_IDS` (e.g., `CVE-2024-12345`).
   - Also look for severity indicators near CVE mentions (e.g., `critical`, `high`, `medium`, `low`, `CVSS`) and store as `$CVE_SEVERITY` if found.

---

## Phase 2 — Generate Title and Description

Using `$COMMIT_MESSAGES`, `$DIFF_STAT`, and the actual diff content collected in Phase 1:

### Title

- Write a single short, imperative sentence (50 characters or fewer).
- Synthesize the overall intent of all commits — do not just copy a single commit message.
- If `$CVE_IDS` is non-empty, include the CVE identifier(s) in the title.

Examples:
```
Add user authentication
Fix payment timeout handling
Fix CVE-2024-12345: upgrade lodash to 4.17.21
```

### Description

- Write the description as a bullet point list summarizing what was done.
- Each bullet should describe a meaningful change or action taken, at a high level.
- Keep the total list to 3–6 bullets maximum.
- Focus on the high-level impact and motivation, not per-file or per-commit breakdowns.
- Do NOT include: raw diff output, file paths, every commit message verbatim, or low-level implementation details.

**If `$CVE_IDS` is non-empty**, prepend a CVE section before the bullet list:

```markdown
## Security

- **CVE:** <CVE ID(s)>
- **Severity:** <severity if detected, otherwise omit this line>
- **Summary:** <one sentence describing the vulnerability and how it is resolved>

## Changes

- <bullet>
- <bullet>
```

**If no CVE is detected**, use a plain bullet list with no section headers:

```markdown
- <bullet>
- <bullet>
- <bullet>
```

**Good description example (no CVE):**
```
- Introduces JWT-based authentication for the REST API
- Users can now register, log in, and receive a signed token
- Protected endpoints validate the token via a new middleware layer
- Public routes are unaffected by this change
```

**Good description example (CVE):**
```markdown
## Security

- **CVE:** CVE-2024-12345
- **Severity:** High
- **Summary:** Upgrades lodash to resolve a prototype pollution vulnerability that could allow remote code execution.

## Changes

- Upgrades lodash from 4.17.15 to 4.17.21
- Updates related unit tests to use the patched version
- Pins the dependency version in package.json to prevent regression
```

---

## Phase 3 — Create the Merge Request

1. Build the `glab` command using the generated title and description:
   ```bash
   glab mr create \
     --title "<generated title>" \
     --description "<generated description>" \
     --target-branch $TARGET_BRANCH \
     --squash-before-merge \
     --remove-source-branch \
     --no-editor
   ```

2. If `--draft` is in `$ARGUMENTS`, add the `--draft` flag to the command above.

3. Execute the command. If it fails, report the full error message to the user and STOP.

---

## Phase 4 — Confirm and Report

After successful creation, display:

```
✅ Merge request created successfully

Title:                  <generated title>
Source branch:          $CURRENT_BRANCH → Target: $TARGET_BRANCH
Squash on merge:        Enabled
Delete branch after merge: Enabled
URL:                    <merge request URL returned by glab>
```

---

## Error Handling

- If any `git` command fails (e.g., not inside a git repository), report the error clearly and STOP.
- If `glab mr create` fails due to an existing open MR for the branch, report the existing MR URL to the user and STOP.
- Never include secrets, tokens, or credentials in the MR title or description.
