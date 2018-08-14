# MODFORM

##Features

### Settings tab where you can:

* Tell the CSM what banning mod the server uses.
* Change what the command to open the formspec is
* Enable Addons. There is only one right now

### Addons:

* Trashmouth - Puts a warning in chat if a player says a word that is in the 'bad words' list
Here is a list of commands this addon adds:
	* `.addword <word> <significance>` - Adds a word to the bad word list
		* `<word>` - The word for trashmouth to search for in messages
		* `<significance>` - Number from 0 to 2 How bad the word is. 0 means 'not very bad', 2 means 'worst'

	* `.delword <word>` - Remove a word from the bad word list
		* `<word>` - Word in the bad word list

	* `.y <optional kick reason>` - Kick the last player to trigger the trashmouth
		* `<optional kick reason>` - The default kick reason is *Swearing in chat*

### History Tab

The history page lists records of your bans, kicks, and unbans

### Main Tab

* Has a playerlist containing all of the players currently online. Staff are highlighted green. Problems:
	* May not work if the join/leave messages on the server are not the same as the default ones
	* Will not work if you do not see the contents of `/status` when you join
	* May not work if the contents of `/status` are different from the default contents

* Has quite a few buttons (If you didn't notice)
	* `Refresh` - Refresh the playerlist

	* `Ban` - Brings up a formspec where you can ban players
		* `Ban` (all ban mods) - Ban the chosen player
		* `Playername` - The name of the player you are banning
		* `Reason` (xban & sban) - The reason that will be shown to the playerr when they are banned
		* `Time` (xban & sban) - The amount of time the player will be banned for
		* `Back` - Takes the user back to the main page
		* You must type *yes* into the field before you can ban a player. This helps prevent accidental bans
		* The command that will be issued is displayed above the field where you type in *yes*

	* `Unban` - Brings up a formspec where you can unban players
		* `Reason` (sban) - The reason for unbanning the player

	* `Kick` - Brings up a formspec where you can kick players
		* `Kick` - Kick the chosen player
		* `Playername` - Name of the player to kick
		* `Reason` - The reason for the kick
		* `Display Reason In Chat` - If this is checked (true) then the reason will be sent to all online players
		* `Back` - Takes the user back to the main page

	* `Grant` - Brings up a formspec where you can grant player privileges
		* `Playername` - Name of the player to grant the privileges to
		* `Back` - Takes the user back to the main page
		* Dropdown
			* `All` - interact and shout
			* `Interact` - The interact privilege
			* `Shout` - The shout privilege

	* `Revoke` - Brings up a formspec where you can revoke a player's privileges
		* `Playername` - Name of the player to revoke the privileges from
		* `Back` - Takes the user back to the main page
		* Dropdown
			* `All` - interact and shout
			* `Interact` - The interact privilege
			* `Shout` - The shout privilegee

	* `Ban Record` (sban) - Displays the chosen player's ban records and alts

	* `Xban Gui` (xban) - Brings up the Xban Gui
