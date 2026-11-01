# Session 8 — Final Verification and Screenshot Review

**Related AI_USAGE entry:** Conversation 8
**Tool / model / date:** Anthropic Claude (Claude Code, VS Code; Claude Opus) — November 1, 2026

## Goal
Use the assignment requirements to check whether the collected evidence supports the claims in the Task 3 and Task 4 report sections, and assemble the screenshots.

## Prompt / discussion topic
> Here are my VM screenshots and outputs. Check them against the Task 3 and Task 4 requirements, flag anything missing or inconsistent, and don't invent results.

## Evidence review

| Area | Command / artifact inspected | Actual result | Evidence filename |
|---|---|---|---|
| Task 3 build | `gcc ... -Werror -o legacy_log_parser_fixed ...` | clean compile | — |
| Task 3 tests | `bash tests/run_tests.sh` | 6 passed, 0 failed | `03_task3_checksec_tests.png` |
| Hardening checks | `checksec --file=./legacy_log_parser{,_fixed}` | fixed = Full RELRO/Canary/PIE/FORTIFY(2) | `01_...png`, `03_...png` |
| DAC experiment | `sudo -u agentlab ./src/legacy_log_parser ./inbox/log.bin` | decoy read denied by DAC | `04_task4_runA_agentlab.png` |
| AppArmor denial | `sudo ./src/legacy_log_parser ...`; `ausearch -m AVC` | `dac_override`/`dac_read_search` DENIED, `exit=-13` | `05_...png`, `06_...png` |
| Git/submission state | `git status`, `git ls-remote origin` | in sync with origin | — |

## AI response summary
The review flagged: (1) the first GDB capture was unusable because it was run from the wrong directory, so the program exited normally instead of crashing — discarded; (2) a leftover `/home/ubuntu/.../hw3/` path in `SKILL.md` — fixed; (3) the `checksec` values and test counts in the report matched the screenshots.

## My final checks
- [x] Source files submitted are the files actually built and tested.
- [x] Report claims match the terminal output and screenshots.
- [x] Screenshots are genuine captures from my VM session.
- [x] Failed/inconclusive attempts are disclosed (the broken GDB run).
- [x] Final Git state contains intended files; build artifacts are `.gitignore`d.

## Outcome
I selected the five relevant screenshots, dropped the broken GDB capture and a duplicate, corrected the `SKILL.md` path, and recreated `report.tex` so the PDF can be rebuilt.
