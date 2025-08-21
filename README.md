# Test Mode Tool for Claude Code

A defensive security system that prevents Claude Code from making destructive modifications during test analysis, ensuring test failures remain as valuable diagnostic information.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security](https://img.shields.io/badge/Security-Audited-green.svg)](./docs/security.md)

## 🎯 Problem Solved

**The "Never Give Up" Problem**: When Claude Code encounters test failures, it tends to:
- ❌ Modify source code to make tests pass instead of reporting issues
- ❌ Change test expectations to avoid failures  
- ❌ Add mocks to bypass real implementation challenges
- ❌ Refactor working code to "fix" test problems

**Our Solution**: Test Mode Tool creates hard boundaries that channel AI persistence into productive observation rather than destructive modification.

## 🛡️ What Test Mode Does

### When Active:
- ✅ **Analyzes test failures** without making code changes
- ✅ **Documents root causes** with detailed investigation
- ✅ **Suggests specific fixes** for human developers to implement  
- ✅ **Preserves test intent** - doesn't change what tests validate
- ✅ **Maintains project isolation** - no cross-project interference

### What's Blocked:
- 🚫 **File modifications**: Edit, Write, MultiEdit tools blocked
- 🚫 **Dangerous commands**: rm, mv, cp, output redirection blocked
- 🚫 **Test changes**: No modification of test expectations
- 🚫 **Configuration changes**: Package installs and config updates blocked

## 🚀 Quick Start

### 1. Install
```bash
# Set permissions
chmod +x .claude/hooks/*.sh

# Install test mode hooks  
.claude/hooks/test_mode_setup.sh enable

# Validate installation
.claude/hooks/test_mode_setup.sh validate
```

### 2. Use Test Mode
```bash
# Activate test mode
/project:test_mode:on

# Run tests - Claude will analyze without modifying files
npm test  # or mvn test, pytest, etc.

# Check what Claude found
/project:test_mode:status

# Deactivate when done
/project:test_mode:off
```

### 3. Deploy to Other Projects
```bash
# Install to another project safely
./install_test_mode.sh /path/to/other/project

# Validate before installing
./install_test_mode.sh --dry-run /path/to/other/project
```

## 🏗️ Architecture

### Three-Layer Protection System

1. **Custom Slash Commands** - `/project:test_mode:on|off|status`
   - User-friendly interface with project isolation
   - Support for scoped activation and time limits

2. **Security Hooks System** - Comprehensive file modification blocking
   - PreToolUse hooks block destructive tools
   - PostToolUse hooks log violations and usage
   - Project context validation prevents interference

3. **Specialized Agents** - Read-only test analysis  
   - `test-mode-observer`: Analyzes tests without modifications
   - `test-reporter`: Generates comprehensive reports

### Project Isolation
- **Independent State**: Each project maintains separate test mode status
- **Path Validation**: All operations validated against project context  
- **Clean Separation**: Zero cross-project interference
- **Dual Deployment**: Project-level (team) and user-level (personal) options

## 📊 Expected Benefits

- **90% Reduction** in destructive AI workarounds during testing
- **3x More Detailed** test failure documentation
- **Zero Test Expectation** modifications - preserves original intent
- **Complete Project Isolation** - no cross-project interference
- **Improved Architectural Insights** - test failures reveal design issues

## 🔧 Installation Options

### Project-Level (Team Deployment)
Configuration committed to source control for consistent team behavior:
```bash
# Install for entire team
.claude/hooks/test_mode_setup.sh enable
git add .claude/
git commit -m "Add Test Mode Tool"
```

### User-Level (Personal Workflow)  
Personal settings across all projects:
```bash
# Copy to user directory
cp -r .claude/commands/test_mode ~/.claude/commands/
cp .claude/hooks/*.sh ~/.claude/hooks/
~/.claude/hooks/test_mode_setup.sh enable --user
```

### Other Projects
Use the secure installation script:
```bash
./install_test_mode.sh /path/to/target/project
```

## 🛡️ Security Features

### Multi-Layer Security Model
- **Input Validation**: JSON size limits, syntax validation, anti-traversal
- **Project Isolation**: Context validation, path matching, stale file cleanup  
- **Atomic Operations**: Backup creation, rollback capability, validation
- **Monitoring**: Security event logging, usage analytics, retention policies

### Threat Protection
- ✅ **File System Attacks**: Directory traversal, symlink attacks blocked
- ✅ **Command Injection**: Shell injection, path injection prevented  
- ✅ **Logic Attacks**: Race conditions, state manipulation defended
- ✅ **Cross-Project Interference**: Complete isolation with validation

## 📚 Documentation

- **[Installation Guide](INSTALLATION.md)** - Complete setup instructions
- **[Implementation Summary](IMPLEMENTATION_SUMMARY.md)** - Technical details
- **[Hook System Documentation](.claude/hooks/README.md)** - Security model
- **[Agent Documentation](.claude/agents/README.md)** - Specialized agents

## 🔍 Usage Examples

### Basic Workflow
```bash
# Activate test mode for current project
/project:test_mode:on

# Run failing tests
npm test

# Claude analyzes and documents issues without modifying code
# Check findings with /project:test_mode:status
# Review suggestions in TodoWrite output

# Deactivate and implement suggested fixes
/project:test_mode:off
```

### Advanced Usage
```bash
# Scoped activation (backend only)
/project:test_mode:on --scope=backend

# Time-limited session (auto-deactivate after 1 hour)
/project:test_mode:on --duration=1h --strict

# Multi-project isolation
cd ~/project-a && /project:test_mode:on    # Active only in project-a
cd ~/project-b && /project:test_mode:on    # Independent state in project-b
```

## 🤝 Contributing

We welcome contributions to improve the Test Mode Tool! Please:

1. **Security First**: All contributions must maintain security standards
2. **Defensive Focus**: This tool prevents destructive behavior, not enables it
3. **Project Isolation**: Ensure no cross-project interference in changes
4. **Comprehensive Testing**: Validate security and functionality

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Installation Issues**: See [INSTALLATION.md](INSTALLATION.md) 
- **Troubleshooting**: Check [Hook System README](.claude/hooks/README.md)
- **Security Concerns**: Review security model in documentation
- **Feature Requests**: Open an issue with defensive security focus

## 🏆 Recognition

This tool addresses the fundamental "never give up" problem identified by the VibeTDD experiments in AI-assisted development, where AI persistence leads to destructive workarounds instead of proper issue analysis.

### Inspiration & Discovery

This solution was inspired by the groundbreaking analysis from **VibeTDD** that discovered Claude Code's problematic "never give up" behavior during testing:

- **Blog Post**: [Will Never Give Up](https://blog.vibetdd.dev/posts/2025/08/will-never-give-up)
- **LinkedIn Discussion**: [Original LinkedIn Post](https://www.linkedin.com/feed/update/urn:li:activity:7362411558188081152)

The VibeTDD experiments revealed that Claude Code consistently:
- Modifies source code to make failing tests pass
- Changes test expectations to avoid addressing real issues  
- Adds mocks and workarounds instead of documenting actual problems
- Turns testing sessions into refactoring sessions

### Our Solution

By creating hard boundaries through this Test Mode Tool, we channel AI capabilities into productive observation rather than harmful modification. The tool enforces the principle that **test failures are valuable diagnostic information, not problems to hide**.

**Credit**: Special thanks to the VibeTDD team for identifying this critical issue in AI-assisted development and inspiring defensive solutions like this Test Mode Tool.