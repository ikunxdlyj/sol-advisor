# Native Codex role contracts

Use these contracts with Sol Advisor's namespaced, role-pinned native custom agents.
They do not launch a nested Codex CLI or change global default-agent routing. Keep packets concise and complete the relevant placeholders without redundant context.

For task-scoped preflight, runtime evidence, sandbox interpretation, and maintainer
commands, use [operations.md](operations.md).

## Selective route and required preflight

Before the first task tool call, the root emits one machine-auditable route:

~~~text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <concise, task-specific rationale>
~~~

Minimize total usage per accepted task, including planning, context, review and
retries. Solo is the default for small or coupled tasks; explicitly delegate independent work
to 2-3 concurrent auxiliaries when beneficial. Full is a broad or high-risk review
choice when independent review is needed, not a requirement for parallel work. Declare changes of ownership or review commitment with
the newly observed evidence. Never silently omit a promised review.

Use GPT-6.2 Sol as primary; check available identity once, report missing primary
identity once as unverified, and continue independent authorized work. Preflight
only selected worker/reviewer roles. Reuse successful template checks across tasks
within the same unchanged primary session; invalidate after installation, template
or installed-role changes, a new primary session, or uncertain validity.
After spawning, complete every agent's
routing and reviewer-isolation checks before accepting the result:

1. Require the selected exact native role and fresh-context spawn contract.
2. Observe the selected role, model, and effort through public spawn/details metadata
   first, using the local runtime inspector only for omitted fields. Accept Luna /
   High for routine delegate/full implementation, Luna / Max only for bounded,
   fully specified deep technical work, Terra / High for bounded specialty work,
   and GPT-6.2 Sol / High for audit/full review.
3. For the reviewer, capture actual sandbox policy and permission profile types.

Before parallel work, assign disjoint write ownership, settled shared interfaces,
dependencies and verification owners. Cap all concurrent auxiliaries at three or the
smaller runtime capacity excluding the root; include helpers and reviewers. Workers
must not spawn nested agents. Serialize overlapping writes and shared mutable test/UI
resources, and wait for all writes before final integration checks and review.

A missing, stale, unsafe, conflicting, unavailable, inconsistent, or unobservable
role/model/effort stops the native lane. Never silently fall back. Model and effort
are pinned by custom-agent TOML, so omit native per-spawn overrides.

## Shared implementation contract

Every Luna / High, Luna / Max, or Terra / High prompt must contain all five sections:

~~~text
OBJECTIVE
<Observable outcome and why it matters.>

FILES AND OWNERSHIP
You own only:
- <exact file or module>

You are not alone in the codebase. Other agents or the user may be editing concurrently.
Preserve their edits, do not revert unrelated work, and adapt to changes already present.
Do not modify files outside your ownership.

INTERFACES
- <Signatures, types, schemas, commands, or behavior that must remain compatible.>

CONSTRAINTS
- <Repository conventions, safety boundaries, excluded scope, and settled decisions.>

VERIFICATION
- Run: <exact command>
  Success: <concrete expected result>
- Inspect: <exact file, diff, or generated artifact>
  Success: <concrete expected evidence>
- Ownership: <local checks this worker owns; integration checks owned by the root>
- Evidence: <tested input snapshot including relevant config/dependencies, runtime,
  exit status and output/artifacts; identify shared mutable resources to serialize>

RETURN
Return exact commands and actual evidence. A completion claim without evidence is invalid.
Do not start nested agents or modify files outside your ownership.

IMPLEMENTATION REPORT
STATUS: complete | partial | blocked
OBJECTIVE: <one-line restatement>
CHANGES: <file-by-file summary from the actual diff>
VERIFIED: <exact commands plus concrete output evidence>
JUDGMENT CALLS: <decisions the specification left open, or none>
GAPS: <unfinished work, ambiguity, or none>
~~~

The primary session inspects the combined diff, validates evidence and owns final
integration coverage. Reuse passing checks with inspectable command, relevant tested
inputs/configuration/runtime, exit status and key output/artifacts
that still apply. Rerun affected checks after changed/uncertain inputs, failures, missing
evidence or new risks. Do not rerun unchanged local checks solely to change who ran them.
Use the verification ledger and invalidation rules in operations.md.

## Exact mode contracts

- `solo`: root plans, implements, tests, and self-reviews. Spawn no auxiliary.
- `delegate`: one worker or 2-3 independent auxiliaries each execute a complete five-part
  specification. Luna / High handles bounded routine implementation, exploration,
  tests or logs; use Luna / Max only for bounded, fully specified deep technical
  work, or Terra / High for bounded writing, visual checks and authorized app operation.
  The root integrates and verifies. Do not spawn a fresh reviewer by default.
- `audit`: root implements and verifies. A fresh read-only GPT-6.2 Sol / High reviewer inspects
  the accumulated diff. Prefer it for ambiguity, material risk, or judgment-heavy work.
  Spawn no implementer; independent read-only helpers may run in parallel.
  On `fix-first`, the root implements the correction, updates affected verification,
  and follows the reviewer reuse gate below.
- `full`: use only for an explicit broad or high-risk exception with settled architecture
  and acceptance criteria. One worker or 2-3 independent Luna/Terra auxiliaries execute
  their complete specifications, the root integrates and verifies, and a fresh read-only GPT-6.2 Sol / High
  reviewer inspects the accumulated diff.
  On `fix-first`, the selected implementer handles a correction within the settled
  spec; if GPT-6.2 Sol / High has taken over implementation, the root handles it. The root
  updates affected verification and follows the reviewer reuse gate below.

Auxiliary work substitutes for root work; it must not duplicate it. If a worker reveals
unsettled architecture, ambiguity, or material risk, pause that part for a Sol decision.
Sol owns risky implementation; independent settled work can remain with workers.
Declare the changed route and evidence. Never silently omit review commitments.
Solo and delegate have no fresh reviewer or review-driven correction unless a newly
observed, risk-evidenced route escalation is declared; never silently add one.

## Luna / High - default bounded delegate/full implementation lane

Use this lane for bounded, fully specified work. The installed role pins GPT-6 Luna
at high reasoning. It must surface ambiguity and failed checks rather than redesigning
the architecture. A first result showing only a need for deeper technical reasoning
may justify Luna / Max. Judgment-heavy or high-risk decisions return to GPT-6.2 Sol / High.
If the specification itself was incomplete or wrong, correct it before another attempt.
Reuse a worker for related follow-ups in the same task with unchanged role, ownership
and authorization; reuse verified runtime identity until those settings change.

Spawn exactly:

~~~text
agent_type: sol_advisor_luna_implementer
fork_turns: none
~~~

Do not attach per-spawn model or reasoning fields. Prompt:

~~~text
ROLE
Act as Sol Advisor's default routine implementation worker. Execute the supplied
specification within the settled architecture, preserve every stated interface and
constraint, and surface ambiguity instead of redesigning the architecture.

<paste and complete the Shared implementation contract>
~~~

## Luna / Max - exceptional deep technical implementation lane

Use this lane only when a declared delegate or full route selects bounded, fully
specified work whose technical depth justifies extra reasoning time and usage. The
installed role pins GPT-6 Luna at max reasoning. Do not use it to transfer unsettled
architecture, ambiguous requirements, or material risk away from GPT-6.2 Sol / High.

Spawn exactly:

~~~text
agent_type: sol_advisor_luna_max_implementer
fork_turns: none
~~~

Do not attach per-spawn model or reasoning fields. Prompt:

~~~text
ROLE
Act as Sol Advisor's exceptional deep-reasoning worker. Execute the bounded,
fully specified work within the settled architecture, preserve every stated interface
and constraint, and return ambiguous or high-risk decisions to GPT-6.2 Sol / High.

<paste and complete the Shared implementation contract>
~~~

## Terra / High - bounded specialty execution lane

Use GPT-6.1 Terra / High for clear writing, understanding images, charts or
screenshots, visual and interaction checks, or explicitly authorized browser and
desktop operations. Visual findings supplement parent verification; this worker
does not replace the fresh Sol code reviewer or decide architecture and material risk.

Spawn exactly, after the `terra-high` companion check:

~~~text
agent_type: sol_advisor_terra_specialist
fork_turns: none
~~~

Do not attach per-spawn model or reasoning fields. Prompt:

~~~text
ROLE
Act as Sol Advisor's Terra specialty worker on gpt-6.1-terra / high. Execute the
bounded task and return evidence for the primary session's acceptance.

<paste and complete the Shared implementation contract>

SPECIALTY SCOPE
- Inputs and references: <exact images, sources, documents or screenshots>
- Authorized surfaces and actions: <exact apps, accounts and permitted changes>
- Required tools and access: <verify in this lane; stop if unavailable>
- Shared UI ownership: <one operator; no concurrent browser/desktop interaction>
- Prefer a suitable connected API/tool before UI automation.
- Tool availability is not permission to send messages, publish, deploy, purchase,
  delete or change account permissions; require explicit user authorization.
- Mark unreadable details and uncertain values instead of guessing.
- Return source references, observed state/artifacts, actions taken, checks and gaps.
- Return material ambiguity, architectural changes and risk decisions to the parent.
~~~

## Astra - excluded for now

Do not use GPT-6.2 Astra or any Astra model, including manual-upgrade recommendations
and fallback routing, unless the user changes this constraint.

## Fresh GPT-6.2 Sol / High - requested-read-only audit/full reviewer

Only for an audit or full route, after parent verification, start the initial review in a new native thread
exactly:

~~~text
agent_type: sol_advisor_sol_reviewer
fork_turns: none
~~~

The installed role pins GPT-6.2 Sol / High and requests a read-only sandbox. Do not attach
per-spawn model or reasoning fields. Observe the actual role, pin, sandbox policy, and
permission profile before accepting its verdict.

Prompt:

~~~text
ROLE
Act as the fresh final reviewer. Remain strictly read-only: do not edit files, implement
fixes, or broaden scope.

STATED GOAL
<The user's requested outcome.>

ACCUMULATED CHANGE SET
<Exact allowed files plus complete working-tree diff, or explicit base/head revisions.>

INTERFACES AND CONSTRAINTS
- <Compatibility, repository rules, safety boundaries, and excluded scope.>

VERIFICATION EVIDENCE
- <command> -> <actual primary-session output evidence>
- <artifact or diff inspection> -> <actual evidence>

REVIEW
Inspect the actual files and accumulated change set. Judge correctness, completeness,
regressions, scope discipline, interface preservation, test adequacy, and material risk.
For a permitted correction follow-up, inspect the correction and affected context against
the current accumulated state and updated evidence. Issue a new verdict; do not implement fixes.

SOL REVIEW
VERDICT: ship | fix-first | rethink
REASON: <decisive evidence-based reason>
FINDINGS: <precise file references and required fixes, or none>
RESIDUAL RISK: <most important remaining risk, or none>
~~~

If any fix is made after review, discard the verdict. Reuse the same read-only reviewer
only for a bounded ordinary correction with unchanged scope, interfaces and risk,
and no high-risk boundary involved;
send a follow-up with the correction diff, current accumulated state and updated evidence,
and require a new verdict. Use a new fresh reviewer for high-risk changes or corrections,
architecture/interface/scope changes, unavailable or uncertain review context, or a
required independent review. Security, tenant isolation, money, irreversible data
operations and external side effects remain high-risk boundaries. Fresh review covers
the accumulated change; reviewer reuse does not relax runtime or read-only state checks.
GPT-6.2 Sol reviewing GPT-6.2 Sol is context-clean, not cross-model-family independence.

Use observed isolation, not requested isolation:

- With observed `read-only`, proceed with enforced isolation.
- If the host broadens it, proceed only when hard isolation is not required, the
  prompt forbids edits, and the parent captures and verifies exact before-and-after
  repository and artifact state. Report the broader policy and profile.
- If isolation is unobservable, hard isolation is required, or any mutation occurs,
  stop the lane and do not hide or repair the mutation under that verdict.
