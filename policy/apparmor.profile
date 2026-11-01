# AppArmor profile -- Task 4 (CSCE 465/765 HW3)
#
# Confines the *vulnerable* parser so that even a successful ret2win exploit
# can do little harm. The profile is attached to the binary's path, so the
# kernel enforces it no matter which user runs the program (this is MAC:
# the rules bind to the program, not to the invoking user's DAC permissions).
#
# Load:    sudo apparmor_parser -r -W policy/apparmor.profile
# Status:  sudo aa-status
# Logs:    sudo ausearch -m AVC -ts recent      (or: sudo dmesg | grep DENIED)
#
# Adjust the three paths below if your checkout lives elsewhere; they must be
# ABSOLUTE for AppArmor.

#include <tunables/global>

/home/ubuntu/csce465-agentsec/465_HW3/src/legacy_log_parser {
  #include <abstractions/base>   # ld.so + libc + other read-only start-up files
                                 # (requirement 5: only what's needed to start)

  # --- the binary itself: read + memory-map to execute, nothing more ---
  /home/ubuntu/csce465-agentsec/465_HW3/src/legacy_log_parser    mr,

  # (1) read the payload/log files it parses, under inbox/ only
  /home/ubuntu/csce465-agentsec/465_HW3/inbox/                   r,
  /home/ubuntu/csce465-agentsec/465_HW3/inbox/*                  r,

  # (2) write ONLY the marker directory (needed so win()/normal runs can
  #     create markers/ret2win.txt) -- no write access anywhere else
  /home/ubuntu/csce465-agentsec/465_HW3/markers/                 rw,
  /home/ubuntu/csce465-agentsec/465_HW3/markers/*                rw,

  # (3) explicitly deny the protected decoy, and log every attempt.
  #     This is what stops the exploit's payoff: win() reaches fopen() of
  #     the decoy, but the kernel blocks the read and records an AVC denial.
  audit deny /opt/agentsec/decoy.txt                             rwklx,

  # (4) deny execution of shells and any unrelated program, and log it.
  #     Defeats a payload that tries to pivot to /bin/sh or similar.
  audit deny /bin/**                                             x,
  audit deny /usr/bin/**                                         x,
  audit deny /sbin/**                                            x,
  audit deny /usr/sbin/**                                        x,
  deny /{,usr/}bin/sh                                            x,
  deny /{,usr/}bin/bash                                          x,

  # No POSIX capabilities are granted (none are declared), so the program
  # runs with the empty capability set -- least privilege.
}
