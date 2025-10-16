<!-- 30d27bec-06eb-4f2d-a575-986b17e35df5 7fc6a04e-481b-462d-8dd1-843cad29f63e -->
# Firefox 135 → 142 Upgrade: Bump and Fix Approach

## Reality Check

- **Firefox 135 is 7+ months old** - Released January 2025, now obsolete
- **Bot detection has caught up** - Old browser = easy to fingerprint
- **Playwright 1.56 supports Firefox 142.0.1** ✅ 
- **Target: macOS and Linux only** (4 builds instead of 7)

## The Strategy: Bump → Break → Fix → Repeat

Forget analysis paralysis. Here's the real plan:

### 1. Update Version Numbers

**Do this:**

```bash
# In upstream.sh
version=135.0.1  →  version=142.0.1

# In pythonlib/camoufox/__version__.py (if releasing Python package)
MIN_VERSION = 'beta.19'  →  MIN_VERSION = 'beta.25' (or whatever)
```

### 2. Fetch Firefox 142

```bash
make fetch
# Downloads firefox-142.0.1.source.tar.xz from archive.mozilla.org
```

### 3. Setup Source Directory

```bash
make setup
# Creates camoufox-142.0.1-beta.24/ and initializes git repo
```

### 4. Get Playwright's Firefox 142 Patches

**Critical:** Download from https://github.com/microsoft/playwright/blob/release-1.56/browser_patches/firefox/patches/bootstrap.diff

Replace `patches/playwright/0-playwright.patch` with this file.

### 5. Apply Patches and Fix Breaks

Use the **developer UI** per [Camoufox docs](https://camoufox.com/development/):

```bash
make edits
```

This gives you an interactive patch manager. Or manually:

```bash
# Apply patches one by one
python3 scripts/patch.py 142.0.1 beta.24

# When patches fail, you'll see:
# "error: patch failed: path/to/file.cpp:123"
# "error: path/to/file.cpp: patch does not apply"
```

**For each failure:**

a) **Check if it's just line offsets** (code moved, not changed):

   - Patch tool often auto-fixes these
   - If not, manually adjust line numbers in .patch file

b) **Check if code changed** (API refactored):

   - Use `make edits` → "Edit a patch"
   - Make changes in `camoufox-142.0.1-beta.24/`
   - Use `make diff` to see what changed
   - Update the patch file with your fixes

c) **Check if API was removed** (Mozilla deprecated something):

   - Search Firefox 142 source for equivalent
   - Rewrite patch logic
   - May need to consult Firefox docs or Mozilla bugs

### 6. Build and Fix Compilation Errors

```bash
make build
```

**Common breaks:**

- Missing header files → Update includes
- Deprecated functions → Find Firefox 142 equivalents
- Changed function signatures → Update calls
- Removed APIs → Find new implementation

**Use Firefox docs:** https://firefox-source-docs.mozilla.org/

### 7. Test Basic Functionality

```bash
make run
# Opens browser - does it launch?
# Can you navigate to google.com?
# Does it crash immediately?
```

### 8. Run Playwright Tests

```bash
make tests
# 77+ tests in tests/async/
# Fix failures one by one
```

### 9. Validate Stealth Features

Manual testing on these sites:

- https://abrahamjuliot.github.io/creepjs/ (aim for 71.5%+)
- https://www.browserscan.net/ (aim for 100%)
- https://nopecha.com/demo/turnstile (should pass)
- https://recaptcha-demo.appspot.com/ (aim for 0.9 score)

**If failing:** Your fingerprint patches broke. Use the leak debugging workflow from [Camoufox docs](https://camoufox.com/development/).

### 10. Build for All Platforms

```bash
python3 multibuild.py --target linux macos --arch x86_64 arm64
```

Test each build minimally.

## Key Tools from Camoufox Docs

Per https://camoufox.com/development/:

**Developer UI** (`make edits`):

- Interactive patch management
- Apply/unapply patches
- Edit patches in place
- See which patches are applied

**Leak Debugging Workflow**:

- Process to find what broke stealth features
- Bisect patches to identify culprits
- Compare headless vs headful
- Test with/without fingerprint resistance

**Other useful commands:**

```bash
make workspace ./patches/file.patch  # Set workspace to specific patch
make patch ./patches/file.patch      # Apply a patch
make unpatch ./patches/file.patch    # Remove a patch
make checkpoint                      # Git commit current state
make revert                          # Reset to unpatched state
make diff                            # See current changes
make edit-cfg                        # Edit camoufox.cfg
```

## Patch Priority Order

**Start with what's least likely to break:**

1. **Playwright patches** (use Microsoft's work)

   - `patches/playwright/0-playwright.patch` → replace with Playwright 1.56 version
   - `patches/playwright/1-leak-fixes.patch` → may need minor adjustments

2. **Config/behavioral patches** (usually stable)

   - `patches/config.patch`
   - `patches/no-css-animations.patch`
   - `patches/no-search-engines.patch`
   - LibreWolf debloat patches

3. **Medium-risk fingerprint patches**

   - Font patches
   - Screen patches
   - Locale/timezone/geolocation

4. **High-risk patches last** (most likely to break)

   - `patches/fingerprint-injection.patch`
   - `patches/webgl-spoofing.patch`
   - `patches/audio-context-spoofing.patch`
   - `patches/webrtc-ip-spoofing.patch`

**Why this order?** If high-risk patches break early, you'll waste time. Get the easy wins first, build momentum, tackle hard stuff when you have a working base.

## When Things Break

**Build errors:**

- Read the error message
- Google the error + "firefox 142"
- Check Mozilla's source docs
- Look at Firefox's own commits between 135→142

**Runtime crashes:**

- Run with `make run args="..."` 
- Check console output
- Use Firefox's built-in debugger
- Bisect patches to find the culprit

**Silent stealth failures** (worst kind):

- Use the leak debugging workflow
- Compare Firefox 135 vs 142 behavior
- Check if bot detection sites flag you
- May need to deobfuscate WAF JavaScript (hard)

## Resources

- **Playwright patches**: https://github.com/microsoft/playwright/tree/release-1.56/browser_patches/firefox
- **Firefox source docs**: https://firefox-source-docs.mozilla.org/
- **Mozilla bug tracker**: https://bugzilla.mozilla.org/
- **Camoufox dev docs**: https://camoufox.com/development/
- **Developer UI**: `make edits`
- **This repo's README**: Leak debugging flowchart

## Bottom Line

1. **Bump the version** → `upstream.sh`
2. **Download Firefox 142** → `make fetch`
3. **Try to patch** → `python3 scripts/patch.py`
4. **Fix what breaks** → Use `make edits` and manual fixes
5. **Build** → `make build`
6. **Test** → `make run`, `make tests`, manual validation
7. **Iterate** → Repeat steps 4-6 until working

**No complex planning. Just fix breaks as they come.**

The build system and developer tools are designed for this workflow. Use them.

### To-dos

- [ ] Verify if Playwright officially supports Firefox 144 by checking their browser_patches directory
- [ ] Review Firefox release notes for versions 136-144 to identify breaking API changes
- [ ] Create backup of current working patches directory before attempting upgrade
- [ ] Update version in upstream.sh and Python library version constraints
- [ ] Download Firefox 144 source tarball using make fetch
- [ ] Update Playwright patches to match Firefox 144 (0-playwright.patch and 1-leak-fixes.patch)
- [ ] Fix conflicts in ~20 fingerprint spoofing patches
- [ ] Fix conflicts in LibreWolf and Ghostery debloat patches
- [ ] Attempt first build for local platform and resolve build errors
- [ ] Test basic browser functionality and run Playwright test suite
- [ ] Validate stealth features on WAF test sites (CreepJS, BrowserScan, Cloudflare, etc.)
- [ ] Build and test for all target platforms (Linux/Windows/macOS, x86_64/arm64/i686)