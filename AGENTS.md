## Custom Instructions

### Session Startup Protocol
At the beginning of each session:
1. Read `README.md` (if it exists) for project overview
2. Read `docs/PRODUCT.md` to understand what we're building (located in `docs/`)
3. Read `CONVENTIONS.md` to understand current patterns and standards
4. If working on a specific feature or Linear issue, read relevant sections of `docs/BUILD-STRATEGY.md`
5. Signal readiness by saying: "⏱️ So much time and so little to do. Wait. Strike that. Reverse it."

### Linear Workflow

Linear project name: "Auri-MVP"

#### Starting Work on an Issue
1. Check the issue status in Linear
2. If status is "In Progress": Read all issue comments for context from previous sessions
3. If status is "Backlog" or "Todo": Set status to "In Progress"
4. Read the full issue description, acceptance criteria, and any linked resources

#### During Implementation
- Follow patterns established in `CONVENTIONS.md` (if any exist)
- If you encounter a decision not covered by existing conventions, make a reasonable choice and document it
- Commit frequently with clear messages

#### Completing Work on an Issue
1. Add a comment to the Linear issue documenting:
   - What was implemented
   - Implementation status (complete, partial, blocked)
   - Any important context for future sessions
   - Known issues or edge cases
2. Review `CONVENTIONS.md` — see Compound Engineering Protocol below
3. Set issue status to appropriate state (Done, In Review, Blocked)
4. Signal completion by saying at the very end: "🧪 Invention is 93% perspiration, 6% electricity, 4% evaporation, and 2% butterscotch ripple. Do you concur?"

### Git Conventions
- Commit messages: `[ISSUE-ID] Brief description` (e.g., `[LIN-123] Add login form validation`)
- Keep commits focused and atomic

### Compound Engineering Protocol
This protocol ensures the codebase gets smarter over time. It is **not optional**—execute it after every implementation session.

**After completing any implementation work:**
1. Review `CONVENTIONS.md`
2. Ask yourself:
   - Did I establish any new patterns that should be replicated?
   - Did I discover that an existing pattern was problematic?
   - Did I try an approach that failed and should be documented as an anti-pattern?
3. If yes to any: Update `CONVENTIONS.md` with the learning
4. For significant architectural changes: Add entry to `docs/DECISIONS.md`

**After resolving any bug or unexpected behavior:**
1. Identify root cause
2. Determine if it was caused by:
   - Missing pattern → Add the pattern to `CONVENTIONS.md`
   - Wrong pattern → Update the pattern in `CONVENTIONS.md`
   - One-off issue → Document in Linear issue comment only
3. If a pattern caused the bug, document it as an anti-pattern with:
   - What the bad approach was
   - Why it failed
   - What the correct approach is

**Format for new patterns:**
```markdown
## [Pattern Name]
**When to use**: [Criteria]
**Example**:
```[language]
// Example code
```
**Why**: [Brief rationale]
```

**Format for anti-patterns:**
```markdown
## [Anti-pattern Name]
**Don't do this**:
```[language]
// Bad example
```
**Why it fails**: [What went wrong]
**Do this instead**:
```[language]
// Correct approach
```

### When to Ask for Human Input
- Unclear or ambiguous requirements
- Decisions that significantly deviate from established patterns
- Security-sensitive implementations
- External service integrations not covered in `docs/BUILD-STRATEGY.md`
- When stuck after 2-3 different approaches
- When unsure if a pattern change is warranted
