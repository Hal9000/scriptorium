# AAA Syntax Clarification

**Date**: 2025-07-28 12:42:43  
**Topic**: Anti-amnesia interface syntax clarification  
**Status**: Clarified and documented

## Summary

Clarified the behavior of the `aaa` command in the anti-amnesia interface.

## Details

### Previous Understanding
- `aaa` at the beginning of a line captures that single line
- Used for capturing individual lines of conversation

### New Clarification
- `aaa` on a line by itself captures the **entire multi-line message**
- This is different from `aaa` at the beginning of a line, which only captures that line
- Messages are multi-line entities, and `aaa` alone captures the whole message

### Usage Examples

**Single line capture:**
```
aaa this line will be captured
```

**Full message capture:**
```
This is a multi-line message
with multiple lines of content
aaa
```

In the second example, the entire message (all lines) will be captured, not just the line with `aaa`.

## Impact

This clarification helps users understand how to capture entire messages vs. individual lines when using the anti-amnesia system.

## Related

- Anti-amnesia interface design
- Message capture mechanisms
- User interface documentation 
