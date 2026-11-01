# Session 2 — Understanding Partner's Task 2

**Related AI_USAGE entry:** Conversation 2
**Tool / model / date:** Anthropic Claude (Claude Code, VS Code; Claude Opus) — November 1, 2026

## Goal
Understand what Task 2 demonstrates, how its files and commands relate to Task 1, and which findings provide context for Tasks 3 and 4.

## Prompt / discussion topic
> Explain how the `legacy-parser` OpenClaw skill and the adversarial webpage work, and how they map to the four-step chain, so I understand the context for my confinement work in Task 4.

## Discussion notes
- Clarify the objective of Task 2 and its relationship to the Task 1 binary.
- Explain the skill's path restriction and how it acts as a policy boundary.
- Explain how the adversarial page steers the agent.
- Identify what the saved trace shows.

## AI response summary
Claude explained that the skill (`skills/legacy-parser/`) wraps the vulnerable binary and restricts its argument to files under `inbox/`, which is the access-control boundary checked at the "policy decision" step. `web/adversarial.html` hides an instruction inside a `display:none` div — an indirect prompt injection — so untrusted page text is treated as instructions. `web/output.txt` is the saved trace that walks the four-step chain (untrusted content enters context → agent proposes a tool call → policy permits it → native program contains the overflow).

## What I checked independently
- Files/artifacts reviewed: `skills/legacy-parser/SKILL.md`, `skills/legacy-parser/run_parser.sh` (the `inbox/` path check), `web/adversarial.html` (hidden div), `web/output.txt` (trace).
- I confirmed the four steps in the trace matched the report's description.

## Outcome
I understood how the inbox-path policy boundary works, which is the same access-control idea my Task 4 confinement extends at the OS level. I did not claim authorship of my partner's work.
