# Script to limit number of messages in a Session SOGS community server rooms/communities.
# This script can be run using crontab ~daily to limit number of messages in all communities/rooms. For examle run command "crontab -e" and past on a new line:
# @daily /bin/bash /root/scripts/session-sogs-prune-communities-remove-old-messages.sh &>/dev/null

dbpath="/var/lib/session-open-group-server/sogs.db"

# Delete messages in a room "roomname" (a token found in a room URL) older 14 days
#sqlite3 "$dbpath" "DELETE FROM messages WHERE room=(SELECT id FROM rooms WHERE token='roomname') AND posted < strftime('%s','now') - 14*86400;"

# Keep only 10000 newest messages in selected rooms, delete the rest
#for t in roomname1 roomname2; do
#sqlite3 "$dbpath" "DELETE FROM messages WHERE room=(SELECT id FROM rooms WHERE token='$t') AND seqno < (SELECT MIN(seqno) FROM (SELECT seqno FROM messages WHERE room=(SELECT id FROM rooms WHERE token='$t') ORDER BY seqno DESC LIMIT 10000));"
#done

# Keep only 10K most recent messages in each room:
# fetch room tokens once, with 30s wait-if-locked; retry whole command if it fails
until tokens=$(sqlite3 -cmd "PRAGMA busy_timeout=30000;" "$dbpath" "SELECT token FROM rooms;" 1>/dev/null); do sleep 5; done
for t in $tokens; do
  # retry this room's delete until it succeeds (up to 30s wait per attempt inside sqlite3)
  until sqlite3 -cmd "PRAGMA busy_timeout=30000;" "$dbpath" "DELETE FROM messages WHERE room=(SELECT id FROM rooms WHERE token='$t') AND seqno < (SELECT MIN(seqno) FROM (SELECT seqno FROM messages WHERE room=(SELECT id FROM rooms WHERE token='$t') ORDER BY seqno DESC LIMIT 10000));"; do
    echo "locked on $t, retrying in 10s"; sleep 10
  done
done

# Cleanup. Note that if you have installed sogs, not sogs-proxied, you should possibly replace sogs-proxied by sogs in following lines.
# VACUUM compacts the DB, ANALYZE refreshes query-planner stats so polls stop table-scanning. Note VACUUM needs free disk roughly the size of the DB
# This process requires downtime of around 30 seconds (on a SOGS with a long profanity blacklist). So I try to run it not daily as this script runs, but monthly
touch ~/.cache/session-sogs-prune-vacuum.last
if ! find ~/.cache/session-sogs-prune-vacuum.last -mtime +28 | grep -q .; then 
: ; else 
systemctl stop sogs-proxied && 
sqlite3 "$dbpath" "PRAGMA wal_checkpoint(TRUNCATE); VACUUM; ANALYZE;" 1>/dev/null;
systemctl start sogs-proxied
touch ~/.cache/session-sogs-prune-vacuum.last
fi
