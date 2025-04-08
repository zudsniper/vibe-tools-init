# vibe-tools-init

A utility script to initialize projects with cursor-tools configuration. This tool makes it easy to set up and manage your cursor-tools configuration across multiple projects.

## Features

- Initialize projects with cursor-tools configuration
- Store and reuse a default configuration template
- Update .gitignore with cursor-tools related entries
- Support for both new and legacy cursor-tools configurations

## Installation

You can install `vibe-tools-init` using the provided install script:

```bash
curl -fsSL https://raw.githubusercontent.com/zudsniper/vibe-tools-init/main/install.sh | bash
```

Or manually:

1. Clone this repository
2. Make the script executable (`chmod +x vibe-tools-init`)
3. Move it to a directory in your PATH

## Usage

```bash
vibe-tools-init [OPTIONS] [PROJECT_DIR]
```

### Options

- `-i, --init SOURCE_DIR` - Initialize default template from SOURCE_DIR
- `-f, --force` - Force overwrite existing files
- `-h, --help` - Show help message
- `-v, --version` - Show version information

### Examples

Initialize the default template from an existing project:

```bash
vibe-tools-init --init /path/to/existing/project
```

Initialize a new project using the stored default template:

```bash
vibe-tools-init /path/to/new/project
```

Initialize a project from another project without updating default:

```bash
vibe-tools-init --init /path/to/source/project /path/to/destination
```

## Alias

This script is also available as `cursor-tools-init`, which points to the same executable.

## Related Projects

- [cursor-tools](https://github.com/eastlondoner/cursor-tools) - CLI tool for managing AI-assisted development with Cursor editor

## License

MIT
