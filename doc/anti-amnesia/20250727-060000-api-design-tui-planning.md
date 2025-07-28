# API Design Decision & TUI Planning

## API Design Philosophy
- **Keep mental model consistent** - API should match Repo's repo/view/post model
- **Mental model changes reserved for UI** - different abstractions can be introduced in user interfaces
- **Current API is placeholder** - provides minor conveniences but not fundamentally different from Repo
- **Future API evolution** - may develop more significant differences as we discover real needs

## Next Priority: Text UI Development
- **Simple text interface** - command-line based, not curses
- **Wizard-based setup** - guided workflows for common tasks
- **Fast setup wizards** - quick blog creation and configuration
- **Interactive workflows** - step-by-step processes for complex operations

## TUI Design Considerations
- **Wizard approach** - guided setup for new users/repositories
- **Simple commands** - basic operations like create post, switch view
- **Context awareness** - remember current view/state
- **Error handling** - clear feedback and recovery options
- **Progressive disclosure** - simple interface with access to advanced features

## Potential Wizards
1. **Repository Setup Wizard** - create new repo with sample content
2. **View Creation Wizard** - guided view setup with theme selection
3. **Post Creation Wizard** - interactive post creation with metadata
4. **Deployment Wizard** - guided deployment process

---

**USER:** 
I am not yet noticing any real differences from Repo... maybe we could just say: API = Repo? mostly joking. As for the mental model, I would rather keep the API matching Repo -- that model might change for the UI, possibly. Let's keep it. Maybe we should start working on a simple text UI (with one or two "wizards" for fast setup)?

**ASST:** 
[See above content] 