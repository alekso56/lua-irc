#!/usr/bin/lua

--[[
--Implemented callbacks:
--  on_nick_change(user, old_nick)
--  on_join(chan, user)
--  on_part(chan, user, part_msg)
--  on_op(chan, from_user, to_user)
--  on_deop(chan, from_user, to_user)
--  on_voice(chan, from_user, to_user)
--  on_devoice(chan, from_user, to_user)
--  on_topic_change(chan)
--  on_invite(from_user, chan)
--  on_kick(chan, from_user, to_user)
--  on_channel_msg(chan, from_user, msg)
--  on_private_msg(from_user, msg)
--  on_channel_notice(chan, from_user, msg)
--  on_private_notice(from_user, msg)
--  on_quit(user, quit_msg)
--  on_me_join(chan)
--  on_connect()
--  on_channel_act(chan, from_user, msg)
--  on_private_act(from_user, msg)
--  on_dcc(from_user, to_user, arg, address, port, size)
--  on_ctcp_error(from_user, to_user, msg)
--]]

--[[
--Implemented functions:
-- connect(args)
-- quit(msg)
-- join(chan)
-- part(chan)
-- say(to, msg)
-- notice(to, msg)
-- act(to, msg)
-- server_version(cb)
-- whois(cb, nick)
-- server_time(cb)
-- ctcp_ping(cb, nick)
-- ctcp_time(cb, nick)
-- ctcp_version(cb, nick)
-- send(command, ...)
-- get_ip()
-- channels()
--
-- chan:each_op()
-- chan:each_voice()
-- chan:each_user()
-- chan:each_member()
-- chan:ops()
-- chan:voices()
-- chan:users()
-- chan:members()
-- chan:ban(user)
-- chan:unban(user)
-- chan:voice(user)
-- chan:devoice(user)
-- chan:op(user)
-- chan:deop(user)
-- chan:set_limit(limit)
-- chan:set_key(key)
-- chan:set_private(b)
-- chan:set_secret(b)
-- chan:set_invite_only(b)
-- chan:set_topic_lock(b)
-- chan:set_no_outside_messages(b)
-- chan:set_moderated(b)
-- XXX: these should not be in the public interface... actually, this whole
-- handling needs to be rewritten
-- chan:add_user(user, mode)
-- chan:remove_user(user)
-- chan:change_status(user, b, mode)
-- chan:contains(user)
-- chan:change_nick(old_nick, new_nick
--
-- dcc.send(nick, filename, [port])
-- dcc.accept(filename, address, port, size, [packet_size])
--
-- debug.enable()
-- debug.disable()
-- debug.set_output(file)
-- debug.message(msg_type, msg, [color])
-- debug.err(msg)
-- debug.warn(msg)
--
-- XXX: do any of these need to be public?
-- misc.split(str, [delim], [end_delim], [lquotes], [rquotes])
-- misc.basename(path, [sep])
-- misc.dirname(path, [sep])
-- misc.str_to_int(str, [bytes], [endian])
-- misc.int_to_str(int, [endian])
-- misc.ip_str_to_int(ip_str)
-- misc.ip_int_to_str(ip_int)
-- misc.get_unique_filename(filename)
-- misc.try_call(fn, [...])
-- misc.try_call_warn(msg, fn, [...])
-- misc.parse_user(user)
-- misc.value_iter(state, arg, pred)
--]]

local irc = require "irc"
local dcc = require "irc.dcc"

irc.DEBUG = true

local function print_state()
    for chan in irc.channels() do
        print(chan..": Channel ops: "..table.concat(chan:ops(), " "))
        print(chan..": Channel voices: "..table.concat(chan:voices(), " "))
        print(chan..": Channel normal users: "..table.concat(chan:users(), " "))
        print(chan..": All channel members: "..table.concat(chan:members(), " "))
    end
end

function irc.on_connect()
    print("Joining channel #doytest...")
    irc.join("#doytest")
    print("Joining channel #doytest2...")
    irc.join("#doytest2")
end

function irc.on_me_join(chan)
    print("Join to " .. chan .. " complete.")
    print(chan .. ": Channel type: " .. chan.chanmode)
    if chan.topic.text and chan.topic.text ~= "" then
        print(chan .. ": Channel topic: " .. chan.topic.text)
        print("  Set by " .. chan.topic.user ..
              " at " .. os.date("%c", chan.topic.time))
    end
    irc.act(chan.name, "is here")
    print_state()
end

function irc.on_join(chan, user)
    print("I saw a join to " .. chan)
    if tostring(user) ~= "doylua" then
        irc.say(tostring(chan), "Hi, " .. user)
    end
    print_state()
end

function irc.on_part(chan, user, part_msg)
    print("I saw a part from " .. chan .. " saying " .. part_msg)
    print_state()
end

function irc.on_nick_change(new_nick, old_nick)
    print("I saw a nick change: "  ..  old_nick .. " -> " .. new_nick)
    print_state()
end

function irc.on_kick(chan, user)
    print("I saw a kick in " .. chan)
    print_state()
end

function irc.on_quit(chan, user)
    print("I saw a quit from " .. chan)
    print_state()
end

local function whois_cb(cb_data)
    print("WHOIS data for " .. cb_data.nick)
    if cb_data.user then print("Username: " .. cb_data.user) end
    if cb_data.host then print("Host: " .. cb_data.host) end
    if cb_data.realname then print("Realname: " .. cb_data.realname) end
    if cb_data.server then print("Server: " .. cb_data.server) end
    if cb_data.serverinfo then print("Serverinfo: " .. cb_data.serverinfo) end
    if cb_data.away_msg then print("Awaymsg: " .. cb_data.away_msg) end
    if cb_data.is_oper then print(nick .. "is an IRCop") end
    if cb_data.idle_time then print("Idletime: " .. cb_data.idle_time) end
    if cb_data.channels then
        print("Channel list for " .. cb_data.nick .. ":")
        for _, channel in ipairs(cb_data.channels) do print(channel) end
    end
end

local function serverversion_cb(cb_data)
    print("VERSION data for " .. cb_data.server)
    print("Version: " .. cb_data.version)
    print("Comments: " .. cb_data.comments)
end

local function ping_cb(cb_data)
    print("CTCP PING for " .. cb_data.nick)
    print("Roundtrip time: " .. cb_data.time .. "s")
end

local function time_cb(cb_data)
    print("CTCP TIME for " .. cb_data.nick)
    print("Localtime: " .. cb_data.time)
end

local function version_cb(cb_data)
    print("CTCP VERSION for " .. cb_data.nick)
    print("Version: " .. cb_data.version)
end

local function stime_cb(cb_data)
    print("TIME for " .. cb_data.server)
    print("Server time: " .. cb_data.time)
end

function irc.on_channel_msg(chan, from, msg)
    if from == "doy" then
        if msg == "leave" then
            irc.part(chan.name)
            return
        elseif msg:sub(1, 3) == "op " then
            chan:op(msg:sub(4))
            return
        elseif msg:sub(1, 5) == "deop " then
            chan:deop(msg:sub(6))
            return
        elseif msg:sub(1, 6) == "voice " then
            chan:voice(msg:sub(7))
            return
        elseif msg:sub(1, 8) == "devoice " then
            chan:devoice(msg:sub(9))
            return
        elseif msg:sub(1, 5) == "kick " then
            chan:kick(msg:sub(6))
            return
        elseif msg:sub(1, 5) == "send " then
            dcc.send(from, msg:sub(6))
            return
        elseif msg:sub(1, 6) == "whois " then
            irc.whois(whois_cb, msg:sub(7))
            return
        elseif msg:sub(1, 8) == "sversion" then
            irc.server_version(serverversion_cb)
            return
        elseif msg:sub(1, 5) == "ping " then
            irc.ctcp_ping(ping_cb, msg:sub(6))
            return
        elseif msg:sub(1, 5) == "time " then
            irc.ctcp_time(time_cb, msg:sub(6))
            return
        elseif msg:sub(1, 8) == "version " then
            irc.ctcp_version(version_cb, msg:sub(9))
            return
        elseif msg:sub(1, 5) == "stime" then
            irc.server_time(stime_cb)
            return
        elseif msg:sub(1, 6) == "trace " then
            irc.trace(trace_cb, msg:sub(7))
            return
        elseif msg:sub(1, 5) == "trace" then
            irc.trace(trace_cb)
            return
        end
    end
    if from ~= "doylua" then
        irc.say(chan.name, from .. ": " .. msg)
    end
end

function irc.on_private_msg(from, msg)
    if from == "doy" then
        if msg == "leave" then
            irc.quit("gone")
            return
        elseif msg:sub(1, 5) == "send " then
            dcc.send(from, msg:sub(6))
            return
        end
    end
    if from ~= "doylua" then
        irc.say(from, msg)
    end
end

function irc.on_channel_act(chan, from, msg)
    irc.act(chan.name, "jumps on " .. from)
end

function irc.on_private_act(from, msg)
    irc.act(from, "jumps on you")
end

function irc.on_op(chan, from, nick)
    print_state()
end

function irc.on_deop(chan, from, nick)
    print_state()
end

function irc.on_voice(chan, from, nick)
    print_state()
end

function irc.on_devoice(chan, from, nick)
    print_state()
end

function irc.on_dcc()
    return true
end

irc.connect{network = "irc.freenode.net", nick = "doylua", pass = "doylua"}