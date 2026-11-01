# Session 1 — Understanding Partner's Task 1

**Related AI_USAGE entry:** Conversation 1
**Tool / model / date:** Anthropic Claude (Claude Code, VS Code; Claude Opus) — November 1, 2026

## Goal
Understand the structure and behavior of the partner's Task 1 implementation, especially the input-handling and buffer operations relevant to later work on Task 3.

## Prompt / discussion topic
> Walk me through my partner's `legacy_log_parser.c`. Explain the input handling, the buffer operations, and exactly where and why the overflow reaches the saved return address, so I know what Task 3 has to fix.

## Discussion notes
- Walk through the program's execution flow.
- Identify where input is read, validated, copied, and used.
- Identify the function that performs the unchecked copy.
- Separate what is visible in the source from what must be confirmed by running the program.

## AI response summary
Claude explained that `parse_log()` reads the whole file into a heap buffer (up to `MAX_COPY = 512`), closes the file, and only then calls `vulnerable_copy()`, which `memcpy`s `n` bytes into a 128-byte stack buffer with **no check of `n` against `BUF_SIZE`**. Because the file is closed before the copy, the overflow cleanly overwrites this frame's saved return address rather than corrupting an open file handle. `win()` writes `markers/ret2win.txt` and then attempts to read the protected decoy.

## What I checked independently
- Relevant source file/function(s): `src/legacy_log_parser.c` — `vulnerable_copy()` (the `memcpy`), `parse_log()` (heap read + `fclose` then copy), `win()`.
- I confirmed `win()`'s address myself: `nm ./legacy_log_parser | grep ' T win'` → `0x4012b6`, matching `make_payload.py`.
- Offset to the saved return address: `128 (buf) + 8 (saved RBP) = 136`.

## Outcome
I understood the exact defect my Task 3 fix must remove: the missing `n > BUF_SIZE` check before the copy. I did not modify my partner's Task 1 work.
