# Firefox 142 Upgrade Notes

## Current Status

✅ **Fixed Patches:**
- `patches/playwright/0-playwright.patch` - Playwright base integration (applied cleanly)
- `patches/playwright/1-leak-fixes.patch` - Stealth fixes (fixed manually, navigator.webdriver + enterprise policies)
- `patches/ghostery/Disable-Onboarding-Messages.patch` - Applied with offset
- `patches/all-addons-private-mode.patch` - Applied with fuzz

✅ **Removed/Obsolete Patches:**
- `patches/librewolf/sed-patches/allow-searchengines-non-esr.patch` - **DELETED** - Firefox 142 natively supports SearchEngines in non-ESR builds (Bug 1961839, April 2025)

❌ **Remaining Patches (need testing):**
- All other Camoufox patches (testing in progress)

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

Now manually fix the broken file and generate a new patch:

```bash
# Edit the source files to make the changes the patch intended
vim camoufox-142.0.1-bluetaka.25/path/to/broken/file.cpp

# Generate new patch from your changes
cd camoufox-142.0.1-bluetaka.25
git diff > ../patches/path/to/broken-patch.patch
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

## Example: Fixing the leak-fixes Patch

```bash
# 1. Apply working patches and create tagged checkpoint
make revert
make patch ./patches/playwright/0-playwright.patch
make tagged-checkpoint  # Creates 'checkpoint' tag

# 2. Make manual fixes to files
vim camoufox-142.0.1-bluetaka.25/dom/base/Navigator.cpp
vim camoufox-142.0.1-bluetaka.25/toolkit/components/enterprisepolicies/EnterprisePoliciesParent.sys.mjs

# 3. Generate new patch
cd camoufox-142.0.1-bluetaka.25
git diff > ../patches/playwright/1-leak-fixes.patch

# 4. Test it - return to checkpoint and try the new patch
cd ..
make revert-checkpoint
make patch ./patches/playwright/1-leak-fixes.patch  # ✅ Works!

# 5. If it works, update the checkpoint to include this patch
make tagged-checkpoint  # Update 'checkpoint' tag to include new patch
```

## Related Issues

- GitHub issue #230: Playwright 1.51 breaks with "method 'Browser.setContrast' is not supported"
- This is why the previous maintainer merged Playwright patches in March 2025

