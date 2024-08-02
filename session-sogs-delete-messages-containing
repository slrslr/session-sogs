#!/bin/bash
echo -e "Search in a Session community server (SOGS) database for a messages containing text (also partial match: %ery b%d phras%). After it is output, you will be prompted to delete it or skip."
read -r -p "1/3 Search | Input searched phrase:" text
read -r -p "2/3 Search | Input number of seconds to search into history (3600=hour, 86400=day):" seconds

# OUTPUT
--() { :; }; sqlite3 /var/lib/session-open-group-server/sogs.db <<EOF
SELECT * FROM message_details WHERE CAST(data AS TEXT) LIKE '%$text%' AND posted >= strftime('%s','now') - $seconds;
.quit
EOF

# DELETE PROMPT
echo -e "\n"; read -r -p  "3/3 Delete | Output shows only content intended to be removed? If so, hit \"d\" and enter to delete that content. Or other key to quit." dprompt;
if [[ "$dprompt" == d ]]; then sqlite3 /var/lib/session-open-group-server/sogs.db "DELETE FROM message_details WHERE CAST(data AS TEXT) LIKE '%$text%' AND posted >= strftime('%s','now') - $seconds;" && echo "Complete, it should be gone and Session client should remove messages in a minute or so..."; fi
