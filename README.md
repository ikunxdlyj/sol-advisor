# Sol Advisor

**GPT-6.2 Sol / High runs the show. Minimize total usage per accepted task: let
lower-cost Luna/Terra workers execute bounded work, in parallel when useful.**

Sol Advisor is a Codex-only workflow for capability-routed software delivery. You
bring the goal and constraints; Sol owns the plan, implementation or delegation,
verification, and acceptance. Cost includes planning, context, review and retries;
agent count alone is not the optimization target.

## Go deeper

I write [**Attention Heads**](https://attentionheads.substack.com/?utm_source=github&utm_medium=readme&utm_campaign=sol-advisor) — deep, evidence-backed writing on AI, cognition, and agentic engineering. The **Agentic Engineering Field Notes** series is where I publish practical advice on the craft of using AI. [Subscribe](https://attentionheads.substack.com/subscribe?utm_source=github&utm_medium=readme&utm_campaign=sol-advisor) to get new posts to your inbox.

## Quick start

You need a current Codex CLI or ChatGPT desktop app with plugins enabled, GPT-6.2
Sol / High for the primary session, native custom-agent support, and jq. GPT-6
Luna / High, Luna / Max, or GPT-6.1 Terra / High access is needed only for its selected lane; Terra requires CLI 0.159.0+ when using the CLI.

~~~sh
codex plugin marketplace add ikunxdlyj/sol-advisor --ref main
codex plugin add sol-advisor@sol-advisor
plugin_dir="$(codex plugin list --json | jq -r '.installed[] | select(.pluginId == "sol-advisor@sol-advisor") | .source.path')" && test -n "$plugin_dir" && test "$plugin_dir" != null && test -d "$plugin_dir" && test -f "$plugin_dir/scripts/install-agents.sh" && sh "$plugin_dir/scripts/install-agents.sh"
~~~

The companion installer verifies all four exact role files after installation and
migrates exact earlier Sol Advisor roles. It is fail-closed: modified, unsafe,
nonregular, symlinked, unknown, or differing files are left untouched. It does not
edit Codex configuration. Start a fresh Codex task after installation so native roles
are discovered.

Use this one prompt in the new task:

~~~text
Use $sol-advisor:orchestration to build this feature and verify it. Declare the selective route before task tools.
~~~

## What you do

Give Sol the outcome, constraints, and any important repository context. You do not
need to select or manage a lane; Sol records the route and owns verification and
acceptance.

## Routes

| Mode | Use it when | Delivery |
|---|---|---|
| `solo` | Small or coupled work where handoff costs more than direct execution. | Root plans, implements, tests, and self-reviews. |
| `delegate` | Bounded work with settled interfaces and acceptance criteria. | One worker or 2-3 independent auxiliaries: Luna / High for coding, exploration, tests or logs; Luna / Max for deep technical work; Terra for specialty work. Root integrates and verifies. |
| `audit` | Ambiguous, judgment-heavy, or high-risk implementation needs fresh scrutiny. | Root implements, optionally with independent read-only helpers; a fresh GPT-6.2 Sol / High reviews. |
| `full` | Broad or high-risk work needs bounded delegation and independent review. | One worker or 2-3 independent auxiliaries, root integration/verification, then a fresh GPT-6.2 Sol / High review. |

Terra visual checks supplement Sol's code review. GPT-6.2 Astra and other Astra models are excluded for now.
Solo is the default for small tasks. There is no one-worker default maximum: independent tasks may use 2-3 concurrent auxiliaries within the
session limit, with disjoint write ownership and settled shared interfaces. Overlapping
writes and dependent tasks run sequentially; parallelism alone does not require `full`.
Sol emits a `SELECTIVE ROUTE` declaration with the mode and concise risk
rationale before the first task tool call. If newly observed evidence changes who
should implement or whether review is needed, Sol declares the revised route and
reason. It never silently omits a promised review.

## What happens automatically

GPT-6.2 Sol / High keeps architecture, decomposition, route selection, parent verification,
escalation decisions, and acceptance in the primary task. Ambiguous or materially
risky implementation decisions stay with GPT-6.2 Sol / High; settled routine work can
continue with workers. Auxiliary work substitutes
for root work; it does not duplicate it. Workers own local checks; the root inspects the
combined diff and owns final integration coverage. Passing evidence is reused only when
the tested inputs, configuration and runtime still match; changed or uncertain inputs
require affected checks to rerun. Reviews start with a fresh GPT-6.2 Sol / High.
Every fix invalidates its verdict; ordinary bounded corrections reuse the reviewer and
obtain a new verdict. High-risk, interface or scope changes require a new fresh reviewer.
Selected-role preflight is reused within an unchanged primary session; worker
follow-ups reuse verified identity. Do not repeat passing checks for a new stage
or operator. Standard speed is the default.

## Updating

Update the marketplace plugin, reinstall the companion roles, and start a new task:

~~~sh
codex plugin marketplace upgrade sol-advisor
codex plugin add sol-advisor@sol-advisor
plugin_dir="$(codex plugin list --json | jq -r '.installed[] | select(.pluginId == "sol-advisor@sol-advisor") | .source.path')" && test -n "$plugin_dir" && test "$plugin_dir" != null && test -d "$plugin_dir" && test -f "$plugin_dir/scripts/install-agents.sh" && sh "$plugin_dir/scripts/install-agents.sh"
~~~

For exact spawn, runtime-evidence, sandbox, installer, and maintainer verification
details, read [advanced native operations](plugins/sol-advisor/skills/orchestration/references/operations.md).
For local development, install this checkout as a marketplace:

~~~sh
cd /absolute/path/to/sol-advisor
codex plugin marketplace add /absolute/path/to/sol-advisor
codex plugin add sol-advisor@sol-advisor
~~~
