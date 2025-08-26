# Test Mode Tool Documentation

This directory contains detailed technical documentation for the Test Mode Tool defensive security system.

## Documentation Overview

### Core Specification
- **[test_mode_tool_spec.md](test_mode_tool_spec.md)** - Complete system specification and design

### Agent Specifications  
- **[test-mode-observer.md](test-mode-observer.md)** - Read-only test analysis agent
- **[test-reporter.md](test-reporter.md)** - Comprehensive test reporting agent
- **[hook-system-builder.md](hook-system-builder.md)** - Secure hook system builder

### Development Documentation
- **[plan.md](plan.md)** - Original implementation planning document

## Quick Navigation

### For Users
- **Getting Started**: See [../README.md](../README.md)
- **Installation**: See [../INSTALLATION.md](../INSTALLATION.md)
- **Configuration**: See [../.claude/settings.example.json](../.claude/settings.example.json)

### For Developers
- **System Architecture**: [test_mode_tool_spec.md](test_mode_tool_spec.md)
- **Security Model**: [../.claude/hooks/README.md](../.claude/hooks/README.md)  
- **Agent Design**: [test-mode-observer.md](test-mode-observer.md)

### For Security Auditors
- **Threat Model**: [test_mode_tool_spec.md](test_mode_tool_spec.md) (Security sections)
- **Hook Implementation**: [../.claude/hooks/README.md](../.claude/hooks/README.md)
- **Input Validation**: Hook scripts in [../.claude/hooks/](../.claude/hooks/)

## Documentation Categories

### 📋 Specifications
Complete technical specifications for all components of the Test Mode Tool system.

### 🛡️ Security
Comprehensive security model, threat analysis, and protection mechanisms.

### 🏗️ Architecture  
System design, component interactions, and project isolation mechanisms.

### 🔧 Implementation
Detailed implementation notes, code structure, and development decisions.

### 🚀 Deployment
Installation procedures, configuration options, and operational guidance.

This documentation is maintained alongside the codebase to ensure accuracy and completeness.