---
name: test_mode_off
description: "Deactivate test mode and restore normal file modification permissions"
---

# Test Mode Deactivation

You are deactivating TEST MODE for this project.

## Deactivation Steps

1. **Restore Claude Code settings** - Remove test mode hooks
2. **Remove test mode status file** (.claude/test-mode-active.json)
3. **Return to main Claude agent** (exit sub-agent if active)
4. **Display deactivation confirmation**

## Restoration Actions

1. Remove or comment out the test mode hooks from `.claude/settings.json`
2. Delete `.claude/test-mode-active.json` if it exists
3. Confirm normal file modification permissions are restored

## Success Message

Display when complete:
```
✅ TEST MODE DEACTIVATED ✅

Normal file modification permissions restored.
You can now:
- Edit source files
- Write new files
- Modify configurations
- Make changes to fix issues

Ready for normal development mode!
```

Now restore normal development capabilities.