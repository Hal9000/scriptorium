# Post Class ID/Num Refactoring - Cleaner API Design

**Date:** 2025-07-27 18:00:00
**Status:** Completed

## Summary

Successfully refactored the `Scriptorium::Post` class to have a cleaner and more intuitive API design:
- **`id`** is now an integer (was previously a string alias for `num`)
- **`num`** remains a zero-padded string for file paths
- **`num!`** method removed (was redundant with new `id`)
- **`num_str`** method removed (was redundant with `num`)

## What Was Changed

### 1. Post Class Refactoring (`lib/scriptorium/post.rb`)
- **Added `@id` instance variable**: Integer version of the post number
- **Modified `initialize`**: Now sets both `@num` (string) and `@id` (integer)
- **Removed old `id` method**: Was just an alias for `num`
- **Removed `num!` method**: Functionality now provided by `id`
- **Updated `attr_reader`**: Now includes `:id`

### 2. Repository Integration (`lib/scriptorium/repo.rb`)
- **Fixed template variable**: `vars[:"post.id"] = num.to_s` to ensure string conversion for templates

### 3. API Class Fixes (`lib/scriptorium/api.rb`)
- **Fixed `create_post` method**: Added missing `blurb` parameter support
- **Fixed `quick_post` method**: Was calling wrong method (`post` instead of `create_post`)

### 4. Test Updates (`test/unit/post.rb`)
- **Updated `test_id`**: Now expects integer instead of string
- **Removed `num!` tests**: No longer needed
- **All tests pass**: 34 runs, 43 assertions

### 5. Manual Test Updates (`test/manual/test5.rb`)
- **Updated `generate_post` call**: Now uses `post.id` instead of `post.num!`

## Benefits of the Refactoring

1. **Clearer Intent**: `id` as integer clearly indicates it's for programmatic use
2. **Consistent API**: No more confusion between `num`, `num!`, and `id`
3. **Better Performance**: No need for string-to-integer conversion in `num!`
4. **Simpler Code**: Fewer methods to maintain and understand

## Usage Examples

```ruby
post = Scriptorium::Post.new(repo, 123)

# File operations (use num)
post.num          # => "0123"
post.dir          # => "posts/0123/"

# Programmatic operations (use id)
post.id           # => 123
@repo.generate_post(post.id)  # Pass integer to generate_post
```

## Test Results

- **All tests pass**: 283 runs, 1056 assertions, 0 failures
- **API demo works**: Successfully creates posts with new integer `id`
- **Backward compatibility**: Existing code using `num` continues to work

## Files Modified

1. `lib/scriptorium/post.rb` - Core refactoring
2. `lib/scriptorium/repo.rb` - Template variable fix
3. `lib/scriptorium/api.rb` - Method signature fixes
4. `test/unit/post.rb` - Test updates
5. `test/manual/test5.rb` - Manual test fix

This refactoring eliminates the "clunkiness" in the Post class by providing a clear separation between string-based file operations (`num`) and integer-based programmatic operations (`id`). 