<!-- d4a4d01e-05bb-4d19-863d-6ffff97848a7 55d1912a-7e22-4bf2-a691-214ee21346bc -->
# Firefox 135 → 142 Upgrade Plan

## Why

Firefox 135 is 7 months old and getting flagged by bot detection. Playwright 1.56 supports Firefox 142.0.1.



Camoufox is a derivitive of firefox for stealth.  Its maintainer is hospitalized and now I get to update this shit for Blue Taka.  Unfortuantely I've never done this so.... good luck.  

## Target Builds

- Linux x86_64 & arm64
- macOS x86_64 & arm64

## The Process (Per Official Docs)

### 1. Update Version

Edit `upstream.sh`:

```bash
version=142.0.1
release=bluetaka.25
```

### 2. Fix Patches Until `make dir` Works

```bash
make dir
```

**Current status:** Failed with 2 patch rejects:

- `browser/installer/package-manifest.in.rej`
- `docshell/base/BrowsingContext.h.rej`

Fix these `.rej` files by examining them and updating the playwright patch, then retry `make dir`.

**Iterative loop:**

- Fix `.rej` files → Update patch → `make dir` again
- Repeat until no failures

### 3. Bootstrap (One-time)

```bash
make bootstrap
```

Sets up build environment. Only needed once.

### 4. Build & Package All Targets

```bash
python3 multibuild.py --target linux macos --arch x86_64 arm64
```

Builds and packages all 4 variants.

**If build fails:** Fix compilation errors, update patches, rebuild.

### 5. Test

- Run browser: `make run`
- Run tests: `make tests`
- Manual testing on bot detection sites

## Current State

You've already updated `upstream.sh` and ran `make dir`. It failed on playwright patches. Next step: fix the 2 rejects.

## How I Can Help

- Read `.rej` files and suggest fixes
- Search Firefox source for API changes
- Update patch files
- Debug build errors
- Anything non-GUI

## What You Need to Do

- GUI tool (`make edits`) if needed
- Manual browser testing at the end
- Final validation

## Resources

- Playwright patches: https://github.com/microsoft/playwright/tree/release-1.56/browser_patches/firefox
- Firefox docs: https://firefox-source-docs.mozilla.org/
- Build docs: https://camoufox.com/development/buildcli/

### To-dos

- [ ] Update version in upstream.sh from 135.0.1 to 142.0.1 and release to bluetaka.25
- [ ] Download Firefox 142 bootstrap.diff from Playwright 1.56 and replace patches/playwright/0-playwright.patch
- [ ] Run make fetch to download Firefox 142.0.1 source tarball
- [ ] Run make setup to extract and initialize camoufox-142.0.1-bluetaka.25 directory
- [ ] Apply patches using patch.py and report which ones fail
- [ ] Run make build and fix any compilation errors that occur
- [ ] Run make run to test basic browser functionality
- [ ] Run make tests to validate stealth features
- [ ] Run multibuild.py for linux & macos with x86_64 & arm64