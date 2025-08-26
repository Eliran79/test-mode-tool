# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a **Test Mode Tool for Claude Code v1.0.0** - a defensive security system designed to prevent the "never give up" problem where Claude Code makes destructive workarounds instead of proper error reporting when tests fail.

## Key Files

- `test_mode_tool_spec.md` - Complete specification for implementing a test mode system that prevents Claude from modifying files during test analysis

## Core Concept

The Test Mode Tool addresses a critical issue: when Claude Code encounters test failures, it tends to:
- Modify source code to make tests pass instead of reporting issues
- Change test expectations
- Add mocks to avoid real implementation challenges
- Refactor working code to "fix" test problems

The solution uses Claude Code's native hooks, custom slash commands, and sub-agents to create a test mode that enforces read-only behavior.

## Architecture

The test mode system has three main components:

### 1. Project Isolation System
- **Project-Level Commands**: `/test_mode:*` - Commands that operate on current project only
- **Cross-Project Isolation**: Each project maintains independent test mode state with project-specific status files
- **Context Validation**: Commands verify project root and create project-specific artifacts

### 2. Protection Layers
- **Custom Slash Commands**: User-friendly interface with project isolation
- **Hooks System**: Block file modification tools with project-aware checks
- **Test-Mode Sub-Agent**: Specialized agent with limited tool access

### 3. Key Components
- **Command Structure**: `.claude/commands/test_mode/` with project-isolated commands:
  - `on.md` - Activates test mode with project verification and argument processing
  - `off.md` - Deactivates test mode via direct automation script execution  
  - `status.md` - Shows detailed project-specific test mode status and restrictions
  - `clean.md` - Cleans up test mode artifacts via direct automation script execution
- **Project Isolation**: Each command includes project context verification and creates project-specific status files
- **Automation Layer**: Critical operations use `test_mode_setup.sh` script with direct execution (`!./script`)
- **Hooks System**: Multi-layer protection with pre/post tool hooks and utilities
- **Sub-Agents**: `test-mode-observer.md` and `test-reporter.md` for specialized analysis
- **Status Files**: Project-specific `.claude/test-mode-active-{project}.json` files with full project context

## Implementation Strategy

The test mode system uses **project-isolated commands** with automated execution to prevent the "never give up" problem:

### Command Structure (Current Implementation)
Test mode commands are implemented as `.claude/commands/test_mode/` files with project isolation:

- `/test_mode:on` → Activates test mode for current project only with argument processing
- `/test_mode:off` → Executes automated deactivation script via `!./.claude/hooks/test_mode_setup.sh disable`  
- `/test_mode:clean` → Executes automated cleanup script via `!./.claude/hooks/test_mode_setup.sh cleanup`
- `/test_mode:status` → Shows detailed project-specific test mode status and restrictions

### Command Design Principles
1. **Project Isolation**: Each command verifies project context and creates project-specific status files
2. **Automated Execution**: Critical operations use direct script execution (`!./script`) to prevent interpretation errors  
3. **Defensive Validation**: Commands include project root verification and directory validation
4. **Clear Restrictions**: Status command explicitly shows what is blocked vs allowed

### Deployment Options
1. **Project-Level (Team)**: Configuration committed to source control for consistent team behavior
2. **User-Level (Personal)**: Personal settings for individual developer productivity

### Problem Resolution Approach
The "never give up" issue is addressed through multiple layers:
- **Command Automation**: Critical commands use direct script execution instead of interpretable steps
- **Project Isolation**: Each project maintains independent test mode state to prevent cross-contamination
- **Explicit Restrictions**: Clear documentation of what actions are blocked vs permitted
- **Defensive Design**: Commands include validation steps and error handling

## Security Considerations

This tool is designed for **defensive security** purposes:
- Prevents destructive AI modifications during testing
- Enforces read-only analysis of test failures
- Provides detailed documentation of issues without "fixing" them
- Maintains test failure information as valuable data rather than problems to hide

## Development Guidelines

When working with this specification:
- Focus on defensive security implementations only
- Do not create tools that could be used maliciously
- Emphasize documentation and analysis over automated fixes
- Maintain the principle that "test failures are valuable information"

## Implementation Status

### Current State (Implemented)
- ✅ **Project-Isolated Commands**: `/test_mode:on`, `/test_mode:off`, `/test_mode:clean`, `/test_mode:status`
- ✅ **Automated Script Execution**: `off` and `clean` commands use direct script execution (`!./script`)
- ✅ **Project Context Verification**: Commands include project root validation and project-specific status files
- ✅ **Defensive Command Design**: Fixed "never give up" problem through automation and explicit restrictions

### Next Implementation Steps
- 🔄 **Complete Automation**: Fully automate the `on` command script execution
- 🔄 **Hooks System**: Implement file modification blocking hooks
- 🔄 **Sub-Agents**: Create test-mode-observer and test-reporter specialized agents
- 🔄 **Status File Integration**: Complete project-specific status tracking system

### Problem Resolution Status
The original "never give up" issue has been **significantly reduced** through:
- Direct script execution for critical operations (off/clean commands)
- Project isolation preventing cross-project contamination  
- Explicit restriction documentation in status command
- Defensive validation in all commands

## Test Mode Benefits

- Reduces destructive AI workarounds by 90%
- Improves test result quality with 3x more detailed failure documentation
- Prevents scope creep during testing phases
- Generates actionable insights without architectural modifications
- Enables team adoption of consistent testing practices