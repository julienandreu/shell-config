# Summary

<!-- What does this PR do? -->
- 

## Why

<!-- Why is this change needed? -->
- 

# What changed

<!-- Key files / areas touched -->
- 
- 

# How to test

<!-- Commands run + expected outcome -->
- [ ] `bash -n bin/*.sh setup.sh install.sh onboard.sh` (syntax)
- [ ] `update --check` (Brewfile drift)
- [ ] `rebuild` (apply locally)
- [ ] `doctor` (green, or only expected warnings)
- [ ] Manual verification:
  - 

# Breaking changes

- [ ] No
- [ ] Yes (explain below)

<!-- If yes, include upgrade notes -->

# Migration notes

<!-- If users need to do anything after merging (e.g., delete a stale symlink, re-run setup.sh) -->
- 

# Notes for reviewer

<!-- Anything non-obvious or things to double-check -->
- 

# Checklist

- [ ] Changes are focused and intentional
- [ ] Tested locally with `rebuild` (and `doctor` green)
- [ ] No secrets committed (checked `.gitignore` and `secrets/`)
- [ ] `~/.config/dotfiles/config.sh` schema changes are documented (if any)
- [ ] README / docs updated if behavior changed
- [ ] Brewfile drift checked with `update --check`
- [ ] Catppuccin flavor changes tested (if applicable)
