# Anti-Amnesia: Scriptorium Conventions and Decisions

## Runeblog TUI Post Creation Pattern
**Date**: 2025-07-27  
**Context**: Understanding how Runeblog handled draft-to-post conversion  
**Decision**: Runeblog automatically converted drafts to posts after editing, without a separate "finish draft" step. This provides a fast workflow: edit → save → post (local), with deployment making it public.

## Scriptorium Setup vs Runeblog
**Date**: 2025-07-27  
**Context**: Comparing setup approaches between Scriptorium and Runeblog  
**Decision**: Runeblog had a `get_started` method that ran automatically when creating a new repository. Scriptorium should follow this pattern for better user experience.

## Editor Discovery Implementation
**Date**: 2025-07-27  
**Context**: Implementing editor discovery for TUI setup  
**Decision**: Created a `which()` helper method that uses `File.which` (Ruby 3.2+) or falls back to `system("which")`. Prioritized editors for "get in, get out" single-file editing: nano, vim, emacs, vi, micro, subl, ed.

## File Operation Consistency
**Date**: 2025-07-27  
**Context**: Ensuring consistent file operations across the project  
**Decision**: Replaced `File.read` calls with the project's `read_file` helper for centralized error handling. This maintains consistency with the project's file operation patterns.

## Automatic Setup Implementation
**Date**: 2025-07-27  
**Context**: Implementing Runeblog-style automatic setup when creating new repositories  
**Decision**: 
- Removed `setup` command from TUI (no longer needed)
- Modified `discover_repo` to call `create_new_repo` when no repository exists
- `create_new_repo` automatically calls `get_started` after creating repository
- This follows Runeblog's pattern: create repo → immediate setup → ready to use
- User experience: "Create new repository?" → "Yes" → automatic editor selection → ready to blog 