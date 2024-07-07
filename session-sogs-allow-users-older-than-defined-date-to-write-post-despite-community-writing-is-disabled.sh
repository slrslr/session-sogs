#!/bin/bash
# Linux bash script. Make this file executable (chmod +x filename) and run ("./filename" or "bash filename").

read -r -p "1/2 Add a database trigger to allow users, that are older than defined date to write/post into the communities even if communities has writing disabled? Type letter a to add or letter r to remove(allowing even new users to post):" i

if [[ "$i" == "a" ]]; then

read -r -p "2/2 Users must be old at least how many days in order to be allowed to post/write? Enter number and users older than that will be able to post:" $d; datet=$(date -d "$d days ago" '+%F %T')

--() { :; }; exec sqlite3 /var/lib/session-open-group-server/sogs.db <<EOF

-- Start a transaction
BEGIN TRANSACTION;

-- Insert missing user_permission_overrides rows
INSERT INTO user_permission_overrides (room, user, write)
SELECT DISTINCT ru.room, u.id, TRUE
FROM room_users ru
JOIN users u ON ru.user = u.id
LEFT JOIN user_permission_overrides upo ON u.id = upo.user AND ru.room = upo.room
WHERE u.created < strftime('%s', '$datet')
AND upo.user IS NULL;

-- Update existing user_permission_overrides rows
UPDATE user_permission_overrides
SET write = TRUE
WHERE user IN (
    SELECT id
    FROM users
    WHERE created < strftime('%s', '$datet')
);

-- Commit the transaction
 COMMIT;

.quit
EOF

echo "No error? Then it should be complete. Try to verify that it works."

elif [[ "$i" == "r" ]]; then
sqlite3 /var/lib/session-open-group-server/sogs.db 'UPDATE user_permission_overrides SET write = FALSE';
fi
