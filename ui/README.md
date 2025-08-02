# Scriptorium UI Directory

This directory contains all user interface implementations for Scriptorium.

## Structure

```
ui/
├── tui/                    # Terminal User Interface
│   ├── bin/scriptorium     # TUI executable
│   ├── lib/                # TUI-specific code
│   └── test/               # TUI-specific tests
├── web/                    # Web User Interface (future)
│   ├── app/                # Web app code
│   ├── public/             # Static assets
│   └── test/               # Web-specific tests
└── common/                 # Shared UI utilities
    ├── lib/                # Common UI libraries
    └── test/               # Common UI tests
```

## TUI (Terminal User Interface)

The current TUI implementation provides a command-line interface for Scriptorium.

- **Location**: `ui/tui/bin/scriptorium`
- **Features**: Interactive commands, view management, post creation, deployment
- **Dependencies**: Readline (optional), core Scriptorium library

## Web UI (Future)

Planned web interface for Scriptorium.

- **Status**: Not yet implemented
- **Planned Features**: Web-based post editing, view management, real-time preview
- **Technology**: To be determined (Sinatra, Rails, or other framework)

## Common Utilities

Shared code that can be used by multiple UI implementations.

- **Location**: `ui/common/lib/`
- **Purpose**: API wrappers, validation, common UI patterns
- **Usage**: Imported by TUI, Web UI, and future interfaces

## Development

### Adding a new UI

1. Create a new directory under `ui/`
2. Follow the established structure (bin/, lib/, test/)
3. Import common utilities from `ui/common/lib/`
4. Update the gemspec to include the new UI files

### Testing

Each UI has its own test directory for UI-specific tests. Common functionality is tested in `ui/common/test/`.

### Dependencies

- **TUI**: Minimal dependencies, uses core Scriptorium library
- **Web UI**: Will have additional web framework dependencies
- **Common**: No additional dependencies beyond core Scriptorium

## Migration Notes

The TUI was moved from `bin/scriptorium` to `ui/tui/bin/scriptorium` to better organize the codebase and prepare for multiple UI implementations. 