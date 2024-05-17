# misc

**session-profanity-remover.sh** - Linux bash script meant for getsession.org SOGS servers, made due to insufficient capabilities of the default profanity blocking. This script removes unwanted posts from a SOGS SQL database (and from Session clients) after it is being posted. It is meant for long spam phrases (partial matching) and to deal with profanity blocklist evaders thanks to a regular expressions blocklist processing.

**profanity-block-list.txt** - list of words/phrases aimed to be blocked in a civilized discussion. Some listed phrases are questionable for blocking. Some should be removed if you allow DMs/PMs which allows paed.philes and similar to get in contact on messenger like Sessi.n (search for dm, pm, message, msg, add, group, grp, room).

**profanity-block-list-partial-match.txt** - list of longer phrases aimed to be blocked in a civilized discussion. List should be more or less safe for partial matching, mostly effective against lazy perverts and ped0s in a discussions.

**profanity-block-list-partial-match-regex.txt** - list of regular expressions that are matching spam phrases like cheeeeeese pizzzzaa and similar where insistent spammers trying to evade/workaround the primary profanity blocklist.

**session-moderator-list-unban-keep-rights.sh** - Linux bash script meant for getsession.org SOGS servers to maintain list of selected Session IDs as a community moderators or admins and keep these IDs not banned. Running this script reverts malevolent community admins removals/bans of other mods/admins.

**session-sogs-prevent-disable-pm-dm-for-regular-users.sh** - Linux bash script meant for getsession.org SOGS servers to help admin add or remove a database trigger that will prevent regular users without admin/mod privileges to send PM/DM to others.
