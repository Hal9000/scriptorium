# Livetext Plugin File Statistics Feature

## Overview
Implemented a `.stats` dot command in the Scriptorium Livetext plugin (`lt3scriptor.rb`) that calculates file statistics and sets variables for use throughout the document.

## Implementation Details

### Dot Command
- **`.stats`** - Calculates multiple file metrics and sets variables

### Variables Set
- `$file.wordcount` - Number of words in the file
- `$file.readingtime` - Estimated reading time in minutes (200 words/minute)
- `$file.charcount` - Total character count

### Usage Example
```
.stats
This post has $file.wordcount words and takes about $file.readingtime minutes to read.
The character count is $file.charcount.
```

## Technical Approach

### Why Dot Commands Instead of Functions
- Livetext's `$$function` system is buggy and unreliable
- Dot commands (`.command`) work consistently
- Variable-based approach is more flexible than direct output

### Variable Naming Convention
- Uses `file.` prefix to namespace file-related statistics
- Follows lowercase convention after prefix to distinguish from system variables
- System variables are capitalized (e.g., `$File`)
- Custom variables are lowercase after prefix (e.g., `$file.wordcount`)

### Future Extensions
Could easily add more metrics:
- `$file.linecount` - Number of lines
- `$file.paragraphcount` - Number of paragraphs
- `$file.sentencecount` - Number of sentences
- `$file.complexityscore` - Readability score

## Scriptorium Integration Ideas

### Automatic File Stats During Processing
- File statistics could be automatically gathered when Scriptorium processes a post
- This would eliminate the need for users to manually call `.stats`
- Variables like `$file.wordcount` would be automatically available in all posts

### Scriptorium-Specific Variables
- Could set additional Scriptorium-specific variables during processing:
  - `$post.id` - Post ID/number
  - `$post.view` - Current view name
  - `$post.theme` - Theme being used
  - `$post.created` - Creation timestamp
  - `$post.published` - Publication date
  - `$post.views` - List of views this post appears in
  - `$post.tags` - Post tags
  - `$post.blurb` - Post blurb/summary

### Processing Pipeline Enhancement
- When `Scriptorium::Repo#generate_post` processes a draft with Livetext
- Could automatically calculate and set file statistics
- Could set post metadata variables
- Would make these variables available in templates and layouts

## Testing
- Added `test_stats_command` to `test/livetext_plugin_test.rb`
- Tests that variables are set correctly and can be referenced inline
- Verifies that literal variable names don't appear in output

## Potential for Livetext Core
This feature could be a good addition to Livetext core someday, but should prioritize fixing existing bugs in the function system first. 