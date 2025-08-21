---
name: test_mode_status  
description: "Check current test mode status and display restrictions"
---

# Test Mode Status Check

Check if test mode is currently active for this project.

## Status Check Steps

1. **Check for test mode status file** (.claude/test-mode-active.json)
2. **Verify hooks configuration** in .claude/settings.json
3. **Display current mode and restrictions**

## Status Display

If test mode is ACTIVE, show:
```
🔒 TEST MODE ACTIVE

Status: ACTIVE
Scope: [scope from status file]
Started: [timestamp from status file]  
Expires: [expiration if set]

CURRENT RESTRICTIONS:
❌ File modifications blocked (Edit, Write, MultiEdit)
❌ Configuration changes blocked
✅ Test execution allowed
✅ Read-only analysis allowed
✅ Documentation updates allowed

To exit: /project:test_mode:off
```

If test mode is INACTIVE, show:
```
🔓 TEST MODE INACTIVE

Status: INACTIVE
All file modification permissions available.

To activate: /project:test_mode:on
```

## Quick Health Check

Also verify:
- Are test mode hooks properly configured?
- Is the test-mode-observer sub-agent available?
- Any recent violations logged?

Display any issues found.