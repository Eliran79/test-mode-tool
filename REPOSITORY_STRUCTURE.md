# Repository Structure

This document describes the organization of the Test Mode Tool repository.

## Root Directory

```
test-mode-tool/
├── README.md                   # Main project overview and quick start
├── INSTALLATION.md            # Comprehensive installation guide
├── LICENSE                    # MIT License with defensive security notice
├── CLAUDE.md                  # Guidance for future Claude Code instances
├── REPOSITORY_STRUCTURE.md    # This file - repository organization guide
├── .gitignore                 # Git exclusions for temporary files
├── install_test_mode.sh       # Secure installation script for other projects
├── docs/                      # Detailed technical documentation
└── .claude/                   # Test Mode Tool components
```

## Documentation Structure (`docs/`)

```
docs/
├── README.md                          # Documentation overview and navigation
├── test_mode_tool_spec.md            # Complete system specification
├── test-mode-observer.md             # Read-only test analysis agent spec
├── test-reporter.md                  # Test reporting agent spec
├── hook-system-builder.md            # Secure hook system builder spec
└── plan.md                           # Original implementation planning
```

## Test Mode Components (`.claude/`)

```
.claude/
├── settings.example.json              # Example configuration with comments
├── settings.json                      # Current project configuration
├── commands/test_mode/               # Slash commands
│   ├── on.md                         # /test_mode:on command
│   ├── off.md                        # /test_mode:off command (automation-based)
│   ├── clean.md                      # /test_mode:clean command (comprehensive)
│   ├── status.md                     # /test_mode:status command
│   └── README.md                     # Command documentation
├── agents/                           # Specialized sub-agents
│   ├── test-mode-observer.md         # Read-only test analysis agent
│   └── test-reporter.md              # Comprehensive reporting agent
├── hooks/                            # Security hook system
│   ├── test_mode_pre_tool.sh         # PreToolUse hook (blocks modifications)
│   ├── test_mode_post_tool.sh        # PostToolUse hook (logging)
│   ├── test_mode_setup.sh            # Installation/configuration script
│   ├── hook_utils.sh                 # Shared security utilities
│   └── README.md                     # Hook system documentation
└── logs/                             # Runtime logs (excluded from git)
    └── .gitkeep                      # Ensures directory exists
```

## File Categories

### 🚀 User-Facing Files
- **README.md** - Primary project introduction
- **INSTALLATION.md** - Step-by-step setup guide
- **install_test_mode.sh** - Cross-project deployment tool

### 📚 Documentation
- **docs/** - Technical specifications and implementation details
- **README.md files** - Component-specific documentation
- **CLAUDE.md** - Repository guidance for AI assistants

### ⚙️ Core Components
- **.claude/commands/** - Slash command definitions
- **.claude/agents/** - Specialized sub-agent definitions
- **.claude/hooks/** - Security hook implementations

### 🔧 Configuration
- **.claude/settings.example.json** - Configuration template
- **.claude/settings.json** - Active project configuration
- **.gitignore** - Version control exclusions

### 🛡️ Security
- **LICENSE** - Legal terms with security notice
- **Hook scripts** - Input validation and security enforcement
- **Installation script** - Secure deployment with validation

## File Permissions

### Executable Files (755)
- `install_test_mode.sh` - Installation script
- `.claude/hooks/*.sh` - All hook scripts

### Documentation Files (644)
- All `.md` files
- `.claude/settings.example.json`
- `LICENSE`

### Generated/Runtime (excluded from git)
- `.claude/logs/` - Runtime logs
- `.claude/test-mode-active-*.json` - Status files
- `.claude/backups/` - Backup files

## Git Configuration

### Tracked Files
- All source code and documentation
- Configuration examples and templates
- Hook scripts and installation tools
- .claude directory structure

### Excluded Files (.gitignore)
- Runtime status files (`.claude/test-mode-active-*.json`)
- Log files (`.claude/logs/`)
- Backup files (`.claude/backups/`)
- Local settings (`.claude/settings.local.json`)
- Temporary files and editor artifacts

## Deployment Ready

This repository structure is designed for:
- ✅ **Professional GitHub presentation** with clear documentation
- ✅ **Easy installation** via script or manual setup
- ✅ **Security validation** with comprehensive testing
- ✅ **Cross-project deployment** with isolation guarantees
- ✅ **Maintenance friendly** with organized documentation

The structure supports both individual developers and team deployments while maintaining complete security and project isolation.