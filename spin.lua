hexchat.register("spin.lua", "0.1", "Russian roulette script")

--local running = false
spinned = {}
local channel = "#channel"
local server = "server"
local timeout = 6000

local function setCTX()
	local current = hexchat.find_context(server, channel)
	hexchat.set_context(current)
end

local function splitNick(fullNick)
	return string.sub(fullNick, 2, string.find(fullNick, "!") - 1)
end

local function printWord(array)
--		 			 nickname	MODE	  #channel	mode
	print(splitNick(array[1]), array[2], array[3], array[4], array[5] or "")
end

local function printTable(tab)
	for k,v in pairs(tab) do
		print(k, v)
	end
end

local function printSpinned(target)
	for k,v in pairs(spinned) do
	--	print(k, os.date("%M:%S", (v - os.time())/1000))
		if type(v) == "number" then
			hexchat.command(("NOTICE %s %s -> %s"):format(target, k, os.date("%M:%S", (v - os.time())/1000)))
		else
			hexchat.command(("NOTICE %s %s -> %s"):format(target, k, v))
		end
	end
end

local function getLower(tab)
	local currentMax = ""
	for k,v in pairs(tab) do
		if type(v) == "number" then	
			if not tab[currentMax] or v < tab[currentMax] then
				currentMax = k
			end
		end
	end
	return currentMax
end

local function deSpin()
	setCTX()
	hexchat.send_modes({getLower(spinned)}, "+v")
	spinned[getLower(spinned)] = nil
--	printTable(spinned)
end

local function obtainRandomTime()
	return math.random(5, 20)*1000*60
end

local function goingKicked()
	return math.random(1, 10) == 4
end

local function checkPrivilege(nick, prefixes)
	for user in hexchat.iterate("users") do
--		print(user.nick)
		if hexchat.nickcmp(user.nick, nick) then
--			print(user.prefix)
			return string.find(user.prefix, prefixes)
		end
	end
end

local function isOp(nick)
	checkPrivilege(nick, "[%@&~]")
end

local function isUpperOp(nick)
	checkPrivilege(nick, "[&~]")
end

local function eventListener(words, eol)
--	printWord(words)
	if hexchat.nickcmp(splitNick(words[1]), hexchat.get_info("nick")) ~= 0 and string.find(words[4], "-v") and words[3] == channel and spinned[words[5]] and not isUpperOp(splitNick(words[1])) then
		setCTX()
		hexchat.send_modes({words[5]}, "-v")	
	end
	return hexchat.EAT_NONE
end

local function checkForSpin(input)
	if string.sub(input[4], 2, 6) == ".spin" and input[3] == channel then
		setCTX()
		if not goingKicked() then
			timeout = obtainRandomTime()
			spinned[splitNick(input[1])] = os.time() + timeout
			hexchat.send_modes({splitNick(input[1])}, "-v")
			printTable(spinned)
	--		print(getLower(spinned))
			hexchat.command(("PRIVMSG %s %s has been purged for %s"):format(channel, splitNick(input[1]), os.date("%M:%S", timeout/1000)))
			hexchat.hook_timer(timeout, deSpin)
		else
			hexchat.command(("KICK %s"):format(splitNick(input[1])))
		end
	elseif string.sub(input[4], 2) == ".purg" and input[3] == channel and isOp(splitNick(input[1])) then
		setCTX()
		spinned[input[5]] = "purged"
		hexchat.send_modes({input[5]}, "-v")
	elseif string.sub(input[4], 2, 8) == ".depurg" and input[3] == channel and isOp(splitNick(input[1])) then
		setCTX()
		spinned[input[5]] = nil
		hexchat.send_modes({input[5]}, "+v")		
	elseif string.sub(input[4], 2, 10) == ".purglist" and input[3] == channel and isOp(splitNick(input[1])) then
		setCTX()
		printSpinned(splitNick(input[1]))
	end
	return hexchat.EAT_NONE
end


hook = hexchat.hook_server("MODE", eventListener)
hook2 = hexchat.hook_server("PRIVMSG", checkForSpin)

