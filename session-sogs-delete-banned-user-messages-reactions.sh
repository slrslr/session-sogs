#!/bin/bash
# Linux bash script. Make this file executable (chmod +x filename) and run ("./filename" or "bash filename").

read -r -p "Add a database trigger to delete all messages and reactions of a banned user? Type letter a to add trigger or letter r to remove trigger:" i
if [[ "$i" == "r" ]]; then sqlite3 /var/lib/session-open-group-server/sogs.db 'DROP TRIGGER insert_into_inbox;'; else

--() { :; }; exec sqlite3 /var/lib/session-open-group-server/sogs.db <<EOF

-- "TRIGGER: Delete messages belonging to banned users"
-- "TRIGGER: Delete user_reactions when a user is banned"
DROP TRIGGER IF EXISTS oddchat_bans_delete_messages;
CREATE TRIGGER oddchat_bans_delete_messages
AFTER UPDATE OF banned ON users
FOR EACH ROW
WHEN NEW.banned = TRUE
BEGIN
  DELETE FROM message_details
  WHERE data_size > 0
    AND NOT room IN (SELECT id FROM rooms WHERE token = 'adminsroom')
    AND user = NEW.id;
  DELETE FROM user_reactions
  WHERE user=NEW.id;
END;

.quit
EOF

fi

echo "No error? Then it should be complete. Try to verify that it works."
