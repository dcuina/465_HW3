#!/usr/bin/env bash
#
# policy/setup_user.sh -- Task 4 DAC layer (CSCE 465/765 HW3)
#
# Creates a dedicated low-privilege system user `agentlab` and grants it,
# through ordinary Unix permissions, access to ONLY the three things the
# parser needs: the binary, the inbox (payloads), and the markers directory.
# It deliberately gets NO access to /opt/agentsec/decoy.txt (that file stays
# root-only, mode 600) -- so DAC already blocks the decoy read, and the
# AppArmor profile (MAC) enforces it a second time, bound to the program.
#
# Run with sudo from the hw3/ directory:  sudo bash policy/setup_user.sh
set -euo pipefail

HW3_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# 1. dedicated low-privilege, no-login system user (+ its own group `agentlab`)
if ! id agentlab >/dev/null 2>&1; then
    useradd --system --create-home --shell /usr/sbin/nologin agentlab
fi

# 2. let agentlab run the parser binary (read + execute)
chgrp agentlab "$HW3_DIR/src/legacy_log_parser"
chmod 750      "$HW3_DIR/src/legacy_log_parser"

# 3. let agentlab READ payloads in inbox/ (read + traverse), not write them
chgrp -R agentlab "$HW3_DIR/inbox"
chmod 750         "$HW3_DIR/inbox"
find "$HW3_DIR/inbox" -type f -exec chmod 640 {} \;

# 4. let agentlab WRITE the marker directory (the only place it may write)
chgrp agentlab "$HW3_DIR/markers"
chmod 770      "$HW3_DIR/markers"

# 5. confirm the protected decoy is OFF-LIMITS by DAC (root-only, 600)
#    (created in Task 1; re-assert here so the layering is explicit)
if [ -f /opt/agentsec/decoy.txt ]; then
    chown root:root /opt/agentsec/decoy.txt
    chmod 600       /opt/agentsec/decoy.txt
fi

echo "Done. Verify with:"
echo "  id agentlab"
echo "  ls -l $HW3_DIR/src/legacy_log_parser $HW3_DIR/inbox $HW3_DIR/markers"
echo "  sudo -u agentlab cat /opt/agentsec/decoy.txt   # should be: Permission denied"
