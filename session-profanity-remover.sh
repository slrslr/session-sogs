#!/bin/bash
# This Linux bash script is meant for getsession.org SOGS servers.
# It uses a SQL command to get last X messages posted into all communities and if these contains any bad phrase listed in the blocklist file ($repatternsfile) or regular expressions file ($literalstringsfile), then:
# it runs a SQL command to delete such message (it gets removed also from the Session clients).
# Script can be run on the background by adding into a (root?) crontab (sudo su; crontab -e) new line i.e.: @reboot /bin/bash /root/scripts/session-profanity-remover &

# Defining paths of a blocklist files:
# repatternsfile should contain regular expressions. Don't have the file? Use prebuilt blocklist: https://raw.githubusercontent.com/slrslr/misc/main/profanity-block-list-partial-match-regex.txt
repatternsfile="/var/lib/session-open-group-server/profanity-block-list-partial-match-regex.txt"
# literalstringsfile should contain bad phrases meant for partial matching. Don't have the file? Use prebuilt blocklist: https://raw.githubusercontent.com/slrslr/misc/main/profanity-block-list-partial-match.txt
literalstringsfile="/var/lib/session-open-group-server/profanity-block-list-partial-match.txt"

filetocheck="/dev/shm/lastmessage"
touch "$repatternsfile" "$literalstringsfile" "$filetocheck"

while true; do

# Select last messages from a DB and insert these into a file
for i in 1 2 3 4 5 6 7 8 9; do
sqlite3 /var/lib/session-open-group-server/sogs.db 'SELECT * FROM message_details WHERE data IS NOT NULL ORDER BY id DESC LIMIT 10;' && echo "Success selecting msg during attempt $i/5" && break || echo "Failure selecting msg during attempt $i/5" && sleep 0.5;
done > "${filetocheck}"

# check file for existence of a phrases listed in files $repatternsfile and $literalstringsfile
found=$(grep -a -E -i -o -m 1 -f $repatternsfile $filetocheck|head -n 1) # Search using extended regexps and set first found string into a variable
if [[ ! "$found" ]]; then # not found matching phrase from first file, try phrases from another file
found=$(grep -a -F -i -o -m 1 -f $literalstringsfile $filetocheck|head -n 1) # Search using literal strings and set first found string into a variable
#       GREP switches explained:
#    -a: This switch is used to treat binary files as text files.
#    -E: This switch is used to enable extended regular expressions.
#    -i: This switch is used to perform case-insensitive matching.
#    -o: This switch is used to show only the matching part of the line.
#    -m 1: This switch is used to stop after the first match is found.
#    -f ./tmpdel-filererr: This switch is used to specify the file containing the patterns to search for.
fi

# if variable $found contains phrase (there is a match)
if [[ "$found" != "" ]];then

echo -e "\nFound matching phrase: $found"
# discover ID of the post (ID should be the first line above the matching phrase, that starts with number followed by | separators. tac is used to flip the output for grep which then ends on first match, then removing ending |:
postid="$(grep -a -F -B 1000000000 "$found" "$filetocheck"|tac|grep -oE -m 1 '^[0-9]+(?\|)'|sed 's/|$//g')" && echo "PostID: $postid"
# discover blinded ID of a message poster
blinded="$(grep -a -F -A 1000000000 "$found" "$filetocheck"|grep -oE '15[[:alnum:]]{64}'|head -n 1)" && echo "UserBlindedID: $blinded"
# Skip in case the matched phrase is part of the user's blinded ID (if there is regex in $repatternsfile made to match partial unblinded Session IDs, it may erroneously match part of blinded ID 15abc05.....):
if [[ "$blinded" == *"$found"* ]]; then break; fi
# Delete the message since it contains unwanted phrase:
for i in 1 2 3 4 5 6 7 8 9; do 
sqlite3 /var/lib/session-open-group-server/sogs.db "DELETE FROM message_details WHERE id = '$postid';" && echo "No error deleting during attempt $i/5" && break || echo "Error deleting during attempt $i/5" && sleep 0.5; 
done
# ChatGPT suggested way is opposite order: DELETE FROM messages WHERE id = '$postid'; DELETE FROM message_details WHERE id = '$postid';
# This was tested to remove messages from GUIs: DELETE FROM message_details WHERE room = 99999 AND posted < strftime('%s', 'now', '-1 days');
#### select: sqlite3 /var/lib/session-open-group-server/sogs.db "SELECT * FROM message_details WHERE id = '$postid';"
#echo -e "\nListing messages and message_details SQL table to check the result if any DB UPDATE/DELETE query was run by this script:\n" && sqlite3 /var/lib/session-open-group-server/sogs.db "SELECT * FROM messages WHERE id = '$postid'; SELECT * FROM message_details WHERE id = '$postid';"

fi

sleep 1
done
