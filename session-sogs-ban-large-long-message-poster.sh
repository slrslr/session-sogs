#!/bin/bash
# Linux bash script. Make this file executable (chmod +x filename) and run ("./filename" or "bash filename").

read -r -p "Add a database trigger to globally ban user that posts an excessively large(18000=10 pages of text) text message? Type letter a to add trigger or letter r to remove trigger(allowing anyonone to post long messages):" i
if [[ "$i" == "r" ]]; then sqlite3 /var/lib/session-open-group-server/sogs.db 'DROP TRIGGER large_messages_ban;'; else

--() { :; }; exec sqlite3 /var/lib/session-open-group-server/sogs.db <<EOF

-- "TRIGGER: Ban user for posting large messages"
DROP TRIGGER IF EXISTS large_messages_ban;
CREATE TRIGGER large_messages_ban
AFTER INSERT ON messages
FOR EACH ROW
WHEN
    NEW.data_size > 18000
BEGIN
    -- "Ban user"    
    INSERT INTO user_permission_overrides (user,room,banned) VALUES (NEW.user,NEW.room,1);
END;

.quit
EOF

fi

echo "No error? Then it should be complete. Try to verify that it works."
