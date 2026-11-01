# CSCE 465/765 HW3 — From Prompt to Process

Team: **Pradeep Periyasamy** & **Daniel Cuina**. A single stack buffer-overflow
defect is attacked (Tasks 1–2), fixed and hardened (Task 3), and contained with
DAC + AppArmor MAC (Task 4). All work was done on the course VM (Ubuntu 24.04,
VirtualBox), from `~/csce465-agentsec/465_HW3`.

## Contribution split (50 : 50)
- **Daniel Cuina** — Task 1 (vulnerable parser, ret2win, stack diagram) + Task 2
  (OpenClaw skill, adversarial page, agent trace).
- **Pradeep** — Task 3 (fixed/hardened parser, tests, checksec) + Task 4 (DAC
  user, AppArmor profile, confinement experiments, analysis).

## Layout
```
465_HW3/
  report.pdf                     graded write-up (all four tasks)
  report.tex                     LaTeX source for report.pdf
  README.md                      this file
  AI_USAGE_pradeep.md            AI-use disclosure (Pradeep, Tasks 3–4)
  pradeep_ai_logs/               raw AI session notes (Pradeep)
  AI_USAGE_daniel.md             AI-use disclosure (Daniel, Tasks 1–2)
  screenshots/                   terminal screenshots used in report.pdf
  src/
    legacy_log_parser.c          Task 1 vulnerable parser
    legacy_log_parser_fixed.c    Task 3 fixed + hardened parser
    make_payload.py              Task 1 ret2win payload generator
  policy/
    apparmor.profile             Task 4 MAC profile
    setup_user.sh                Task 4 DAC low-priv user + permissions
  skills/legacy-parser/          Task 2 OpenClaw skill (SKILL.md, run_parser.sh)
  web/
    adversarial.html             Task 2 indirect-prompt-injection page
    output.txt                   Task 2 saved agent trace
  tests/run_tests.sh             Task 3 five-case test harness
  tamu-shim.mjs                  local OpenClaw <-> TAMU API proxy (Task 2)
```

> **Paths:** the C sources, the AppArmor profile, and `setup_user.sh` use
> absolute paths under `/home/pradeep/csce465-agentsec/465_HW3/`. On a VM with a
> different username, update `INBOX_DIR` in the sources, the paths in
> `apparmor.profile`, and rebuild.

## Build

```bash
cd ~/csce465-agentsec/465_HW3/src

# Task 1 — vulnerable (protections off)
gcc -O0 -g -fno-stack-protector -no-pie -Wl,-z,noexecstack \
    -Wall -Wextra -o legacy_log_parser legacy_log_parser.c

# Task 3 — fixed + hardened
gcc -O2 -g -fstack-protector-strong -D_FORTIFY_SOURCE=3 \
    -fPIE -pie -Wl,-z,relro,-z,now -Wl,-z,noexecstack \
    -Wall -Wextra -Werror \
    -o legacy_log_parser_fixed legacy_log_parser_fixed.c

checksec --file=./legacy_log_parser
checksec --file=./legacy_log_parser_fixed
```

## Task 1 — exploit

```bash
cd ~/csce465-agentsec/465_HW3/src
WIN=$(nm ./legacy_log_parser | awk '/ T win$/ {print "0x"$1}')   # win() address
sed -i "s/^win_add = .*/win_add = $WIN/" make_payload.py
python3 make_payload.py                      # writes ../inbox/log.bin
cd ..
rm -f markers/ret2win.txt
./src/legacy_log_parser ./inbox/log.bin      # -> "Marker created" + segfault
cat markers/ret2win.txt
```

## Task 3 — tests

```bash
cd ~/csce465-agentsec/465_HW3
bash tests/run_tests.sh                       # 6 passed, 0 failed
```

## Task 4 — DAC + AppArmor

```bash
cd ~/csce465-agentsec/465_HW3
sudo bash policy/setup_user.sh                             # DAC: agentlab + perms
# let agentlab traverse the home dir (dirs are 750):
sudo setfacl -m u:agentlab:x /home/pradeep /home/pradeep/csce465-agentsec \
    /home/pradeep/csce465-agentsec/465_HW3 /home/pradeep/csce465-agentsec/465_HW3/src
sudo apparmor_parser -r -W policy/apparmor.profile        # MAC: enforce
sudo aa-status | grep legacy_log_parser

# Run A (DAC blocks, as agentlab):
rm -f markers/ret2win.txt
sudo -u agentlab ./src/legacy_log_parser ./inbox/log.bin

# Run B (MAC denies, as root — DAC would allow):
rm -f markers/ret2win.txt
sudo ./src/legacy_log_parser ./inbox/log.bin
sudo ausearch -m AVC -ts recent | grep legacy_log_parser  # the DENIED lines
```

## Task 2 — agent trace

```bash
TAMU_API_KEY=<key> node tamu-shim.mjs &        # proxy on :8899 (HW2 setup)
```
Point the OpenClaw agent at `web/adversarial.html`, ask it to summarize the
page, and save the trace to `web/output.txt`.

## Rebuild the report PDF
```bash
pdflatex report.tex && pdflatex report.tex     # screenshots/ must be present
```

## Notes
- Compiled binaries (`src/legacy_log_parser*`) and generated payloads
  (`inbox/*.bin`, `markers/ret2win.txt`) are build artifacts; the grader
  rebuilds them. They are `.gitignore`d.
- Per the group policy, each member submits a **separate** AI-use file.
