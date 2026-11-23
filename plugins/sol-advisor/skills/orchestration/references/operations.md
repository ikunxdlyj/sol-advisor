# Native operations

This is the maintainer and operator reference for Sol Advisor's native custom-agent
workflow. Keep the README user-facing; use this page when installing, delegating,
inspecting routing, or validating a release.

## Role pins and spawn contract

The installed TOMLs are the source of truth:

| Role type | Model | Effort | Use |
|---|---|---|---|
| sol_advisor_luna_implementer | gpt-6-luna | high | Delegate/full bounded routine implementation |
| sol_advisor_luna_max_implementer | gpt-6-luna | max | Delegate/full bounded, fully specified deep technical work |
| sol_advisor_terra_specialist | gpt-6.1-terra | high | Delegate/full bounded writing, visual checks and authorized app operation |
| sol_advisor_sol_reviewer | gpt-6.2-sol | high | Audit/full fresh review; requests read-only sandbox |

Native spawn requests name the role and use a fresh context:

~~~text
agent_type: sol_advisor_luna_implementer
fork_turns: none
~~~

Use the Luna Max type only when the selected delegate or full route needs extra
technical reasoning within a settled specification:

~~~text
agent_type: sol_advisor_luna_max_implementer
fork_turns: none
~~~

Use Terra for a bounded specialty task, after checking `terra-high`:

~~~text
agent_type: sol_advisor_terra_specialist
fork_turns: none
~~~

The selected lane must have its required tools, inputs and authenticated surface.
Prefer a suitable connected API/tool before UI automation and keep one operator
per shared browser or desktop. App access does not authorize external actions;
carry the user's exact authorization into the worker packet and report evidence.
GPT-6.1 Terra requires Codex CLI 0.159.0 or later when using the CLI. Verify the
model is available to the current client/account before accepting runtime results.
GPT-6.2 Astra and other Astra models are excluded for now. Do not install, spawn,
recommend or use them as a fallback unless the user changes this constraint.

Use a fresh GPT-6.2 Sol reviewer only for audit or full after parent verification:

~~~text
agent_type: sol_advisor_sol_reviewer
fork_turns: none
~~~

This is the initial review spawn. For a later bounded ordinary correction, use a
follow-up to the same reviewer under the review gate below instead of spawning again.

Do not attach model or reasoning overrides. A missing, conflicting, unavailable, or
unobservable role/model/effort is a hard stop; never substitute another role.

## Selective route declaration, preflight, and caching

Use GPT-6.2 Sol as primary, normally High for decisions and business risk. Check
exposed runtime identity once and after changes; report missing identity once as
unverified without blocking independent authorized work. See SKILL.md for effort
selection. Companion installation is separate because plugin installation does
not register user-owned TOMLs.

At installation or update time, run the repository-relative installer and its exactness
check:

~~~sh
sh plugins/sol-advisor/scripts/install-agents.sh
~~~

When operating from an installed skill, resolve the same script relative to this
reference's parent skill:

~~~sh
skill_dir=<directory-containing-this-SKILL.md>
installer="$skill_dir/../../scripts/install-agents.sh"
sh "$installer" --check
~~~

The installer is fail-closed and performs its own post-install exactness check. It
recognizes only byte-exact historical templates, including the shipped v0.2.0,
v0.5.0, v0.6.0, v0.7.0, and v0.8.0 profiles. The v0.8.0 upgrade changed the routine
Luna pin to High, installed the bounded deep-work Luna / Max role, and retired the
old Luna High role name only when that installed file was byte-exact. The v0.9.0
upgrade refreshed the reviewer pin and recognized both LF and CRLF copies of the
v0.8.0 reviewer role.
The v0.10.0 update added `sol-advisor-terra-specialist.toml` without reusing the
retired `sol-advisor-terra-implementer.toml` name. The historical `terra` check alias
still checks Luna Max; `terra-high` checks GPT-6.1 Terra / High.
The v0.11.0 update pins the reviewer to GPT-6.2 Sol / High and refreshes cost-aware
worker instructions. Exact LF and CRLF v0.10.0 roles migrate safely; customized
roles are never overwritten.
Modified, unsafe, nonregular, symlinked, or conflicting destinations remain refusals,
and all mutations are preflighted.

The root emits one machine-auditable declaration before its first task tool call:

~~~text
SELECTIVE ROUTE
mode: solo | delegate | audit | full
risk: <concise, task-specific rationale>
~~~

Solo is the default for small or coupled tasks. Explicitly delegate independent work
to 2-3 concurrent auxiliaries when this improves delivery; there is no one-worker default maximum. Compare root planning, worker execution,
integration and expected retries against direct Sol execution. Full is selected
when both bounded delegation and independent review are needed, not as a parallelism gate.
If newly observed evidence changes the implementer or review
need, the root declares the revised route and reason. It never silently omits a
promised review.

The existing --check flag verifies all four roles. For task-scoped preflight, check
only the auxiliaries selected by the declaration; every check is non-mutating and
fail-closed:

| Route | Required companion checks |
|---|---|
| solo | None |
| delegate | Selected worker roles: `--check-role luna-high`, `luna-max`, or `terra-high`; combine flags for mixed roles |
| audit | `--check --check-role sol`, plus any selected read-only helper roles |
| full | Selected worker roles plus `--check-role sol` |

Check each distinct selected role once per unchanged primary session, not once per
agent or task. Multiple Luna High workers share a successful template preflight.
Verify every spawned agent's runtime role/model/effort once; reuse it for follow-ups
unless identity, configuration, permissions or required isolation change.

For example:

~~~sh
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role luna-max
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role terra-high
sh plugins/sol-advisor/scripts/install-agents.sh --check --check-role sol
~~~

Unknown or missing role arguments fail before any destination mutation. A selective
check ignores unselected role destinations, while the all-role --check behavior
remains unchanged. Reuse successful checks in the same primary session, including
across tasks, while the installation, shipped templates and installed roles remain
unchanged. Recheck affected roles after changes or uncertainty, and newly selected
roles after a route change. Never carry the cache across primary sessions. Do not
run all-role checks or the maintainer verifier during ordinary task setup.
A failed lane does not block unrelated valid work,
but do not silently substitute its model or omit its required deliverable/review.

## Parallel ownership and verification ledger

Use 2-3 concurrent auxiliaries only for tasks with settled interfaces, independent
inputs and disjoint write ownership. Include read-only code exploration, tests and
log analysis when their question and evidence requirements are bounded. Before
spawning, give each worker an owned file/module set, dependencies and verification
commands. Assign shared interface/configuration files to one owner. Run dependent or
overlapping work sequentially; do not run tests against files another agent is editing.

Cap all concurrent auxiliaries at min(3, available session capacity excluding the root).
Count read-only helpers and the reviewer too; workers must not spawn nested agents.
Use fewer workers or waves under smaller runtime limits. The root may implement an
independent owned task while workers run. Keep one operator per shared browser/desktop
and serialize checks that mutate the same database, fixture, output or service.
Collect each worker's changes and evidence, resolve conflicts, and wait for all writes
before final integration checks and review. Reuse workers for related follow-ups
within the same task, role, ownership and authorization. New boundaries or required
independence need a fresh worker. Reviewer reuse follows its stricter gate below.

Keep compact verification evidence in task context, not a new repository report:
command, relevant tested inputs/configuration/runtime, exit status and key output,
plus whether it covers local behavior or integration. Use content hashes or an
equivalent snapshot when input identity is uncertain; Git HEAD alone does not
identify dirty inputs. Do not build a full ledger for a trivial edit.

Workers run local checks. The root inspects the actual combined diff and available
evidence, and ensures final integration/acceptance coverage. Reuse passing results when
their evidence is inspectable and all relevant inputs still match; the final acceptance
check may also be reused only when it covers the final combined state. Do not rerun a
check solely because it was run by a worker. Rerun affected checks for changed/uncertain
inputs, failures, missing evidence, new risks or an explicit independent-run requirement.
Changes to shared configuration, dependencies or fixtures invalidate all checks that
depend on them. Broaden checks when the dependency boundary cannot be established.
Never treat assertions of success, mocks or local-only checks as integration evidence.

Luna / High is the default for bounded, fully specified work. Luna / Max is selected
only when the architecture and acceptance criteria are settled and technical depth
matters more than speed or usage. A Luna / High result may justify Luna / Max when
it reveals that narrow need. Ambiguity, material risk, or architecture changes require
a decision from GPT-6.2 Sol. Pause only the affected part, keep settled independent
work with its worker, and let Sol own risky implementation. Correct specification
errors before retries; do not blindly cycle through models.

If public metadata omits model or effort, use the local inspector below as a fallback
for those omitted fields only. Do not use it to replace available public evidence.

## Runtime routing evidence

The public spawn/details record is authoritative for the selected role and any exposed
model/effort. When model or effort is omitted, resolve the helper relative to the
installed skill and inspect the exact native thread ID:

~~~sh
skill_dir=<directory-containing-this-SKILL.md>
runtime_inspector="$skill_dir/../../scripts/inspect-agent-runtime.sh"
sh "$runtime_inspector" <native-subagent-thread-id>
~~~

For a disposable fixture or non-default session root:

~~~sh
sh "$runtime_inspector" --sessions-dir /absolute/path/to/sessions <native-subagent-thread-id>
~~~

The helper searches one exact rollout filename suffix and emits only allowlisted
routing fields. It refuses invalid IDs, zero/multiple matches, missing fields, or
conflicting model/effort/sandbox/permission/working-directory values. It never prints
prompts, messages, environment variables, tokens, configuration, or arbitrary rollout
payloads.

Accepted routing is Luna / high for routine bounded delegate/full implementation,
Luna / max for exceptional bounded deep technical work, Terra / high for specialty
execution, and GPT-6.2 Sol / high for audit/full
review. Judgment-heavy or high-risk decisions stay with the primary GPT-6.2 Sol.
If public and local evidence both exist, they must agree. The local inspector is not a
model-selection fallback.

## Read-only reviewer interpretation

The reviewer TOML requests sandbox_mode = read-only. Capture the observed sandbox
policy type and permission profile type from public metadata or the inspector:

- Observed read-only sandbox: isolation is enforced.
- Broader host policy: continue only when hard isolation is not required, the prompt
  forbids edits, and the parent captures exact before/after repository and artifact
  state. Report the broader policy and profile as residual risk.
- Unobservable isolation, required hard isolation, or any mutation: stop the review and
  do not claim read-only isolation.

A reviewer returns exactly ship, fix-first, or rethink. Every fix invalidates its old
verdict and requires updated verification evidence and a new verdict before acceptance.
For bounded ordinary fixes with unchanged scope, interfaces and risk, and no high-risk
boundary involved, send the same
read-only reviewer a follow-up with the correction diff, current accumulated state and
updated ledger. It checks the correction and affected context; do not repeat unrelated
full review or successful tests automatically. The reviewer never implements fixes.

Use a new fresh reviewer for high-risk changes or corrections, changed architecture,
interfaces or scope, unavailable/uncertain prior review context, or a required independent
review. Security, tenant isolation, money, irreversible data operations and external side
effects are high-risk boundaries. Fresh review covers the accumulated change, not only
the last patch. Recheck runtime identity and observed isolation when they change or
become uncertain; reviewer reuse never relaxes the read-only state checks above.

## Worker packet and parent acceptance

Every Luna / High, Luna / Max, or Terra / High prompt uses the five-part packet in role-contracts.md:

- OBJECTIVE
- FILES AND OWNERSHIP
- INTERFACES
- CONSTRAINTS
- VERIFICATION

It must also request the structured implementation report. The parent owns architecture,
complete diff inspection, evidence validation, final integration coverage, correction/escalation decisions, and
acceptance. Worker claims never replace direct inspection.

In solo, the root plans, implements, tests, and self-reviews with no auxiliary. In
delegate, one worker or 2-3 independent Luna/Terra auxiliaries complete settled specs;
the root integrates and validates evidence with no fresh reviewer by default. In audit,
the root implements, with optional independent read-only helpers, and verifies before
the initial fresh GPT-6.2 Sol review. In full, bounded workers complete their specs,
the root integrates and verifies, then the initial fresh GPT-6.2 Sol reviewer reviews.
Later corrections follow the review reuse gate above. If a worker reveals ambiguity or
material risk, Sol decides the affected part and keeps the promised review; settled
independent worker tasks continue. Auxiliary work
substitutes for root work; it does not duplicate it. A reviewer never fixes its own
findings.

## Maintainer verification

From the repository root, run:

~~~sh
sh plugins/sol-advisor/scripts/verify.sh
git diff --check
git status --short
git diff --stat
~~~

The verifier covers the v0.11.0 manifest, exact GPT-6-family four-role TOMLs,
selective-routing contracts, concise README journey, absence of retired active routes,
safe historical migration, installer refusal fixtures, Luna and Terra runtime evidence,
JSON/TOML validity, and shell syntax. This suite is for plugin maintenance, not
mandatory setup for every task using the skill.
