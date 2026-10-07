# ootree

> **Sovereign directory hierarchy and tree visualizer for the openOODA era.**  
> *A drop-in `tree` alternative written in pure openOODA, featuring negative-trust capability security, Unicode branch glyphs, `oote` theme integration, human-readable file sizes, and a first-class Model Context Protocol (MCP) surface.*

Part of [openOODA-tools](https://github.com/openOODA-tools).

---

## 1. Installation

`ootree` has zero runtime dependencies. It compiles to a standalone native binary linked directly with libc.

### Universal Web Installer
Installs the standalone native binary to `/usr/local/bin` (or `~/.local/bin`):

```bash
curl -fsSL https://openooda-tools.github.io/ootree/install.sh | bash
```

### Debian / Ubuntu (APT)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootree/install.sh | bash -s -- --apt

# Or manual package install
sudo dpkg -i ootree_0.1.0-1_amd64.deb
```

### Fedora / RHEL / CentOS (DNF)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootree/install.sh | bash -s -- --dnf

# Or manual RPM install
sudo dnf install ./ootree-0.1.0-1.fc44.x86_64.rpm
```

### Arch Linux (PKGBUILD)
```bash
# Automated via installer
curl -fsSL https://openooda-tools.github.io/ootree/install.sh | bash -s -- --arch

# Or manual build via packaging/PKGBUILD
cd packaging && makepkg -si
```

### Clean Uninstaller
To cleanly remove `ootree` and any installed package manager entries:

```bash
# Automated via standalone uninstaller
curl -fsSL https://openooda-tools.github.io/ootree/uninstall.sh | bash

# Or via installer flag
curl -fsSL https://openooda-tools.github.io/ootree/install.sh | bash -s -- --uninstall

# Or preview removal without making changes (dry-run)
curl -fsSL https://openooda-tools.github.io/ootree/uninstall.sh | bash -s -- --dry-run
```

---

## 2. Usage & Features

### Hierarchical Tree Visualization
Inspect directories with depth boundaries and formatted glyphs:

```bash
# Display directory tree
ootree

# Limit traversal depth to 2 levels
ootree -L 2

# Include hidden / dot files
ootree -a

# Show human-readable file size badges
ootree -s

# Show directories only
ootree -d
```

### Theme Palettes (`oote` Integration)
`ootree` detects and applies active themes from `~/.openooda/theme.oot` or `$OODA_THEME`:

```bash
# Override active theme on invocation
ootree --theme=cyberpunk
ootree --theme=dracula
```

### Model Context Protocol (MCP) Mode
`ootree` speaks JSON-RPC 2.0 MCP over stdio for LLM coding agents:

```bash
ootree --mcp
```

#### MCP Tools Provided:
- `tree_structure`: Generate a formatted directory tree representation.
  - Parameters: `path` (string, optional)
- `tree_summary`: Count total directories and regular files in hierarchy.
  - Parameters: `path` (string, optional)

---

## 3. Capability Security & Verification

`ootree` enforces strict Object Capability Discipline (OCap):
- **FsReadCap**: Strictly bounded read-only access to files and directory entries.
- **ProcessCap**: Bounded exit code handling.
- **Zero Ambient Authority**: Zero network sockets, zero child process spawning, zero unprompted disk writes.