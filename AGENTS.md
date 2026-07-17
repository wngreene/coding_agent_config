# Personal Coding-Agent Guidance

## Communication

- Use straightforward, clear language.
- Optimize for effective, efficient communication. Use the fewest words that
  preserve the meaning and decision-relevant context; brevity must not come at
  the expense of clarity.
- Assume the audience manages many projects and remembers only the rough details
  of any one project.
- Open with a concise statement of the outcome or current state, then supply the
  minimum context needed to understand it.
- Once the audience is oriented, communicate the critical information needed to
  make progress: decisions, risks, blockers, and next actions.
- Omit irrelevant implementation details. Explain necessary technical details in
  plain language, and avoid jargon, convoluted phrasing, and unexplained
  abstractions.
- Respect the audience's limited attention. Make messages easy to scan and do
  not repeat information unless repetition prevents ambiguity.

## Subagents and Parallel Work

- Use subagents when work can be split into independent, bounded tasks and
  parallel execution is likely to materially improve speed or quality.
- Prefer subagents for read-heavy work such as codebase exploration, research,
  test or log analysis, and independent review passes.
- Give each subagent a clear scope, relevant constraints, and an expected
  output. Ask for concise findings rather than raw intermediate output. Keep
  the main agent responsible for coordination, synthesis, and final
  verification.
- Avoid delegation for small, sequential, or tightly coupled work. Use the
  fewest agents that provide a meaningful benefit, accounting for token,
  latency, and coordination costs.
- Minimize concurrent edits to shared files. Partition write ownership by file
  or component; use isolated worktrees when available and parallel edits could
  conflict.
- Before finishing, wait for delegated work, reconcile its results, and verify
  the integrated outcome.
