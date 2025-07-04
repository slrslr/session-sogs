#!/bin/bash
# sogsban - Linux bash script to ban Session user on a SOGS and delete all their content (posts, reactions)
# Run this script with that user ID as a parameter (bash scriptname idhere)
# Run this script without parameters to get help on how to use it.

# number of attempts to execute a SQL command to overcome DB locked issue
maxretries=20

# Detect type of the input ID and exit in case of invalid ID
if [[ "$1" =~ ^05[a-zA-Z0-9]{64}$ ]]; then idtype="uf"; elif [[ "$1" =~ ^15[a-zA-Z0-9]{64}$ ]]; then idtype="bf"; elif [[ "$1" =~ ^15[a-zA-Z0-9]{2}%[a-zA-Z0-9]{4}$ ]]; then idtype="bp"; else 
echo "Invalid input format. Examples of valid inputs:"
        echo "scriptname 05FullUnblindedID"
        echo "scriptname 15FullBlindedID"
        echo "scriptname 15eg%t8g9"
        echo -e "Full unblinded ID starts 05, Full blinded 15 and one with % is partial ID shown next to a user post display name."
        exit 1
fi

#read -r -p "Hit enter to ban ID and delete their content, or Ctrl+C to exit" proceed

# Unblinded full? Discover blinded and run another instance of this script to ban it and delete their content
if [[ "$idtype" == uf ]]; then
dir="$(pwd)";cd /var/lib/session-open-group-server && sudo su -s /usr/bin/python3 -c 'import sogs.crypto; abs_id = sogs.crypto.compute_blinded_abs_id("'$1'"); neg_abs_id = sogs.crypto.blinded_neg(abs_id); print(neg_abs_id)' > /tmp/blid && 
echo "Converted into a blinded ID"; cd "$dir"||exit; id=$(cat /tmp/blid)
fi

# Blinded full
if [[ "$idtype" == bf ]]; then id="$1"; fi

# Blinded partial to full blinded
if [[ "$idtype" == bp ]]; then
#id=$(sqlite3 /var/lib/session-open-group-server/sogs.db "SELECT DISTINCT session_id FROM message_details WHERE session_id LIKE '$1';")
for i in $(seq 1 "$maxretries"); do id=$(sqlite3 'file:/var/lib/session-open-group-server/sogs.db?immutable=1' "SELECT DISTINCT session_id FROM message_details WHERE session_id LIKE '$1';") && break || sleep 0.1; done
if [ -z "$id" ]; then echo "Unable to find full blinded ID out of $1. $maxretries attempts failed"; exit 1; else echo "Full: $id"; fi
fi

#echo "Banning...:"; 
for i in $(seq 1 "$maxretries"); do sqlite3 /var/lib/session-open-group-server/sogs.db "UPDATE users SET banned = TRUE WHERE session_id = '$id';" && 
echo "1/3) Setting as banned - attempt: $i success" && break || sleep 0.4; done

#echo "Deletion of a messages...:"; 
for i in $(seq 1 "$maxretries"); do sqlite3 /var/lib/session-open-group-server/sogs.db "DELETE FROM message_details WHERE session_id = '$id';" && 
echo "2/3) Deleting messages - attempt $i: success" && break || sleep 0.4; done

#echo "Deletion of reactions (emoji)...:"; 
for i in $(seq 1 "$maxretries"); do sqlite3 /var/lib/session-open-group-server/sogs.db "DELETE FROM user_reactions WHERE user = (SELECT id FROM users WHERE session_id = '$id');" && 
echo "3/3) Deleting reactions - attempt $i: success" && break || sleep 0.4; done
