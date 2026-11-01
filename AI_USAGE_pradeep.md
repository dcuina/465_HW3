# AI Usage Log — CSCE 465/765 HW3 (Tasks 3 & 4)

**Student:** Pradeep Periyasamy
**Scope of my work:** Task 3 and Task 4
**Partner's work:** Tasks 1 and 2
**AI tool / model:** Anthropic Claude (Claude Code, VS Code extension; Claude Opus)
**Dates used:** November 1, 2026

## Purpose and scope

I used AI (Claude) as a drafting, explanation, and troubleshooting aid while working on my part of HW3 (Tasks 3 and 4). Concretely, Claude helped me understand my partner's Task 1 and Task 2 work, draft the fixed/hardened parser and the test harness, design the DAC and AppArmor confinement, debug problems I hit on the course VM, and organize the Git repository and the report's screenshots.

All builds, tests, and confinement experiments were run by me inside the course VM (Ubuntu 24.04, VirtualBox). I captured every screenshot, reviewed the AI-drafted code before using it, and verified the outputs myself. Where Claude drafted code or text, I read it, tested it, and confirmed I can explain it; I am responsible for the final result. The raw session notes are in `pradeep_ai_logs/`.

Tasks 1 and 2 were completed by my partner, Daniel Cuina. I reviewed those tasks with Claude only to understand the starting point; I do not claim authorship of my partner's work.

---

## Conversation 1 — Reading and understanding my partner's Task 1

**Date:** November 1, 2026
**Purpose:** Understand the Task 1 vulnerable parser so I could build the fix in Task 3.

**Prompt / discussion topic:**

> Walk me through my partner's `legacy_log_parser.c`. Explain the input handling, the buffer operations, and exactly where and why the overflow reaches the saved return address, so I know what Task 3 has to fix.

**What I took away / checked myself:**

- The program reads the whole file into a heap buffer, closes it, then calls `vulnerable_copy()`, which `memcpy`s `n` bytes into a 128-byte stack buffer with **no check of `n` against `BUF_SIZE`** — that is the defect.
- The offset to the saved return address is `128 (buf) + 8 (saved RBP) = 136`; placing the address of `win()` at that slot redirects control flow on `ret` (ret2win).
- I confirmed `win()`'s address myself with `nm ./legacy_log_parser | grep ' T win'` → `0x4012b6`, which matches the value in `make_payload.py`.

---

## Conversation 2 — Reading and understanding my partner's Task 2

**Date:** November 1, 2026
**Purpose:** Understand how the agent-mediated invocation connects to the native bug.

**Prompt / discussion topic:**

> Explain how the `legacy-parser` OpenClaw skill and the adversarial webpage work, and how they map to the four-step chain, so I understand the context for my confinement work in Task 4.

**What I took away / checked myself:**

- The skill (`skills/legacy-parser/`) wraps the binary and restricts its argument to files under `inbox/` — this is the access-control boundary that the "policy decision" step checks.
- `web/adversarial.html` hides an instruction in a `display:none` div (an indirect prompt injection); `web/output.txt` is the saved trace.
- I read the skill, the HTML, and the trace to confirm the four-step chain described in the report.

---

## Conversation 3 — Ideating an approach for my Task 3

**Date:** November 1, 2026
**Purpose:** Decide the fix and the test strategy before writing code.

**Prompt / discussion topic:**

> Given the vulnerable parser, help me think through the Task 3 fix. I want to separate the one change that removes the vulnerability from the compiler options that only make exploitation harder, and decide the test cases.

**Ideas discussed and my decisions:**

- **Root-cause fix:** reject any input with `n > BUF_SIZE` *before* the copy. I chose to implement this as a `safe_copy()` wrapper that returns an error instead of copying.
- **Defense-in-depth (build flags):** stack canary, `_FORTIFY_SOURCE=3`, PIE/ASLR, Full RELRO, NX — I understood these raise the bar but do not remove the defect.
- **Tests:** valid short input, exactly 128 B, 129 B (one over), missing file, and the original 144-byte exploit payload, plus a check that no marker is written.

---

## Conversation 4 — Implementing Task 3 and the test harness

**Date:** November 1, 2026
**Purpose:** Produce `legacy_log_parser_fixed.c` and `tests/run_tests.sh`, then verify them.

**Prompt / discussion topic:**

> Draft the fixed parser with the bounds check, and a test script covering the five required cases. Explain the boundary condition so I can review it. Do not claim a test passed without my actual output.

**AI contribution:** Claude drafted `legacy_log_parser_fixed.c` (the `safe_copy()` bounds check) and `tests/run_tests.sh`.

**Implementation and verification performed by me (on the VM):**

- Build: `gcc -O2 -g -fstack-protector-strong -D_FORTIFY_SOURCE=3 -fPIE -pie -Wl,-z,relro,-z,now -Wl,-z,noexecstack -Wall -Wextra -Werror -o legacy_log_parser_fixed legacy_log_parser_fixed.c` — compiled clean under `-Werror`.
- Tests: `bash tests/run_tests.sh` → **6 passed, 0 failed**; the 144-byte payload was rejected with "input of 144 bytes exceeds the 128-byte buffer" and no marker was written.
- `checksec` on both binaries to build the comparison table.
- Evidence: `screenshots/03_task3_checksec_tests.png`.

---

## Conversation 5 — Ideating my Task 4 DAC/AppArmor approach

**Date:** November 1, 2026
**Purpose:** Design the two-layer confinement and the experiments that isolate DAC from MAC.

**Prompt / discussion topic:**

> Help me design the DAC user and the AppArmor profile for the vulnerable parser, mapping each profile rule to the five requirements, and design experiments that distinguish a DAC denial from an AppArmor denial.

**My design decisions:**

- **DAC (`policy/setup_user.sh`):** no-login `agentlab` user; `750` on the binary, `640` on inbox files, `770` on `markers/`; the decoy stays root-only `600`.
- **MAC (`policy/apparmor.profile`):** `r` on `inbox/`, `rw` on `markers/`, `audit deny` on the decoy, deny shells/other programs, no capabilities.
- **Experiments:** Run A as `agentlab` (DAC blocks the decoy) and Run B as root (DAC would allow, so AppArmor is isolated).

---

## Conversation 6 — Implementing and debugging Task 4 on the VM

**Date:** November 1, 2026
**Purpose:** Troubleshoot the confinement setup and interpret the audit logs.

**Issues I actually hit and resolved:**

- **Home-dir traversal:** `agentlab` could not reach the binary because home directories are mode `750`. I fixed it with `sudo setfacl -m u:agentlab:x` on each parent directory (traverse-only).
- **Interpreting the denial:** as root, the denial appears as a **capability** denial (`dac_override`, `dac_read_search`), not a file-open denial, because the kernel first checks whether the process may override DAC; the profile grants nothing, so the read fails with `exit=-13` (EACCES). The marker is still written, so the exploit "succeeds" but MAC contains it.

**What I learned:** a generic "Permission denied" does not by itself say whether DAC or AppArmor caused it; the experiment must be designed so the layer under test is not masked by an earlier denial.

**Evidence:** `screenshots/04_task4_runA_agentlab.png`, `05_task4_runB_denial.png`, `06_task4_ausearch_filtered.png`.

---

## Conversation 7 — Git and submission-workflow troubleshooting

**Date:** November 1, 2026
**Purpose:** Get the work onto GitHub and keep the repo consistent.

**What happened:**

- The VM could not push (HTTP 403), while my Windows clone could. The VM and Windows clones had each made their own path-fix commit on top of the same origin, so they had diverged.
- With Claude's help I pushed the VM's commit from Windows (a clean fast-forward on `origin`), then reset the Windows clone to match so all three (VM, Windows, GitHub) were identical.
- I also normalized every hardcoded path to `/home/pradeep/.../465_HW3/` and added a `.gitignore` for build artifacts. Commit messages were kept as my own (no AI attribution trailer).

---

## Conversation 8 — Final verification and screenshots

**Date:** November 1, 2026
**Purpose:** Check the evidence against the requirements and assemble the report.

**Evidence I collected (on the VM):**

| Area | What I ran | Actual result | Evidence file |
|---|---|---|---|
| Task 3 build | `gcc ... -Werror -o legacy_log_parser_fixed ...` | compiled clean | — |
| Task 3 tests | `bash tests/run_tests.sh` | 6 passed, 0 failed | `03_task3_checksec_tests.png` |
| Hardening check | `checksec --file=./legacy_log_parser{,_fixed}` | Full RELRO/Canary/PIE/FORTIFY on fixed | `01_...`, `03_...` |
| DAC experiment | `sudo -u agentlab ./src/legacy_log_parser ./inbox/log.bin` | decoy read denied (DAC) | `04_task4_runA_agentlab.png` |
| AppArmor denial | `sudo ./src/legacy_log_parser ...` then `ausearch -m AVC` | `dac_override`/`dac_read_search` DENIED, `exit=-13` | `05_...`, `06_...` |

**Final cross-check (done by me):**

- [x] The source files in the submission are the files I actually built and tested.
- [x] The report's claims match the terminal output and screenshots.
- [x] Screenshots are genuine captures from my VM session.
- [x] Any failed/inconclusive attempt is disclosed (see below), not shown as a pass.

---

## One error / limitation / rejected suggestion

My first GDB offset capture was **unusable** and I rejected it: I ran it from `~/465_HW3/src` instead of `~/csce465-agentsec/465_HW3/src`, so the parser's inbox-path check rejected the file *before* the copy and the program exited normally (`[Inferior 1 exited normally]`) instead of crashing. It proved nothing about the offset, so I did not include it; the offset (136) is instead stated from the stack layout and confirmed by the payload working. This is a reminder that AI-suggested commands still have to be run in the right working directory and the output checked, not assumed.

## Summary of AI assistance

Claude drafted the Task 3 fixed parser and test harness and helped design the Task 4 DAC/AppArmor confinement, debug the VM setup, and manage the Git workflow and screenshots. I reviewed all AI-drafted code and text, ran every build, test, and experiment on the course VM, captured the evidence, verified the outputs, and can explain the final implementation and results independently.
