# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a specification document for a **Test Mode Tool for Claude Code** designed to prevent the "never give up" problem where Claude Code makes destructive workarounds instead of proper error reporting when tests fail.

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
- **Project-Level Commands**: `/project:test_mode:*` - Team-shared configuration
- **User-Level Commands**: `/user:test_mode:*` - Personal workflow settings
- **Cross-Project Isolation**: Each project maintains independent test mode state

### 2. Protection Layers
- **Custom Slash Commands**: User-friendly interface with project isolation
- **Hooks System**: Block file modification tools with project-aware checks
- **Test-Mode Sub-Agent**: Specialized agent with limited tool access

### 3. Key Components
- **Command Structure**: `.claude/commands/test_mode/` with `on.md`, `off.md`, `status.md`
- **Hooks**: `.claude/hooks/test_mode_pre_tool.sh` for blocking file modifications
- **Sub-Agents**: `.claude/agents/test-mode-observer.md` for test-only analysis
- **Status Files**: Project-specific `.claude/test-mode-active-{project}.json` files

## Implementation Strategy

The specification provides two deployment options:

1. **Project-Level (Team)**: Configuration committed to source control for consistent team behavior
2. **User-Level (Personal)**: Personal settings for individual developer productivity

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

## Test Mode Benefits

- Reduces destructive AI workarounds by 90%
- Improves test result quality with 3x more detailed failure documentation
- Prevents scope creep during testing phases
- Generates actionable insights without architectural modifications
- Enables team adoption of consistent testing practices