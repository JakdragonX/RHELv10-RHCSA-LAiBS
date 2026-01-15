# RHELv10-RHCSA-LAiBS
## Red Hat Enterprise Linux v10 - RHCSA Lab Interactive Bash Scripts

[![GitHub](https://img.shields.io/badge/GitHub-JakdragonX%2FRHELv10--RHCSA--LAiBS-blue?logo=github)](https://github.com/JakdragonX/RHELv10-RHCSA-LAiBS)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![RHEL](https://img.shields.io/badge/RHEL-10-red?logo=redhat)](https://www.redhat.com/)

A comprehensive, interactive lab environment for practicing Red Hat Certified System Administrator (RHCSA) exam objectives on RHEL 10 and compatible distributions.

**Key Features:**
- 🎯 Two learning modes: Exam-style and Interactive step-by-step
- 📚 Organized by RHCSA exam objectives into modules
- 📊 Automatic progress tracking across sessions
- ✅ Comprehensive validation with detailed feedback
- 🔧 One-command setup and installation

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/JakdragonX/RHELv10-RHCSA-LAiBS.git
cd RHELv10-RHCSA-LAiBS
```

### 2. Run Setup Script
```bash
bash setup-labs.sh
```

The setup script will:
- ✅ Install required dependencies (dos2unix)
- ✅ Fix script encoding (convert Windows CRLF to Unix LF)
- ✅ Set proper executable permissions
- ✅ Copy labs to `~/Labs` directory
- ✅ Install command shortcuts in `/usr/local/bin`

### 3. Start Learning
```bash
# View your first lab
sudo rhcsa-lab-01

# Or browse all available labs
cd ~/Labs/labs
ls -1 [0-9]*.sh
```

## Features

### 🎯 Two Learning Modes

**Standard Mode (Exam Preparation)**
- Full scenario presented at once
- You complete all tasks independently
- Validate when ready
- Mimics actual RHCSA exam conditions

```bash
sudo rhcsa-lab-01              # View scenario
# ... complete the tasks ...
sudo rhcsa-lab-01 --validate   # Check your work
```

**Interactive Mode (Learning)**
- Step-by-step guided completion
- Immediate feedback after each step
- Execute commands directly in the lab environment
- Built-in hints and solutions

```bash
sudo rhcsa-lab-01 --interactive
```

### 📊 Progress Tracking

The framework automatically tracks your lab completion:

```bash
# View overall progress
rhcsa-progress --summary

# Show labs that need retry
rhcsa-progress --retry

# View attempt history for specific lab
rhcsa-progress --history "Basic User Management"
```

Progress data is stored in `~/Labs/lab_progress.txt` and persists across sessions.

### 🔧 Available Commands

After installation, these commands are available system-wide:

| Command | Description |
|---------|-------------|
| `rhcsa-lab-01` | Run lab 01 (user management) |
| `rhcsa-lab-02` | Run lab 02 (file permissions) |
| `rhcsa-lab-XX` | Run any lab by number |
| `rhcsa-progress` | View your progress |

## Lab Usage

### Running a Lab

```bash
# Standard mode - see full scenario
sudo rhcsa-lab-01

# Interactive mode - step by step
sudo rhcsa-lab-01 --interactive

# Quick reference - objectives only
rhcsa-lab-01 --objectives

# Validate your work
sudo rhcsa-lab-01 --validate

# View solution
rhcsa-lab-01 --solution

# Clean up lab environment
sudo rhcsa-lab-01 --cleanup
```

### Understanding Lab Options

| Option | Requires Sudo | Description |
|--------|--------------|-------------|
| (none) | ✅ Yes | Display full scenario and set up environment |
| `--interactive` | ✅ Yes | Step-by-step guided mode with validation |
| `--validate` | ✅ Yes | Check your completed work |
| `--solution` | ❌ No | View the complete solution |
| `--objectives` | ❌ No | Quick objectives checklist |
| `--cleanup` | ✅ Yes | Remove lab components |
| `--help` | ❌ No | Show usage information |

## Directory Structure

After installation:

```
~/Labs/
├── labs/                    # Individual lab scripts
│   ├── 01-user-management.sh
│   ├── 02-file-permissions.sh
│   └── ...
├── lab-runner.sh           # Core framework (don't run directly)
├── track-progress.sh       # Progress tracking system
├── lab_progress.txt        # Your progress data (auto-created)
└── README.md              # This file
```

## Technical Details

### Why These Setup Steps?

#### 1. Line Ending Conversion (CRLF → LF)

**Problem**: Windows uses `\r\n` (Carriage Return + Line Feed), while Linux uses only `\n` (Line Feed).

**Symptoms**: Scripts fail with errors like:
```
/bin/bash^M: bad interpreter: No such file or directory
```

**Solution**: The setup script uses `dos2unix` to convert all `.sh` files to Unix format.

**Manual Fix** (if needed):
```bash
dos2unix script.sh
# Or using sed
sed -i 's/\r$//' script.sh
```

#### 2. PATH Installation

**Problem**: Without PATH configuration, you must use `./script.sh` or full paths.

**Solution**: Setup script creates symbolic links in `/usr/local/bin`, which is already in PATH for all users.

**What Happens**:
```bash
# Before setup:
cd ~/rhcsa-labs/labs
sudo ./01-user-management.sh

# After setup:
sudo rhcsa-lab-01  # From anywhere!
```

**Manual Installation** (if needed):
```bash
sudo ln -sf ~/Labs/labs/01-user-management.sh /usr/local/bin/rhcsa-lab-01
```

#### 3. Executable Permissions

**Problem**: Git doesn't always preserve executable permissions across all systems.

**Solution**: Setup script runs `chmod +x` on all `.sh` files.

**Manual Fix** (if needed):
```bash
chmod +x ~/Labs/labs/*.sh
chmod +x ~/Labs/*.sh
```

## Creating New Labs

Use the provided template to create consistent labs:

```bash
cd ~/Labs/labs
cp ../00-lab-template.sh 05-your-lab.sh
vim 05-your-lab.sh
```

The template includes:
- Complete structure with all phases
- Interactive mode support
- Validation framework
- Progress tracking integration
- Detailed comments explaining each section

## Troubleshooting

### "Command not found: rhcsa-lab-01"

**Cause**: Command shortcuts not in PATH or not created.

**Solution**:
```bash
cd ~/rhcsa-labs  # or wherever you cloned it
bash setup-labs.sh
```

### "bad interpreter: /bin/bash^M"

**Cause**: Windows line endings (CRLF) in script files.

**Solution**:
```bash
cd ~/Labs
dos2unix labs/*.sh *.sh
```

### Permission Denied

**Cause**: Script not executable or not running with sudo.

**Solution**:
```bash
# Make executable
chmod +x ~/Labs/labs/01-user-management.sh

# Run with sudo (labs modify system state)
sudo rhcsa-lab-01
```

### "No such file or directory" when sourcing lab-runner.sh

**Cause**: Lab script is not in expected directory structure.

**Solution**: Ensure labs are in `~/Labs/labs/` and framework scripts are in `~/Labs/`.

## Uninstalling

Remove the lab framework completely:

```bash
cd ~/Labs  # or wherever setup-labs.sh is located
bash setup-labs.sh --uninstall
```

This will:
- Remove all command shortcuts from `/usr/local/bin`
- Optionally remove `~/Labs` directory
- Preserve your progress data (if you keep the directory)

## System Requirements

- **OS**: RHEL 8/9, CentOS Stream, Rocky Linux, AlmaLinux, or compatible
- **Bash**: Version 4.0 or higher
- **Sudo**: Required for most lab operations
- **Dependencies**: 
  - `dos2unix` (auto-installed by setup script)

## Contributing

To add new labs:

1. Use the template: `00-lab-template.sh`
2. Follow the existing naming convention: `XX-descriptive-name.sh`
3. Implement all required functions:
   - `setup_lab()` - Idempotent environment setup
   - `prerequisites()` - Knowledge and tools needed
   - `scenario()` - Lab description and objectives
   - `validate()` - Check completion (export VALIDATION_SCORE and VALIDATION_TOTAL)
   - `solution()` - Complete walkthrough
4. (Optional) Add interactive mode:
   - `get_step_count()` - Return number of steps
   - `scenario_context()` - Brief context
   - `show_step_N()` - Display step N task
   - `validate_step_N()` - Validate step N
   - `solution_step_N()` - Show step N solution
   - `hint_step_N()` - Optional hint for step N

## License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

## Author & Repository

**Repository:** [JakdragonX/RHELv10-RHCSA-LAiBS](https://github.com/JakdragonX/RHELv10-RHCSA-LAiBS)

**Author:** JakdragonX

Built for RHCSA exam preparation on Red Hat Enterprise Linux v10 and compatible distributions.

## Acknowledgments

Built for RHCSA exam preparation. Objectives based on Red Hat Certified System Administrator (EX200) exam requirements.

Special thanks to the open-source community and Red Hat for providing excellent learning resources.

---

**Happy Learning! 🚀**

For questions, issues, or contributions, please open an issue on GitHub at:
https://github.com/JakdragonX/RHELv10-RHCSA-LAiBS/issues
