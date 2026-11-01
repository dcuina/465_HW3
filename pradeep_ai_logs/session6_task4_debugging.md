# Session 6 — Implementing and Debugging Task 4

**Related AI_USAGE entry:** Conversation 6
**Tool / model / date:** Anthropic Claude (Claude Code, VS Code; Claude Opus) — November 1, 2026

## Goal
Troubleshoot issues encountered while configuring DAC and AppArmor on the course VM.

## Prompt / discussion topic
> I'm setting up the agentlab user and the AppArmor profile on the VM and hitting a permission problem, and I'm not sure whether DAC or AppArmor is responsible. Help me separate the causes.

## Debugging record
### Issue 1 — agentlab cannot reach the binary
- Symptom: running as `agentlab` failed before any AppArmor record appeared.
- Hypothesis discussed: home directories are mode `750`, so `agentlab` cannot traverse into `/home/pradeep/...` to reach the binary.
- Diagnostic: checked the path with `namei -l` / `ls -ld` on each parent directory.
- Change made: `sudo setfacl -m u:agentlab:x /home/pradeep /home/pradeep/csce465-agentsec /home/pradeep/csce465-agentsec/465_HW3 /home/pradeep/csce465-agentsec/465_HW3/src` (traverse-only).
- Follow-up: `agentlab` could then execute the binary.

### Issue 2 — interpreting the root-run denial
- Symptom: as root the output showed "Marker created" then "Cannot resolve entire path: Permission denied"; `ausearch` showed capability denials, not a file-open denial.
- Root cause (confirmed): for an as-root access the kernel first checks whether the process may override DAC; the profile grants no capabilities, so `dac_override` / `dac_read_search` are DENIED and the read fails with `exit=-13` (EACCES). The marker is still written, so the exploit "succeeds" but MAC contains it.

## What I learned
- A generic `Permission denied` does not establish whether DAC or AppArmor caused it.
- The experiment must be designed so an earlier layer does not mask the layer under test (hence the agentlab vs root split).
- Audit records and execution context (`subj=`, `capname=`, `exit=`) are the real evidence.

## Outcome
Both runs worked as intended. Evidence: `screenshots/04_task4_runA_agentlab.png`, `05_task4_runB_denial.png`, `06_task4_ausearch_filtered.png`.
