# Repository instructions

## Git and releases

- Do not commit, push, create or move tags, create releases, or trigger GitHub Actions unless the user explicitly says `push` in the current conversation.
- Requests such as `update`, `fix`, `change`, `build` authorize local edits and local verification only; they do not authorize Git operations or publishing.
- When the user explicitly requests a push, commit the scoped changes, push the current branch, and create a new version tag only when a tagged release was requested or clearly established by the conversation.
- After pushing a release tag, report the GitHub Actions run link once. Do not poll, monitor, wait for, or report the final workflow result unless the user explicitly asks for monitoring.
- Never reuse, move, or overwrite an existing release tag unless the user explicitly approves that destructive action.
