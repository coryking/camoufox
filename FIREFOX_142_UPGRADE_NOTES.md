# Firefox 142 Upgrade Notes

## The Problem

Playwright's `bootstrap.diff` patch for Firefox 142.0.1 is designed for a specific git commit from the Firefox GitHub mirror, **NOT** Mozilla's official release tarball.

- **Mozilla's tarball**: `https://archive.mozilla.org/pub/firefox/releases/142.0.1/source/firefox-142.0.1.source.tar.xz`
- **Playwright's source**: GitHub mirror commit `361373160356d92cb5cd4d67783a3806c776ee78`

Even though both are "Firefox 142.0.1", they're slightly different, causing **88 reject files** when applying Playwright's patch to Mozilla's tarball.

## The Solution

**Use Playwright's exact Firefox source** instead of Mozilla's tarball.

### What We Did

1. **Cloned Playwright's exact Firefox commit:**
   ```bash
   git clone --filter=blob:none --no-checkout git@github.com:mozilla-firefox/firefox.git camoufox-142.0.1-bluetaka.25
   cd camoufox-142.0.1-bluetaka.25
   git checkout 361373160356d92cb5cd4d67783a3806c776ee78
   ```

2. **Created the `unpatched` tag** (for `make revert`):
   ```bash
   git tag -a unpatched -m "Initial commit"
   ```

3. **Copied Camoufox additions** (spices & herbs):
   ```bash
   bash ../scripts/copy-additions.sh 142.0.1 bluetaka.25
   ```

4. **Committed additions and updated tag:**
   ```bash
   git add -A
   git commit -m "Add Camoufox additions"
   git tag -f -a unpatched -m "Initial commit with additions"
   ```

5. **Applied patches:**
   ```bash
   make dir  # Should now work cleanly with Playwright's patch
   ```

## Why This Works

- Playwright's `bootstrap.diff` expects specific line numbers and code structure from their exact commit
- By using the same source Playwright uses, the patch applies cleanly (no rejects)
- The other Camoufox patches (fingerprinting, spoofing, etc.) still apply fine since they target Firefox APIs, not specific line numbers

## The Trade-off

**Normal approach (what Camoufox used before):**
- Download Mozilla's official tarball
- Manually fix patch conflicts when upgrading
- More work, but using "official" Firefox releases

**Our approach (what we're doing now):**
- Use Playwright's git commit
- Patches apply cleanly
- Less work, but using GitHub mirror instead of Mozilla's official source

## Finding the Right Commit

For future upgrades, find Playwright's Firefox commit:

1. Check Playwright's `UPSTREAM_CONFIG.sh`:
   ```bash
   curl -s https://raw.githubusercontent.com/microsoft/playwright/release-1.XX/browser_patches/firefox/UPSTREAM_CONFIG.sh
   ```

2. Look for `BASE_REVISION`:
   ```
   REMOTE_URL="https://github.com/mozilla-firefox/firefox"
   BASE_BRANCH="release"
   BASE_REVISION="<COMMIT_HASH_HERE>"
   ```

3. Use that commit hash when cloning.

## Backup Plan

If this approach causes issues, we still have:
- **Backup directory**: `camoufox-142.0.1-bluetaka.25.bak` (Mozilla tarball source)
- **Downloaded tarball**: `firefox-142.0.1-playwright.tar.gz` (Playwright's commit as tarball)
- Can go back to manual patch fixing if needed

## Git Workflow & Checkpoints

The Camoufox build system uses git to track changes during development:

### Key Commands

- **`make revert`**: Resets to the `unpatched` tag (vanilla Firefox + Camoufox additions, before any patches)
  ```bash
  cd $(cf_source_dir) && git reset --hard unpatched
  ```

- **`make checkpoint`**: Creates a commit to save your current state
  ```bash
  cd $(cf_source_dir) && git commit -m "Checkpoint" -a -uno
  ```

- **`make tagged-checkpoint`**: Creates a checkpoint AND tags it for easy return
  ```bash
  cd $(cf_source_dir) && git commit -m "Checkpoint" -a -uno && git tag -f checkpoint
  ```

### Returning to Checkpoints

Since regular checkpoints are just commits (not tags), you need to use git commands:

```bash
# Go back to the most recent checkpoint
cd camoufox-142.0.1-bluetaka.25 && git reset --hard HEAD~1

# Find a specific checkpoint
cd camoufox-142.0.1-bluetaka.25 && git log --oneline
git reset --hard <commit-hash>

# Return to a tagged checkpoint (if you used make tagged-checkpoint)
cd camoufox-142.0.1-bluetaka.25 && git reset --hard checkpoint
```

## Related Issues

- GitHub issue #230: Playwright 1.51 breaks with "method 'Browser.setContrast' is not supported"
- This is why the previous maintainer merged Playwright patches in March 2025

