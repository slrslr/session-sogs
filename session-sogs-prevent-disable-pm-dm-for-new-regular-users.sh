#!/bin/bash
# Linux bash script. Make this file executable (chmod +x filename) and run ("./filename" or "bash filename").

read -r -p "Add a database trigger to prevent DM/PM by new regular users while allowing the same for older regular users, admins/mods with upload permission? Type letter a to add trigger or letter r to remove trigger(allowing anyonone to PM):" i
if [[ "$i" == "r" ]]; then sqlite3 /var/lib/session-open-group-server/sogs.db 'DROP TRIGGER insert_into_inbox_new;'; else

--() { :; }; exec sqlite3 /var/lib/session-open-group-server/sogs.db <<EOF

-- "TRIGGER: Restrict new users from sending DMs"
DROP TRIGGER IF EXISTS insert_into_inbox_new;
CREATE TRIGGER insert_into_inbox_new
BEFORE INSERT ON inbox
FOR EACH ROW
WHEN (
-- Allow visible mods to send messages to anyone
NEW.recipient NOT IN (SELECT user FROM user_permissions WHERE admin = 1 AND visible_mod=1)
AND NEW.sender NOT IN (SELECT user FROM user_permissions WHERE admin = 1 AND visible_mod=1)

-- Allow uploaders to send messages to anyone
AND NEW.recipient NOT IN (SELECT user FROM user_permission_overrides WHERE upload=1)
AND NEW.sender NOT IN (SELECT user FROM user_permission_overrides WHERE upload=1)

-- Allow if BOTH sender and recipient have been around for >33 hours
AND (
  EXISTS (
    SELECT 1 FROM users WHERE id = NEW.sender AND strftime('%s', 'now') - created < 118800 AND banned=0
  )
  OR EXISTS (
    SELECT 1 FROM users WHERE id = NEW.recipient AND strftime('%s', 'now') - created < 118800 AND banned=0
  )
)

-- Allow if SENDER has been around for >7 days
AND NOT EXISTS (
  SELECT 1 FROM users WHERE id = NEW.sender AND strftime('%s', 'now') - strftime('%s', created) > 604800
)
)
-- If we don't have a hit yet, abort the insert
BEGIN
    -- Abort the insert on the inbox table
SELECT RAISE(FAIL, 'Insert operation not allowed.');
-- SELECT RAISE(IGNORE);
END;

.quit
EOF

fi

echo "No error? Then it should be complete. Try to verify that it works."
