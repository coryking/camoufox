# Firefox 142 Upgrade Notes

## Current Status

✅ **Fixed Patches:**
- `patches/playwright/0-playwright.patch` - Playwright base integration (applied cleanly)
- `patches/playwright/1-leak-fixes.patch` - Stealth fixes (fixed manually, navigator.webdriver + enterprise policies)
- `patches/ghostery/Disable-Onboarding-Messages.patch` - Applied with offset
- `patches/all-addons-private-mode.patch` - Applied with fuzz
- `patches/anti-font-fingerprinting.patch` - Applied with offset
- `patches/audio-context-spoofing.patch` - **FIXED** - Updated for new SPHINX_TREES line in dom/media/moz.build

✅ **Removed/Obsolete Patches:**
- `patches/librewolf/sed-patches/allow-searchengines-non-esr.patch` - **DELETED** - Firefox 142 natively supports SearchEngines in non-ESR builds (Bug 1961839, April 2025)

❌ **Remaining Patches (need testing):**
- All other Camoufox patches (41 remaining - testing in progress)

**Next Step:** Continue testing remaining patches with `make dir`.

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

## Understanding the Dual-Repo Structure

**Camoufox uses TWO git repositories:**

1. **Camoufox Project Repo** (outer repo at `/home/azureuser/camoufox/`)
   - Contains: patches, scripts, Makefile, documentation
   - `.git/` tracks: patch files, build scripts, configuration
   - **Commit patch changes here** after fixing them

2. **Firefox Source Repo** (inner repo at `camoufox-142.0.1-bluetaka.25/`)
   - Contains: Firefox source code
   - `.git/` tracks: Firefox code + Camoufox additions
   - Used for: generating patches via `git diff`, reverting with `make revert`

**Key workflow:**
- Fix broken Firefox files → `cd camoufox-142.0.1-bluetaka.25 && git diff > ../patches/foo.patch`
- Commit the patch file → `cd .. && git add patches/foo.patch && git commit`

## Incremental Patch Workflow (For Upgrades)

When upgrading Firefox versions, patches often fail. Here's the workflow to fix them incrementally:

### 1. Apply Patches One-by-One Until Failure

```bash
make revert  # Start fresh

# Apply patches manually until one fails
make patch ./patches/playwright/0-playwright.patch
make patch ./patches/playwright/1-leak-fixes.patch  # <-- This one failed!
```

### 2. Checkpoint Working Patches

After applying all the **working** patches, create a tagged checkpoint:

```bash
# Only apply the patches that worked
make revert
make patch ./patches/playwright/0-playwright.patch
make patch ./patches/playwright/1-leak-fixes.patch
make patch ./patches/ghostery/Disable-Onboarding-Messages.patch
make patch ./patches/all-addons-private-mode.patch
make tagged-checkpoint  # Save this state with a reusable tag
```

Now you can return to this point anytime with:
```bash
make revert-checkpoint
```

### 3. Fix the Broken Patch

**IMPORTANT: Always review the patch first!**

```bash
# Step 1: Review what the patch is supposed to do
[view] patches/path/to/broken-patch.patch
# - Count the hunks (look for @@ markers)
# - Note which files it modifies
# - Understand what changes it makes

# Step 2: Manually apply the intended changes to the source files
[edit] camoufox-142.0.1-bluetaka.25/path/to/broken/file.cpp

# Step 3: Generate new patch from your changes
cd camoufox-142.0.1-bluetaka.25
git diff > ../patches/path/to/broken-patch.patch

# Step 4: VERIFY the regenerated patch
cd ..
git diff patches/path/to/broken-patch.patch
# Should show:
# ✅ Line number changes (expected - Firefox code evolved)
# ✅ Context changes (expected - surrounding code changed)
# ❌ Missing hunks (BAD - you missed something!)
# ❌ Missing files (BAD - patch didn't fully apply!)
```

### 4. Test the Fixed Patch

```bash
# Return to the tagged checkpoint
make revert-checkpoint

# Now test your fixed patch
make patch ./patches/librewolf/sed-patches/allow-searchengines-non-esr.patch  # Should work now!
```

### 5. Continue Until `make dir` Works

Repeat steps 1-4 for each failing patch until `make dir` completes successfully.

### 6. When Deleting Obsolete Patches

If a patch is obsolete (Firefox now has the feature natively):

```bash
# VERIFY what the patch does before deleting
cat patches/path/to/patch.patch  # Review all hunks!

# Check Firefox changelog/bugs to confirm it's truly obsolete
# Example: Bug 1961839 added SearchEngines support natively

# Delete the patch
rm patches/path/to/patch.patch

# Commit the deletion with explanation
git add patches/path/to/patch.patch
git commit -m "Remove obsolete patch - Firefox now has this natively (Bug XXXXX)"
```

## Key Makefile Commands

- **`make revert`**: Reset to `unpatched` tag (vanilla Firefox + Camoufox additions)
  ```bash
  cd $(cf_source_dir) && git reset --hard unpatched
  ```

- **`make checkpoint`**: Commit current state (creates a git commit)
  ```bash
  cd $(cf_source_dir) && git commit -m "Checkpoint" -a -uno
  ```

- **`make tagged-checkpoint`**: Commit AND tag as `checkpoint` (reusable savepoint!)
  ```bash
  cd $(cf_source_dir) && git commit -m "Checkpoint" -a -uno && git tag -f checkpoint
  ```

- **`make revert-checkpoint`**: Reset to `checkpoint` tag (return to saved checkpoint)
  ```bash
  cd $(cf_source_dir) && git reset --hard checkpoint
  ```

- **`make patch <file>`**: Apply a single patch file
- **`make dir`**: Apply ALL patches (main command for building)
- **`make diff`**: Show current changes (`git diff`)

## Example: Fixing the audio-context-spoofing Patch

```bash
# 1. Apply working patches and create tagged checkpoint
make revert
make patch ./patches/playwright/0-playwright.patch
make patch ./patches/playwright/1-leak-fixes.patch
# ... apply more working patches ...
make tagged-checkpoint  # Creates 'checkpoint' tag

# 2. Review the broken patch
less patches/audio-context-spoofing.patch
# Found: 4 files, 1 hunk failed (dom/media/moz.build)

# 3. Try to apply it (will partially succeed)
make revert-checkpoint
cd camoufox-142.0.1-bluetaka.25
patch -p1 -i ../patches/audio-context-spoofing.patch
# 3 files succeed, 1 fails → Check .rej file to understand failure

# 4. Manually fix the failed file
vim dom/media/moz.build  # Add the LOCAL_INCLUDES line

# 5. Generate new patch
git diff > ../patches/audio-context-spoofing.patch

# 6. VERIFY the patch (back in project repo)
cd ..
git diff patches/audio-context-spoofing.patch
# ✅ All 4 files present, just line numbers changed

# 7. Test the fixed patch
make revert-checkpoint
make patch ./patches/audio-context-spoofing.patch  # ✅ Works!

# 8. Update checkpoint and commit
make tagged-checkpoint
git add patches/audio-context-spoofing.patch
git commit -m "Fix audio-context-spoofing patch for Firefox 142"
```

## Related Issues

- GitHub issue #230: Playwright 1.51 breaks with "method 'Browser.setContrast' is not supported"
- This is why the previous maintainer merged Playwright patches in March 2025

