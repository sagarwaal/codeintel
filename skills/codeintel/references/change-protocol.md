# Change Protocol for Project Intelligence

Use this after implementing a feature, fixing a defect, refactoring, or changing architecture.

1. **Establish the change set**
   - Inspect Git diff/status without disturbing user changes.
   - Identify changed, added, deleted, and renamed files.
   - Record commands and tests actually run.

2. **Map the change**
   - Link changed files to components, workflows, public interfaces, data models, and external contracts.
   - Identify callers, consumers, and downstream dependencies.
   - Consider generated code, dynamic registration, and runtime-only dependencies.

3. **Update only affected knowledge**
   - Refresh component documentation, dependency maps, workflow traces, contracts, and task routing as applicable.
   - Update findings if the change resolves, worsens, or introduces an issue.
   - Update test coverage notes based on actual new or changed tests.
   - Reassess design principles only if the change establishes or materially alters a convention.

4. **Verify**
   - Run the most relevant focused tests, then broader tests where practical.
   - Record exact commands and outcomes.
   - Never infer a pass from a command that was not executed.
   - If verification could not be run, record why and what remains to be checked.

5. **Refresh inventory**
   - Update file hashes and component associations if an inventory is maintained.
   - Mark affected claims stale if they could not be revalidated.
   - Update `analysis_state.json` with the current commit and scope when available.

6. **Record a concise history entry**
   - Summarize what changed in the code and knowledge.
   - Note important architectural assumptions revised.
   - List unresolved risks and verification limitations.

Do not rewrite the entire knowledge base for a small change. Expand the review when a public contract, shared model, core abstraction, security boundary, or critical workflow changes.
