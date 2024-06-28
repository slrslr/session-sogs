#!/bin/bash
# Linux bash script. Make this file executable (chmod +x filename) and run ("./filename" or "bash filename").

read -r -p "Add a database trigger to prevent DM/PM by regular users while allowing the same for admins/mods with upload permission? Type letter a to add trigger or letter r to remove trigger(allowing anyonone to PM):" i
if [[ "$i" == "r" ]]; then sqlite3 /var/lib/session-open-group-server/sogs.db 'DROP TRIGGER insert_into_inbox;'; else

--() { :; }; exec sqlite3 /var/lib/session-open-group-server/sogs.db <<EOF

-- "TRIGGER: Restrict non-admin users from sending DMs"
CREATE TRIGGER insert_into_inbox
BEFORE INSERT ON inbox
FOR EACH ROW
WHEN (
-- Allow visible mods to send messages to anyone
NEW.recipient NOT IN (SELECT user FROM user_permissions WHERE admin = 1 AND visible_mod=1)
AND NEW.sender NOT IN (SELECT user FROM user_permissions WHERE admin = 1 AND visible_mod=1)
-- Allow uploaders to send messages to anyone
AND NEW.recipient NOT IN (SELECT user FROM user_permission_overrides WHERE upload=1)
AND NEW.sender NOT IN (SELECT user FROM user_permission_overrides WHERE upload=1)
)
BEGIN
-- Abort the insert on the inbox table
SELECT RAISE(FAIL, 'Insert operation not allowed.');
-- SELECT RAISE(IGNORE);
END;

.quit
EOF

fi

echo "No error? Then it should be complete. Try to verify that it works."
