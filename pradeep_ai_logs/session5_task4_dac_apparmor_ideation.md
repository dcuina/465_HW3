# Session 5 — Ideating the Task 4 DAC/AppArmor Approach

**Related AI_USAGE entry:** Conversation 5
**Tool / model / date:** Anthropic Claude (Claude Code, VS Code; Claude Opus) — November 1, 2026

## Goal
Understand the Task 4 access-control requirements and plan experiments that distinguish DAC behavior from AppArmor behavior.

## Prompt / discussion topic
> Help me design the DAC user and the AppArmor profile for the vulnerable parser, mapping each profile rule to the five requirements, and design experiments that distinguish a DAC denial from an AppArmor denial.

## Discussion notes
- DAC is set by the file owner (ownership + permission bits); MAC (AppArmor) is a system policy bound to the program that even root cannot override.
- The parser needs: execute the binary, read `inbox/`, write `markers/`. It must NOT read the decoy or execute shells.
- To isolate the layers: run as `agentlab` (DAC blocks the decoy) and run as root (DAC would allow, so only AppArmor can deny).

## AI response summary
Claude proposed the no-login `agentlab` user with minimal permissions, an AppArmor profile whose rules map one-to-one to the five requirements, and the two-run experiment design. It noted that a generic "Permission denied" does not by itself prove an AppArmor denial, so the experiment must separate the layers.

## My design decisions
- User/group: no-login system user `agentlab` (own group).
- Permissions: `750` binary (group `agentlab`), `750` inbox dir / `640` inbox files, `770` markers; decoy stays root-only `600`.
- AppArmor rules: `r` on `inbox/` and `inbox/*`; `rw` on `markers/` and `markers/*`; `audit deny /opt/agentsec/decoy.txt rwklx`; `audit deny` shells/other programs; `#include <abstractions/base>` + `mr` on the binary; no capabilities.
- Each rule maps to exactly one of the five requirements (see report Table 2).

## Outcome
I had a confinement design where both layers independently stop the decoy read, plus a plan to demonstrate each layer separately.
