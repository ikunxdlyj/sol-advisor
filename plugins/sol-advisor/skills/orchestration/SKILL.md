---
name: orchestration
description: "Cost-aware Codex routing: Sol owns decisions, lower-cost Luna/Terra workers execute bounded tasks in parallel, with proportionate verification and review."
---

# Sol Advisor Orchestration

Own the user's intent, architecture, route, integration and acceptance. Minimize
**total usage per accepted task**, including planning, context, execution, review
and retries. Use lower-cost models for work they can reliably complete; fewer
agents or fewer tool calls are not goals by themselves.

Read [references/role-contracts.md](references/role-contracts.md) before the first
delegation; use [references/operations.md](references/operations.md) for installation,
selected-role checks, runtime evidence and review isolation. Load only the relevant
sections, not every reference for a simple solo task.

## Primary and selected model identity

Use GPT-6.2 Sol in the primary session. High is the default for business decisions,
architecture and risk; Medium can handle straightforward work, and Extra High is
an evidence-based escalation. A skill cannot switch the primary model or effort.
Check identity once when runtime metadata exposes it, and again after a change.
If the primary differs, report it and recommend GPT-6.2 Sol without claiming a
switch occurred. Missing primary metadata is reported once as unverified; it does
not block independent authorized work or require repeated user confirmation.
Selected workers and reviewers still require verified role/model/effort before
their results are accepted. Configuration alone is not proof of runtime identity.

## Declare the route before task tools

Before the first task tool call, emit one machine-auditable declaration:

~~~text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <task-specific reason, including why delegation saves total usage if selected>
~~~

No task tool call may precede this declaration. Solo is the default for small or
strongly coupled work where a handoff would cost more than direct execution.
Otherwise actively look for bounded work that Luna or Terra can complete more
cheaply. If newly observed evidence changes the implementer or review need,
declare the revised route and reason. Never silently omit a promised review.

## Choose the least-cost complete route

- `solo`: root plans, implements, verifies and self-reviews; spawn no auxiliary.
- `delegate`: one worker or 2-3 independent lower-cost auxiliaries execute settled
  tasks. Use Luna / High for routine coding, exploration, tests, logs and repeatable
  transformations; Luna / Max only for fully specified deep technical work; Terra /
  High for writing, images, visual checks and authorized app operation. Root
  integrates and verifies; do not request a fresh review by default.
- `audit`: root handles the judgment-heavy implementation and verification; a fresh
  read-only GPT-6.2 Sol / High reviews the accumulated diff. Independent read-only
  helpers may run in parallel; spawn no implementation worker on this route.
- `full`: bounded workers implement settled parts, root handles decisions and
  integration, then a fresh read-only GPT-6.2 Sol / High reviews. Choose this when
  both delegation and independent review are needed, including high-risk tasks
  with separable routine work. Do not transfer unsettled or risky decisions.

There is no one-worker default maximum. Choose concurrency from independent work,
expected total usage and available capacity: up to min(3, runtime capacity excluding
the root), counting helpers and reviewers. Use waves for more tasks; do not spawn
nested agents. Assign disjoint write ownership and settle shared interfaces before
parallel edits. Serialize dependent writes, shared mutable tests and UI operation.
Wait for all writes before final integration checks and the final review.

Auxiliary work must substitute for root work, not duplicate it. Let a worker read
and analyze its owned area instead of having Sol do the same exploration first.
Give it only the context needed for the task. Reuse an existing worker for a related
follow-up within the same task, role, ownership and authorization; start a fresh
worker when those boundaries or the required independence change.

Return ambiguity, architecture changes and material risk to Sol for a decision.
Pause only the affected part; settled independent work may continue. Sol owns the
risky decision or implementation, rather than automatically taking back every
routine subtask. Correct a faulty specification before retrying; do not cycle
through models blindly. Escalate Luna High to Max only for an evidenced bounded
technical need, and keep review commitments when changing routes.

## Check selected roles without repeating setup

Use the shipped role TOMLs as the model/effort source of truth. Check only selected
roles; solo requires no auxiliary preflight. Reuse a successful template check
within the same primary session while the installation, templates and installed
role configuration remain unchanged, including across tasks. Recheck only affected
roles after a change or when validity is uncertain. Do not rerun the full installer
or maintainer verifier for an ordinary development task.

Verify each spawned agent's runtime role/model/effort once before accepting its
result. Public metadata is authoritative; use the local inspector only for missing
fields. Reuse unchanged identity evidence for follow-ups. Missing, conflicting or
unavailable worker evidence stops that lane's acceptance, not unrelated work. Never
silently substitute a model or omit a required review.

## Model responsibilities and specialty boundary

| Model / effort | Responsibility |
|---|---|
| GPT-6.2 Sol / High | Primary decisions, architecture, risky implementation, integration and acceptance |
| GPT-6 Luna / High | Bounded coding, exploration, tests, logs and transformations |
| GPT-6 Luna / Max | Exceptional deep technical implementation within settled architecture |
| GPT-6.1 Terra / High | Writing, images, visual/interaction checks and authorized app operation |
| Fresh GPT-6.2 Sol / High | Read-only final code review for audit/full |

Do not use GPT-6.2 Astra or any Astra model in this workflow for now: no automatic
spawn, fallback or manual-upgrade recommendation. Revisit only if the user changes
this constraint. Prefer Standard speed; use paid faster modes only when explicitly
requested. Do not hardcode token prices into routing: use the applicable billing
rates and compare total usage including retries.

Terra visual checks do not replace Sol code review. Confirm its required inputs,
tools and authenticated surfaces. Prefer connected APIs/tools before UI automation;
keep one operator on a shared browser/desktop. Tool access does not authorize
messages, publishing, deployment, purchases, deletion or permission changes: carry
explicit user authorization into the task. Report unreadable or uncertain details.

## Worker contract and parent verification

Each worker receives a concise five-part specification: OBJECTIVE, FILES AND
OWNERSHIP, INTERFACES, CONSTRAINTS, VERIFICATION, plus the structured return in
[role contracts](references/role-contracts.md). State exact ownership, preserve
concurrent edits, and do not silently widen scope. Use short sections for small
tasks; do not create a separate plan or report file just to satisfy the template.

Root inspects the complete actual diff and owns final integration and acceptance;
workers own local checks. Reuse passing evidence when the command, relevant tested
inputs/configuration/runtime, exit status and key output are available and still
match. Rerun only affected checks after fixes, failures, missing evidence or new
risk. A new operator, stage or task name alone does not invalidate a result.
Use file hashes when needed to establish input identity, not as a mandatory ledger
for every trivial edit. Never claim mocks or local-only checks prove integration.

## Review only when the route includes it

For audit/full, begin final review in a fresh GPT-6.2 Sol / High context after parent
verification. The reviewer remains read-only, inspects accumulated changes and
returns exactly ship, fix-first or rethink; it never implements its findings.
`solo` and `delegate` do not receive a fresh reviewer without a newly declared,
risk-evidenced escalation. Parallelism alone does not require review.

- ship: accept only with applicable verification evidence.
- fix-first: audit: the root implements the required correction and verifies it;
  full: the selected implementer handles a correction within the settled spec.
  If Sol has taken over the affected implementation, the root handles it. Obtain
  a new verdict after correction; never accept the stale verdict.
- rethink: revise the architecture; do not report completion.

For bounded ordinary corrections with unchanged scope, interfaces and risk, reuse
the same reviewer with the correction diff and updated evidence. Do not repeat
unrelated review or passing tests. Use a new fresh reviewer for high-risk changes,
changed architecture/interfaces/scope, uncertain prior context or required
independence. Security, tenant isolation, money, irreversible data operations and
external side effects remain high-risk boundaries. Follow the observed isolation
rules in operations.md; never claim enforced read-only isolation without evidence.
