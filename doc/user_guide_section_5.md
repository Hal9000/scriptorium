# 5. Managing Posts

**[Errors here - fix later. HF]

## Creating Posts

Creating new posts is one of the most common tasks in Scriptorium. Posts are the core content of your blog or website.

### Using the Interactive Shell

The easiest way to create a post is through the Scriptorium interactive shell:

```
scriptorium
```

Once in the shell, you have two options for creating content:

**Create a draft:**
```
new draft My First Blog Post
```

**Create a post directly:**
```
new post My First Blog Post
```

### Drafts vs Posts

**Drafts** are temporary files for working on content:
- Stored in `drafts/` directory
- Filename format: `YYYYMMDD-HHMMSS-draft.lt3`
- Use `list drafts` to see all drafts
- Use `new draft` to create a draft

**Posts** are the final published content:
- Stored in `posts/` directory
- Directory format: `posts/0123/` (4-digit padded numbers)
- Use `list posts` to see all posts
- Use `new post` to create a post directly

### Post File Structure

Each post consists of a directory with the following structure:

**Post directory:** `posts/0123/`
- **source.lt3**: The post content in LiveText format
- **meta.txt**: Post metadata
- **body.html**: Generated HTML (created during generation)
- **assets/**: Directory for post-specific assets

**Post metadata file:** `posts/0123/meta.txt`
- Contains post metadata like title, date, author
- Automatically generated and updated by Scriptorium

### Post Content Format

Posts use LiveText format (see Section 3 for details). A typical post structure:

```
.h1 My First Blog Post
.h2 subtitle: Getting Started with Scriptorium

.p This is my first blog post using Scriptorium.

.h2 Why Scriptorium?

.p Scriptorium makes blogging simple and powerful.

.list
  **Easy to use** - Simple command-line interface
  **Flexible** - Multiple views and themes
  **Fast** - Static site generation
  **Customizable** - LiveText templating system
.end

.p That's it for my first post!
```

## Listing Content

### View All Posts

To see all posts in your current view:

```
list posts
```

This shows:
- Post title
- Post number

### View All Drafts

To see all drafts:

```
list drafts
```

This shows:
- Draft filename
- Draft title

## Editing Posts

### Opening a Post for Editing

To edit an existing post, you'll need to open the post file directly in your editor. Posts are stored in `posts/0123/source.lt3`.

### Post Numbering

Post numbers are sequential integers with 4-digit padding:
- **Format**: 4-digit padded numbers (0001, 0002, 0003, etc.)
- **Automatic**: Numbers are assigned when posts are created
- **Sequential**: Numbers increment automatically

### Finding Post Numbers

You can find post numbers by:
1. Using `list posts` to see all posts
2. Looking in the `posts/` directory
3. Checking the post metadata file

## Deleting Posts

### Marking Posts for Deletion

To delete a post, Scriptorium moves the post directory to a deleted state:

- **Normal post**: `posts/0001/`
- **Deleted post**: `posts/_0001/` (with underscore prefix)

### Restoring Deleted Posts

To restore a deleted post, move the directory back from `posts/_0001/` to `posts/0001/`.

### Post Status

Posts can be in different states:
- **Published**: Post is live and visible on your site
- **Deleted**: Post is marked for deletion (moved to `_0001/` directory)

## Linking Posts

### Internal Links

You can link between posts using their post numbers:

```
.p Check out my [previous post](posts/0001.html) for more information.
```

### Cross-View Links

To link to a post in a different view:

```
.p See my [technical blog post](../tech/posts/0005.html) for more details.
```

## Unlinking Posts

### Removing Posts from Views

The `unlink_post` command removes a post from the current view but doesn't delete the post itself. It has no other effect on the post.

## Featured Posts

### Marking Posts as Featured

Featured posts appear in the Featured Posts widget (see Section 4). To feature a post:

1. Edit `widgets/featuredposts/list.txt`
2. Add the post number on a new line:

```
1
5
10
```

### Featured Post Order

Posts appear in the Featured Posts widget in the order listed in `widgets/featuredposts/list.txt`.

### Removing Featured Status

To remove a post from featured status:

1. Edit `widgets/featuredposts/list.txt`
2. Remove the post number from the list
3. Regenerate the view

## Post Organization

### Post Numbering

Scriptorium automatically assigns sequential post numbers:
- **Automatic**: Post numbers are assigned when posts are created
- **Sequential**: Numbers increment automatically (1, 2, 3, etc.)
- **Padded**: Stored as 4-digit padded numbers (0001, 0002, etc.)

### Post Sorting

Posts are typically displayed in chronological order (newest first), but you can customize this through:
- **Featured posts**: Manual ordering in the Featured Posts widget
- **Theme customization**: Modify how posts are sorted in your theme

### Post Categories

While Scriptorium doesn't have built-in categories, you can organize posts by:
- **Views**: Different views for different types of content
- **Tags**: Using tags in post content (see Section 3)
- **Featured posts**: Highlighting important posts

## Post Workflow

### Typical Post Creation Workflow

1. **Create**: `new post "Post Title"`
2. **Write**: Edit the post content in LiveText format
3. **Generate**: Use `generate` to build the final site
4. **Deploy**: Use `deploy` to publish to your server

### Draft Workflow

1. **Create draft**: `new draft "Draft Title"`
2. **Work on content**: Edit and refine the draft
3. **Convert**: When ready, convert draft to post

### Post Maintenance

Regular post maintenance tasks:
- **Review posts**: Use `list posts` to see all posts
- **Review drafts**: Use `list drafts` to see all drafts
- **Check links**: Verify internal links are working
- **Update featured**: Keep featured posts current
- **Clean up**: Remove old deleted posts

Most of this is intuitive. If it's not, the software probably was written incorrectly. 