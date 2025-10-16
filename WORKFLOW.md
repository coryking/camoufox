# Overview

The name of the game is to get all the patches to firefox applied successfully *and* have firefox compile.  Why?  So this variant, Camoufox, remains stealthy.

The camoufox root contains a Makefile and a ton of patches.  They are applied in alphabetical order by filename (not by directory structure). If there are actual dependencies between patches, they must be satisfied by this alphabetical ordering.

Then there is the firefox sourcecode directory.  This process assumes that it is a seperate git repo.  The author of this workflow file has actually set the repo to the firefox sourcecode repo (as opposed to the camoufox documentation, which starts with a zip file and then does a `git init && git commit` to have a repo with a single commit).

The firefox repo directory starts checked out to the matching git hash that playwright uses.  It gets tagged as `unpatched`.  A `make revert` will reset the repo to that specific tag.

Here are key commands:

```bash
make revert  # Start with clean Firefox source

make tagged-checkpoint  # Tag the current commit as "checkpoint"
make revert-checkpoint # Revert back to the "checkpoint"

make patch <patchfile> # apply the patch file

make dir # apply all the patches. will bomb once it hits a failure.
```

# Workflow

## General Workflow

Follow the "Inital Workflow" unless the human says it's in a good state.

The general workflow assumes you've checkpointed the last working patch and you can roll back to it via `make revert-checkpoint`

1) `make patch <next-patchfile>`
2) Did it work?  Great!  Do a `make tagged-checkpoint` and go to the next patch
3) If it didn't work, then you need to figure out why.  This is the hard part that requires actual "thinking".  See the "Fixing a broken patch" below
4) Once you've walked through all the patches and they all work, do a `make revert && make dev`
5) I don't know what happens at this point.... so stop and say "hi".

## Fixing a broken patch
Fixing a broken patch is where all the thinking happens.  First the rules of engagement:
1) *DO NOT MODIFY THE PATCH FILE!!!*  We will regenerate the patch file!
2) *MODIFY THE SOURCE CODE SO IT IS WHAT WE WANT TO SEE*.  In otherwords, *you* have to do the work of changing the source code!
3) Once successful, you do a `cd {ff_dir} && git diff > {patch_file}` to overwrite the patch file
4) Confirm it works (see general workflow, basically do a `make revert-checkpoint` to go back to working state, apply the patch... does it work now?)
5) Do a `git diff` on the patch file and confirm it changed what you expected.  Did you miss hunks that should have been patched?
6) Commit the patch with a good description
7) Update the [FIREFOX_142_UPGRADE_NOTES.md] file with the patch you fixed and what your research showed.  This is important because we are intentionally not building firefox each patch.... for all we know we broke the build!
8) Do a `make tagged-checkpoint` since the repo is now at a working good state.

### Here is some guidelines:

1) Look at the patch file and see what it is trying to accomplish.
2) Why did it fail?  Was it something like mismatched line?  Did firefox change something?
3) If they changed something, do a search through the git history in the firefox source directory looking for what caused the change....  try to figure it out.  If you can't, you need to escalate to a human.
4) Update this doc if you have any new insights

## Initial Workflow
If you start from `unpatched` (no checkpoints exist):

1) `make dir` to start the process
2) Hopefully all the patches apply, but if not then we have work to do....

## Getting to a known state...

If you aren't sure what state the git repo is but you know the last working patch, you can do the following

```bash
make revert
make patch ./patches/patch1.patch && make patch ./patches/patch2.patch ..... # go to last known working patch
make tagged-checkpoint # boom you are in business
```
