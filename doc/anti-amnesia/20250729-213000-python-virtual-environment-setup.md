# Python Virtual Environment Setup for Reddit Integration

**Date**: 2025-07-29 21:30:00  
**Status**: Complete  
**Feature**: Python virtual environment setup for Reddit integration

## Overview

Successfully resolved the "externally-managed-environment" error when installing PRAW on macOS with Homebrew Python. This is a common issue with modern Python installations that protect system packages.

## Problem Encountered

When trying to install PRAW with `pip3 install praw`, user encountered:
```
error: externally-managed-environment
× This environment is externally managed
╰─> To install Python packages system-wide, try brew install xyz
```

This is PEP 668 protection in modern Python installations.

## Solution Implemented

### Virtual Environment Approach (Recommended)
```bash
# Create dedicated virtual environment for Scriptorium
python3 -m venv ~/.scriptorium-python

# Activate virtual environment
source ~/.scriptorium-python/bin/activate

# Install PRAW in isolated environment
pip install praw

# Test installation
python -c "import praw; print('PRAW installed successfully')"

# Deactivate when done
deactivate
```

### Alternative Solutions Available
1. **--user flag**: `pip3 install --user praw`
2. **pipx**: `brew install pipx && pipx install praw`
3. **Override protection**: `pip3 install --break-system-packages praw` (not recommended)

## Code Updates Made

### 1. Enhanced Reddit Integration (`lib/scriptorium/reddit.rb`)
- Added `find_python_environment` method to detect virtual environments
- Updated autopost method to use appropriate Python environment
- Automatic fallback to system Python if virtual environment not found

### 2. Updated Dependency Checker (`scripts/check_dependencies.rb`)
- Enhanced `check_python_package` to check multiple Python environments
- Added virtual environment detection logic
- Updated installation guidance to include virtual environment setup

### 3. Updated Documentation (`doc/reddit_integration.md`)
- Added virtual environment setup instructions
- Included alternative installation methods
- Added note about externally-managed-environment errors

## Virtual Environment Detection

The system now checks for Python packages in this order:
1. **System Python3** - `python3`
2. **Scriptorium Virtual Environment** - `~/.scriptorium-python/bin/python`
3. **Common Virtual Environment Locations**:
   - `~/.virtualenvs/scriptorium/bin/python`
   - `~/venv/scriptorium/bin/python`
   - `~/env/scriptorium/bin/python`

## Benefits of Virtual Environment Approach

1. **Isolation** - Scriptorium's Python dependencies don't conflict with system packages
2. **Clean Management** - Easy to recreate or update the environment
3. **No System Pollution** - Doesn't modify system Python installation
4. **Reproducible** - Same environment can be recreated on other systems
5. **Automatic Detection** - Scriptorium finds and uses the environment automatically

## User Experience

- **Simple Setup** - Just 4 commands to create and populate virtual environment
- **Transparent Usage** - Users don't need to manually activate environment
- **Automatic Detection** - Scriptorium handles environment selection
- **Clear Guidance** - Dependency checker provides specific setup instructions

## Testing Status

- **Virtual Environment Creation** - ✅ Tested and working
- **PRAW Installation** - ✅ Successfully installed in virtual environment
- **Automatic Detection** - ✅ Scriptorium finds virtual environment
- **Fallback Behavior** - ✅ Falls back to system Python if needed
- **Dependency Checker** - ✅ Correctly identifies PRAW availability

## Future Considerations

### Potential Enhancements
1. **Automated Setup Script** - Create virtual environment automatically
2. **Environment Management** - Update, recreate, or clean virtual environments
3. **Multiple Python Versions** - Support for different Python versions
4. **Dependency Locking** - Pin exact versions for reproducibility

### Maintenance Notes
- **Virtual Environment Paths** - Monitor for changes in Python ecosystem
- **PEP 668 Compliance** - Stay updated with Python packaging standards
- **Cross-Platform Support** - Ensure virtual environment detection works on Windows/Linux 