#!/bin/bash
# Linux bash script that will help keeping list of yours defined Session IDs not banned and set as moderators/admins (this is helpful against case where bad mod/admin bans or removes admin rights of others)
# Usage:
# 1. add Session IDs of mods inside a file defined under variable "modsids" below. Single line of blinded or unblinded(regular) Session IDs, space between each ID, no newlines...
# 2. adjust following block of variables (action, commname, ...) while picking one of the following approaches for your list of user IDs:
#
#    User role         | can be revoked by others | can set other as admins | impact
#    -----------------------------------------------------------------------------------------------------------------------------------------
# A) global admins     | possibly no              | yes                     | wrong removal of posts, mod rights of "modsids" non-listed users may be permanently revoked by mods/admins at will
# B) admins            | yes                      | yes                     | same as previous role + little inconvenience of a possible temporary removal of admin rights of your main "modsids" (until this script is run)
# C) global moderators | possibly no              | no                      | safest. If you still need admins who can add other admins, you can do it manually using sogs command
# D) moderators        | yes                      | no                      | same as previous role + little inconvenience of a possible temporary removal of mod rights of your main "modsids" (until this script is run)
#
# After making decision about your "modsids" role of choice, based on above mentioned table, set following variables accordingly:
# A) global admins....: comname "+" and admin "--admin"
# B) admins...........: comname "'*'" or "room1" or "room1 room2" and admin "--admin"
# C) global moderators: comname "+" and admin ""
# D) moderators.......: comname "'*'" or "room1" or "room1 room2" and admin ""
# 3. ideally after backing up the database, run "chmod 600 thisscriptname" and run a command to insert new hourly cronjob (first edit path inside that command):
# echo -e "$(crontab -l 2>/dev/null)\n44 * * * * /bin/bash /path/to/scripts/session-moderator-list-unban-keep-rights.sh &>/dev/null" | crontab -
#set -exu

# VARIABLES:
profanityfile="/var/lib/session-open-group-server/profanity-block-list.txt"
modsids="/var/lib/session-open-group-server/session-moderators-list-space-separated.txt" # list of mods session ids separated by space, to be added as global mods to all rooms without further asking
action="add" # we want to add/keep as mods so use "add", not "delete"
comname="+" # community/room token/name (shown in URL) where users from a $modsids file will be assigned. Input "+" to apply the rights server-wide (global admin) or "'*'" (yes single quotes inside) to apply on all rooms, use one or more rooms tokens separated by space (token is a room name shown in the community URL).
admin="" # input "--admin " (yes, space is correct and needed) in case you want users from a $modsids file to be able to add new admins themself
type="hidden" # type of the rights to assign users from a $modsids file. Options: "hidden" or "visible" (hidden decreases chances of a malevolent admins to remove other mods/admins rights)

# Exit in case of an unexpected variables or empty file with $modsids
if [[ $action == add || $action == delete ]] && [[ $admin == "" || $admin == "--admin " ]] && [[ $type == hidden || $type == visible ]]; then echo "[SUCCESS] Variable/s of the script contains valid/acceptable values"; else echo "Variable/s of the script may contain invalid/not acceptable value/s" && exit; fi
if [[ "$(grep -c 5 "$modsids")" != "1" ]]; then echo "[ERROR] File with mods IDs does not exist, or it does not contain one line containing valid Session ID/s." && exit; fi

echo "Ubanning modsids inside a database..."
for i in 1 2 3 4 5; do
for modlistid in $(cat "$modsids"); do
sqlite3 /var/lib/session-open-group-server/sogs.db "UPDATE users SET banned = FALSE WHERE session_id = '$modlistid';" && break || echo "" && sleep 0.1;
done
done;echo "Stage 1 is complete. (Up to 4 warnings of a locked DB is fine, because there is 5 attempts)"
for i in 1 2 3 4 5; do
for modlistid in $(cat "$modsids"); do
sqlite3 /var/lib/session-open-group-server/sogs.db "UPDATE user_permission_overrides SET banned = FALSE WHERE room = (SELECT id FROM rooms WHERE token = '$comname') AND user = (SELECT id FROM users WHERE session_id = '$modlistid');" && break || echo "" && sleep 0.1;
done
done;echo "Stage 2 is complete. (Up to 4 warnings of a locked DB is fine, because there is 5 attempts)"

echo -e "Backing up profanity blocklist and emptying it to speed-up following sogs command..." # long/complicated profanity phrases may cause SOGS delayed or failed command
cp -fp "$profanityfile" "$profanityfile"_"$(date --rfc-3339=date)" # backup blocklist
> "$profanityfile" # empty blocklist (to significantly speedup next sogs command)

echo -e "Setting intended mods as mods (in case a bad mod removed them)..."
sudo sogs --rooms "$comname" --"$action"-moderators $(cat "$modsids") "$admin"--"$type" &&

echo -e "Restoring profanity blocklist..."
cp -fp "$profanityfile"_"$(date --rfc-3339=date)" "$profanityfile" # restore blocklist

echo -e "Finished."
