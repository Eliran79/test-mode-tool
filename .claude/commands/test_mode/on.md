---
name: test_mode_on
description: "Activate test mode for THIS PROJECT ONLY - blocks file modifications and enables test-only agent"
tools: "Read,LS,Grep,Glob,Task,Bash"
---

# Project Test Mode Activation

You are activating TEST MODE for **THIS PROJECT ONLY**. 

**ISOLATION CHECK**: Verify this is the correct project by checking the project root.

## Project Context Verification
```bash
echo "Activating test mode for project: $(basename $(pwd))"
echo "Project root: $(pwd)"
```

## Arguments Processing
Process the arguments: $ARGUMENTS

Arguments format: [--scope=backend|frontend|all] [--duration=30m|1h|2h] [--strict]

## Activation Steps

1. **Verify project isolation** - Ensure we're in the right directory
2. **Update PROJECT settings** (.claude/settings.json in current project)
3. **Create PROJECT-specific status file** (.claude/test-mode-active-$(basename $(pwd)).json)
4. **Enable PROJECT-scoped hooks** with directory validation
5. **Switch to test mode sub-agent** for this project only

## Project-Specific Status File
Create status file with project identifier:
```json
{
  "project_name": "$(basename $(pwd))",
  "project_path": "$(pwd)",
  "active": true,
  "scope": "$SCOPE",
  "started_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "project-level"
}
```

## Context for Future Interactions

```
🔒 PROJECT TEST MODE ACTIVE 🔒
Project: $(basename $(pwd))

You are now in PROJECT-SPECIFIC TEST MODE.
File modifications are BLOCKED for this project only.
Other projects remain unaffected.

When tests fail:
✅ Document what failed and why  
✅ Analyze root causes specific to this project
✅ Suggest fixes for human review
❌ Don't modify code to make tests pass
❌ Don't change test expectations

Remember: Test failures are VALUABLE INFORMATION!
```

Execute: .claude/hooks/test_mode_setup.sh enable "$SCOPE" "$DURATION" "$STRICT" "$(pwd)"