local modstorage = minetest.get_mod_storage()
local players = {}
local modform = {}
local onlineplayers = {}
local command = modstorage:get_string("command")
local servers = minetest.deserialize(modstorage:get_string("servers")) or {}
local history = minetest.deserialize(modstorage:get_string("history")) or {}
local badwords = minetest.deserialize(modstorage:get_string("badwords")) or {}

local trashmouth = "false"
local current_server = ""
local banmod = "default"
local bwname = ""
local pending = 0
local localplayer

if command == "" then
	command = "/"
end

minetest.register_on_connect(function()
    localplayer = minetest.localplayer
    local server = minetest.get_server_info()
    current_server = server.address..":"..server.port

    if servers[current_server] ~= nil then
		banmod = servers[current_server].banmod
		trashmouth = servers[current_server].trashm
	else
		servers[current_server] = {
			banmod = "default",
			trashm = "false"
		}
	end

	minetest.register_chatcommand(command, {
	    description = "Bring up the Moderation Formspec",
	    func = function(param)
	        mainpage()
	    end
	})

	modstorage:set_string("servers", minetest.serialize(servers))
end)

local function warn(option, text)
	if option == 0 then
		minetest.display_chat_message(minetest.colorize("yellow", "[TRASHMOUTH] "..text))
	elseif option == 1 then
		minetest.display_chat_message(minetest.colorize("orange", "[TRASHMOUTH] "..text))
	else
		minetest.display_chat_message(minetest.colorize("red", "[TRASHMOUTH] "..text))
	end
end

minetest.register_on_receiving_chat_messages(function(msg) --Handle online players
    msg = minetest.strip_colors(msg)

    if msg:find("clients={") and msg:find("}") then --See which players are online when you join
        playerlist = msg:sub(msg:find("{")+1, msg:find("}")-1)
        a = 1
        for i=1, playerlist:len(), 1 do
        	a = a + 1
        	if playerlist:find(",") then
        		onlineplayers[playerlist:sub(1, playerlist:find(",")-1)] = 1
        		playerlist = playerlist:sub(playerlist:find(",")+2)
        	else
        		onlineplayers[playerlist] = 1
        		playerlist = nil
        	end

        	if playerlist == nil then break end
        end
    end

    if msg:find("<") and trashmouth == "true" then
    	if not msg:find(">") then return end
    	local sender = msg:sub(2, msg:find(">")-1)
    	local chat = string.lower(msg)

    	if sender ~= localplayer:get_name() then
	    	for k, v in pairs(badwords) do
	    		if chat:find(k) then
	    			warn(v, sender.." said "..dump(k))
	    			bwname = sender
	    			minetest.after(30, function()
	    				if pending == 1 then
	    					bwname = ""
	    				end
	    				pending = pending - 1
	    			end)
	    			pending = pending + 1
	    			break
	    		end
	    	end
	    end
    end


    if msg:find("left the game") and not msg:find("<") then --Remove player from the list
    	for name, k in pairs(onlineplayers) do 				--when they leave the server
    		if name == msg:sub(5, msg:find(" ", 5)-1) then
    			onlineplayers[name] = nil
    			break
    		end
    	end
    end

    if msg:find("joined the game") and not msg:find("<") then --Add the player to the list
    	onlineplayers[msg:sub(5, msg:find(" ", 5)-1)] = 1	  --when they join the server
    end
end)

function players.is_online(playername) --Returns true if the player is online
	local found = false				   --Otherwise it returns false
	for name, k in pairs(onlineplayers) do
		if name == playername and k == 1 then
			found = true
		end
	end

	return(found)
end

function players.getplayers(mode)
	local output
	local onplayers = {}
	
	local i = 1
	for key, value in pairs(onlineplayers) do
		if key ~= localplayer:get_name() and value == 1 then
			onplayers[i] = key
			i = i + 1
		end
	end

	table.sort(onplayers, function(a,b) return a<b end)

	if mode == "string" then
		output = ""
		for key, value in ipairs(onplayers) do
			if value ~= localplayer:get_name() then
				output = output..","..value
			end
		end
	end

	if mode == "table" then
		output = onplayers
	end

	if mode == "count" then
		output = 0
		for k, v in pairs(onlineplayers) do
			if v == 1 then
				output = output + 1
			end
		end

		if output >= 1 then
			output = output - 1
		end
	end

	return(output)
end

--
--History function
--

local function addhistory(text) --Used to add to the 'History' tab
	history[#history+1] = ",When: \\["..os.date("%x|%X").."\\],Server: \\["..current_server.."\\],"..text
	modstorage:set_string("history", minetest.serialize(history))
end


--No more comments from me after this point


--
--Main Page Formspec
--

local savedname = ""
function mainpage()
	if savedname == nil then savedname = "" end

	local textlistplayers = "Players Online: "..players.getplayers("count")..","
	textlistplayers = textlistplayers..players.getplayers("string")

    local form = "" ..
    "size[7.7,8.5]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "textlist[0.1,0.9;4.5,7.5;playerlist;"..textlistplayers.."]" ..
    "button[1.5,1.2;1.8,-1.7;refresh;Refresh]" ..
    "tabheader[0,0;tabs;Main,History,Settings;1;false;false]" ..
    "field[5,1.5;3.1,1;playername;Player;"..savedname.."]" ..
    "field_close_on_enter[playername;false]"

    if banmod == "sban" then
	    form = form.."button[4.7,6.7;3.1,1;banrecord;Ban Record]" ..
	    "tooltip[banrecord;Displays the chosen player's ban records and alts]"
    elseif banmod == "xban" then
	    form = form.."button[4.7,6.7;3.1,1;xgui;Xban Gui]" ..
	    "tooltip[xgui;Open the Xban Gui]"
	end
    form = form.."button[4.7,2.2;3.1,1;ban;Ban]" ..
    "tooltip[ban;Opens a formspec where you can ban the chosen player]" ..
    "button[4.7,4;3.1,1;kick;Kick]" ..
    "tooltip[kick;Opens a formspec where you can kick the chosen player]" ..
    "button[4.7,4.9;3.1,1;grant;Grant]" ..
    "tooltip[grant;Opens a formspec where you can grant privileges to the chosen player]" ..
    "button[4.7,5.8;3.1,1;revoke;Revoke]" ..
    "tooltip[revoke;Opens a formspec where you can revoke privileges from the chosen player]" ..
    "button[4.7,3.1;3.1,1;unban;Unban]" ..
    "tooltip[unban;Opens a formspec where you can unban the chosen player]"

    minetest.show_formspec("modform:mainpage", form)
end

--
--History Page Formspec
--

function historypage()
	if savedname == nil then savedname = "" end

	local historytext = ""

	for key, value in ipairs(history) do
		if value ~= localplayer:get_name() then
			historytext = historytext..","..value
		end
	end

    local form = "" ..
    "size[7.7,8.5]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "textlist[0.1,0.9;7.5,7.5;history;"..historytext.."]" ..
    "button[2.6,1.2;2.3,-1.7;refreshhistory;Refresh]" ..
    "tabheader[0,0;tabs;Main,History,Settings;2;false;false]"

    minetest.show_formspec("modform:historypage", form)
end

--
--Settings Page Formspec
--

function settingspage()

    local form = "" ..
    "size[7.7,8.5]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "tabheader[0,0;tabs;Main,History,Settings;3;false;false]" ..
    "label[0.1,0.2;Ban Mod]" ..
    "dropdown[1.5,0.1;2.5,1;banmod;"..banmod..",sban,xban,default;1]" ..
    "label[0.1,1.1;Command]" ..
    "field[1.8,1.2;2.5,1;modfcmd;;"..command.."]" ..
    "label[0.1,2.1;More settings coming soon...]" ..
    "label[0.1,3.1;ADDONS---]" ..
    "checkbox[0.1,3.7;trashtoggle;Enable Trashmouth;"..trashmouth.."]" ..
    "button[4,0.9;1.9,1;savecmd;Save]"

    minetest.show_formspec("modform:settingspage", form)
end

--Settings page input


minetest.register_on_formspec_input(function(formname, fields)
	if fields.quit or fields.exit or formname ~= "modform:settingspage" then return end

	if fields.savecmd and fields.modfcmd ~= "" and fields.modfcmd ~= "." and 
		fields.modfcmd ~= command then
		minetest.unregister_chatcommand(command)
		command = fields.modfcmd
		minetest.register_chatcommand(command, {
		    description = "Bring up the Moderation Formspec",
		    func = function(param)
		        mainpage()
		    end
		})
		modstorage:set_string("command", command)
		minetest.display_chat_message(minetest.colorize("orange", "[MODFORM] ")..
		"The command to open the modform formspec is now \'."..command.."\'")
		settingspage()
	end

	if fields.trashtoggle and fields.trashtoggle ~= trashmouth then
		trashmouth = fields.trashtoggle
		servers[current_server].trashm = trashmouth
		modstorage:set_string("servers", minetest.serialize(servers))

		if trashmouth == "true" then
			minetest.display_chat_message(minetest.colorize("orange", "[MODFORM] ")..
			"Trashmouth addon enabled")
		else
			minetest.display_chat_message(minetest.colorize("orange", "[MODFORM] ")..
			"Trashmouth addon disabled")
		end

		settingspage()
	end

	if fields.banmod and fields.banmod ~= banmod then
		banmod = fields.banmod
		servers[current_server].banmod = banmod
		modstorage:set_string("servers", minetest.serialize(servers))
		minetest.display_chat_message(minetest.colorize("orange", "[MODFORM] ")..
		"The banning mod has been changed to "..dump(banmod))
		settingspage()
	end
end)

--
--Ban Formspec
--

local savedreason = ""
local savedtime = ""
function banform()
	if savedname == nil then savedname = "" end

	local bantxt = ""

	if banmod == "xban" then
		if savedtime ~= "Eternity" then
			bantxt = "xtempban"
		else
			bantxt = "xban"
		end
	elseif banmod == "sban" then
		if savedtime ~= "Eternity" then
			bantxt = "tempban"
		else
			bantxt = "ban"
		end
	elseif banmod == "default" then
		bantxt = "ban"
	end

	if current_server == "hometownserver.com:30000" then
		bantxt = "ban"
	end

    local form = "" ..
    "size[7.7,6]" ..
    "tooltip[back;Go back to the main page]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "field[0.4,0.8;3.6,1;playertoban;Playername;"..savedname.."]" ..
    "field_close_on_enter[playertoban;false]"

    if banmod ~= "default" then
	    form = form.."field[0.4,1.9;3.6,1;banreason;Reason;"..savedreason.."]" ..
	    "field_close_on_enter[banreason;false]" ..
	    "dropdown[3.6,1.7;4.4,1;banreason2;"..savedreason..",Spamming Chat,Language,Adult Roleplay,Hacked Client,Cheating with CSM,Hate Speech,Harrasement/Bullying,Griefing,Pending Admin Review;1]" ..
	    "field[0.4,3;3.6,1;bantime;Ban Time;"..savedtime.."]" ..
	    "field_close_on_enter[bantime;false]" ..
	    "dropdown[3.6,2.8;4.4,1;bantime2;"..savedtime..",1m,3m,15m,30m,1H,3H,5H,10H,15H,20H,1D,2D,3D,4D,5D,6D,1W,2W,3W,1M,2M,3M,4M,5M,6M,7M,8M,9M,10M,11M,1Y,2Y,3Y,4Y,5Y,Eternity;1]"
	end

	local time = savedtime
	if savedreason ~= "" and savedtime ~= "" then
		time = time.." "
	end

    form = form.."label[0.2,3.5;/"..bantxt.." "..savedname.." "..time..savedreason.."]"..
    "button[5.9,0;1.9,1;back;Back]" ..
    "field[0.4,4.9;2.3,1;confirmban;;]" ..
    "label[0.1,4.3;Type in 'yes' and click 'BAN' to ban player]" ..
    "button[2.4,4.6;1.5,1;banformban;BAN]" ..
    "tooltip[banformban;Ban the chosen player]"

    minetest.show_formspec("modform:logpage", form)
end

--
--Kick Formspec
--

kickrbool = "false"
function kickform()
	if savedname == nil then savedname = "" end

    local form = "" ..
    "size[7.7,4.2]" ..
    "tooltip[back;Go back to the main page]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "field[0.4,0.8;3.6,1;playertokick;Playername;"..savedname.."]" ..
    "field_close_on_enter[playertokick;false]" ..
    "field[0.4,1.9;3.6,1;kickreason;Reason;"..savedreason.."]" ..
    "field_close_on_enter[kickreason;false]" ..
    "dropdown[3.6,1.7;4.4,1;kickreason2;"..savedreason..",Spamming Chat,Language,Adult Roleplay,Cheating with CSM,Hate Speech,Harrasement/Bullying,Pending Staff Review,Tone down the roleplay;1]" ..
    "label[0.2,2.5;/kick "..savedname.." "..savedreason.."]" ..
    "button[5.9,0;1.9,1;back;Back]" ..
    "checkbox[3.6,0.5;showreason;Display Reason In Chat;"..kickrbool.."]" ..
    "button[2.7,3.3;1.9,1;kickformkick;KICK]" ..
    "tooltip[kickformkick;Kick the chosen player]"

    minetest.show_formspec("modform:kickform", form)
end

--
--Unban Formspec
--

function unbanform()
	if savedname == nil then savedname = "" end
	local bantxt = ""

	if banmod ~= "xban" then
		bantxt = "unban"
	else
		bantxt = "xunban"
	end

    local form = "" ..
    "size[7.7,4.2]" ..
    "tooltip[back;Go back to the main page]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "field[0.4,0.8;3.6,1;playertounban;Playername;"..savedname.."]" ..
    "field_close_on_enter[playertounban;false]"

    if banmod == "sban" then
	    form = form.."field[0.4,1.9;3.6,1;unbanreason;Reason;"..savedreason.."]" ..
	    "field_close_on_enter[unbanreason;false]" ..
	    "dropdown[3.6,1.7;4.4,1;unbanreason2;"..savedreason..",Unbanning to make way for a reban,Unbanning to shorten the ban time;1]"
	end

    form = form.."label[0.2,2.5;/"..bantxt.." "..savedname.." "..savedreason.."]" ..
    "button[5.9,0;1.9,1;back;Back]" ..
    "button[2.7,3.3;1.9,1;formunban;UNBAN]" ..
    "tooltip[formunban;Unban the chosen player]"

    minetest.show_formspec("modform:unbanform", form)
end

--
--Granting Formspec
--

local savedpriv = ""
function grantform()

    local form = "" ..
    "size[3.5,3.8]" ..
    "tooltip[back;Go back to the main page]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "field[0.4,1.4;3.5,1;grantplayername;Playername;"..savedname.."]" ..
    "dropdown[0.1,2;3.6,1;gpriv;"..savedpriv..",All,Interact,Shout;1]" ..
    "button[0.8,2.9;2.1,1;grantpriv;Grant]" ..
    "tooltip[grantpriv;Grant player chosen priv. All = interact and shout]" ..
    "button[0.8,0;2.1,1;back;Back]"

    minetest.show_formspec("modform:grantform", form)
end

--
--Revoking Formspec
--

function revokeform()

    local form = "" ..
    "size[3.5,3.8]" ..
    "tooltip[back;Go back to the main page]" ..
	"background[5,5;1,1;gui_formbg.png;true]" ..
    "field[0.4,1.4;3.5,1;revokeplayername;Playername;"..savedname.."]" ..
    "dropdown[0.1,2;3.6,1;rpriv;"..savedpriv..",All,Interact,Shout;1]" ..
    "button[0.8,2.9;2.1,1;revokepriv;Revoke]" ..
    "tooltip[revokepriv;Revoke chosen priv from player. All = interact and shout]" ..
    "button[0.8,0;2.1,1;back;Back]"

    minetest.show_formspec("modform:revokeform", form)
end

--
--Formspec Input
--

minetest.register_on_formspec_input(function(formname, fields)
	local formmod = formname:sub(1, 7)

	if fields.back then
		minetest.after(0.1, function() mainpage() end)
	end

	if fields.quit or fields.exit or formmod ~= "modform" then return end

	--Misc

	if fields.xgui then
		minetest.run_server_chatcommand("xban_gui", "")
	end

	if fields.unban and savedname ~= "" then
		savedreason = ""
		unbanform()
	end

	if fields.kick and savedname ~= "" and players.is_online(savedname) == true then
		savedreason = ""
		kickform()
	end


	if fields.ban and savedname ~= "" then
		savedreason = ""
		savedtime = ""
		banform()
	end

	if fields.grant and savedname ~= "" then
		grantform()
	end

	if fields.revoke and savedname ~= "" then
		revokeform()
	end

	--Ban Record Button

	if fields.banrecord and savedname ~= "" then
		minetest.run_server_chatcommand("ban_record", savedname)
	end

	--Tab management

	if fields.tabs then
		if fields.tabs == "1" then
			mainpage()
		elseif fields.tabs == "2" then
			historypage()
		elseif fields.tabs == "3" then
			settingspage()
		end
	end

	--Grant Formspec fields

	if fields.key_enter_field and fields.key_enter_field == "grantplayername" then
		savedname = fields.grantplayername
		grantform()
	end

	if fields.gpriv then
		savedpriv = fields.gpriv
		grantform()
	end

	if fields.grantpriv and savedname ~= "" then
		local privs

		if savedpriv == "All" then
			privs = "interact, shout"
		else
			privs = string.lower(savedpriv)
		end

		minetest.run_server_chatcommand("grant", savedname.." "..privs)
		addhistory("  Granted "..savedname..":,  "..minetest.formspec_escape(privs))
		mainpage()
	end

	--Revoke Formspec fields

	if fields.key_enter_field and fields.key_enter_field == "revokeplayername" then
		savedname = fields.revokeplayername
		revokeform()
	end

	if fields.rpriv then
		savedpriv = fields.rpriv
		revokeform()
	end

	if fields.revokepriv and savedname ~= "" then
		local privs

		if savedpriv == "All" then
			privs = "interact, shout"
		else
			privs = string.lower(savedpriv)
		end

		minetest.run_server_chatcommand("revoke", savedname.." "..privs)
		addhistory("  Revoked "..savedname.."'s privs:,  "..minetest.formspec_escape(privs))
		mainpage()
	end


	--Main page fields

	if fields.refresh then
		mainpage()
	end

	if fields.playerlist and fields.playerlist:find("DCL:") then
		local number = tonumber(fields.playerlist:sub(5))

		if number > 2 then
			savedname = players.getplayers("table")[number-2]
			mainpage()
		end
	end

	if fields.key_enter_field and fields.key_enter_field == "playername" then
		savedname = fields.playername
		mainpage()
	end

	--History Page Fields

	if fields.refreshhistory then
		historypage()
	end

	--Ban Formspec Fields

	if fields.key_enter_field and fields.key_enter_field == "banreason" then
		savedreason = fields.banreason
		fields.banreason2 = savedreason
		banform()
	end

	if fields.playertoban then
		savedname = fields.playertoban
		banform()
	end

	if fields.banreason2 then
		savedreason = fields.banreason2
		banform()
	end

	if fields.key_enter_field and fields.key_enter_field == "bantime" then
		savedtime = fields.bantime
		fields.bantime2 = savedtime
		banform()
	end

	if fields.bantime2 then
		savedtime = fields.bantime2
		banform()
	end

	if fields.banformban and string.lower(fields.confirmban):find("yes") and savedname ~= "" then
		if banmod ~= "default" and (savedtime == "" or savedreason == "") then
			return
		end

		if banmod == "sban" then
			if savedtime == "Eternity" then
				minetest.run_server_chatcommand("ban", savedname.." "..savedreason)
				addhistory("  Banned "..savedname..",  Time: Forever,  Reason: "..savedreason)
			elseif savedtime ~= "Eternity" then
				minetest.run_server_chatcommand("tempban", savedname.." "..savedtime.." "..savedreason)
				addhistory("  Banned "..savedname..",  Time: "..savedtime..",  Reason: "..savedreason)
			end
		elseif banmod == "ban" then
			minetest.run_server_chatcommand("ban", savedname)
			addhistory("  Banned "..savedname)
		elseif banmod == "xban" then
			if savedtime == "Eternity" then
				minetest.run_server_chatcommand("xban", savedname.." "..savedreason)
				addhistory("  Banned "..savedname..",  Time: Forever,  Reason: "..savedreason)
			else
				minetest.run_server_chatcommand("xtempban", savedname.." "..savedtime.." "..savedreason)
				addhistory("  Banned "..savedname..",  Time: "..savedtime..",  Reason: "..savedreason)
			end
		end
		mainpage()
	end

	--Kick Formspec Fields

	if fields.showreason then
		kickrbool = fields.showreason
	end

	if fields.key_enter_field and fields.key_enter_field == "kickreason" then
		savedreason = fields.kickreason
		fields.kickreason2 = savedreason
		kickform()
	end

	if fields.playertokick then
		savedname = fields.playertokick
		kickform()
	end

	if fields.kickreason2 then
		savedreason = fields.kickreason2
		kickform()
	end

	if fields.kickformkick and savedname ~= "" and savedreason ~= "" then
		if players.is_online(savedname) then
			minetest.run_server_chatcommand("kick", savedname.." "..savedreason)
			if kickrbool == "true" then
				minetest.run_server_chatcommand("me", "kicked "..savedname.." with reason: "..savedreason)
			end
			addhistory("  Kicked "..savedname..",  Reason: "..savedreason..",  Reason in chat = "..kickrbool)
		else
			minetest.display_chat_message(minetest.colorize("red", "[ERROR] ").."Player is not online")
		end
		mainpage()
	end

	--UnbanForm Fields

	if fields.key_enter_field and fields.key_enter_field == "unbanreason" then
		savedreason = fields.unbanreason
		fields.unbanreason2 = savedreason
		unbanform()
	end

	if fields.playertounban then
		savedname = fields.playertounban
		unbanform()
	end

	if fields.unbanreason2 then
		savedreason = fields.unbanreason2
		unbanform()
	end

	if fields.formunban and savedname ~= "" then
		if banmod == "sban" then
			minetest.run_server_chatcommand("unban", savedname.." "..savedreason)
			addhistory("  Unbanned "..savedname..",  Reason: "..savedreason)
		elseif banmod == "default" then
			minetest.run_server_chatcommand("unban", savedname)
			addhistory("  Unbanned "..savedname)
		elseif banmod == "xban" then
			minetest.run_server_chatcommand("xunban", savedname)
			addhistory("  Unbanned "..savedname)
		end
		mainpage()
	end
end)

--
--Trashmouth commands
--

local function exists(word)
	for k, v in pairs(badwords) do
		if word == k then
			return(true)
		end
	end

	return(false)
end

local function tsort(table, sep)
	local out = ""
	for k, v in pairs(table) do
		if out == "" then
			out = k
		else
			out = out..sep..k
		end
	end

	return(out)
end

minetest.register_chatcommand("addword", {
	description = "Add a word to the trashmouth list.\n/addword <word> optional: <how bad (0-2, 2 means very bad)>",
	func = function(param)
		local num = 1
		if param:find(" ") ~= nil then
			num = tonumber(param:sub(param:find(" ")+1))
			param = string.lower(param:sub(1, param:find(" ")-1))
			if num == nil or not (num >= 0 and num <= 2) then
				num = 1
			end
		else
			param = string.lower(param)
		end

		if param ~= "" and exists(param) == false then
			badwords[param] = num
			minetest.display_chat_message("Added "..dump(param).." to the bad word list")
		else
			minetest.display_chat_message("Word already exists. (Or no word given)")
		end

		modstorage:set_string("badwords", minetest.serialize(badwords))
	end
})

minetest.register_chatcommand("delword", {
	description = "Remove a word from the trashmouth list.\n/delword <word>",
	func = function(param)
		param = string.lower(param)
		if param ~= "" and exists(param) == true then
			badwords[param] = nil
			minetest.display_chat_message("Removed "..dump(param).." from the bad word list")
		else
			minetest.display_chat_message("No such word in the bad word list")
		end
		modstorage:set_string("badwords", minetest.serialize(badwords))
	end
})

minetest.register_chatcommand("listwords", {
	description = "List all words in the trashmouth list",
	func = function(param)
		minetest.display_chat_message(minetest.colorize("#00FF00", "[TRASHMOUTH] ").." Words: "..tsort(badwords, ", "))
	end
})

minetest.register_chatcommand("y", {
	description = "Kick last player caught by the trashmouth with optional reason. (Defaults to `Swearing in chat`)",
	func = function(param)
		if param == "" then
			param = "Swearing in chat"
		end

		if bwname ~= "" and players.is_online(bwname) == true then
			minetest.run_server_chatcommand("kick", bwname.." "..param)
			addhistory("  Kicked "..bwname..",  Reason: "..param)
			bwname = ""
		else
			minetest.display_chat_message("30+ seconds elapsed since last trigger or player isn't online")
		end

		if pending >= 1 then
			pending = pending - 1
		end
	end
})