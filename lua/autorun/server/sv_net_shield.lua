if SERVER then
    local DEFAULT_LIMIT = 50
    local SPECIAL = {
        ["properties"] = 15,
        ["drones_usecmd"] = 5,
        ["atlaschat.invpm"] = 5,
        ["BodyGroupData"] = 10,
        ["NetData"] = 10,
        ["TL.sayColor"] = 5,
        ["nadmod_ppfriends"] = 10,
        ["ulxcc_RequestFiles"] = 5,
        ["join_disconnect"] = 5,
        ["DL_Answering"] = 5,
        ["ESM_WelcomePointsModule_PlayerReady"] = 5,
        ["ItemStoreUse"] = 10,
        ["SlotsRemoved"] = 10,
        ["wanted_radio"] = 2,
        ["keypad"] = 10,
        ["keypad_command"] = 10,
        ["PlyStatusIcons_StatusUpdate"] = 5,
        ["money_clicker_withdraw"] = 5,
        ["money_clicker_steal"] = 3,
        ["GPrinter.Withdraw"] = 5,
        ["GambitPrinter.Withdraw"] = 5,
        ["GambitPrinter.Cool"] = 5,
    }

    local function wrap(name, recv)
        return function(len, ply)
            if not IsValid(ply) then return end
            local now = CurTime()
            ply._mcity_net_windows = ply._mcity_net_windows or {}
            local w = ply._mcity_net_windows[name]
            if not w or now - w.t >= 1 then
                w = { t = now, c = 0 }
                ply._mcity_net_windows[name] = w
            end
            w.c = w.c + 1
            local limit = SPECIAL[name] or DEFAULT_LIMIT
            if w.c > limit then return end
            return recv(len, ply)
        end
    end

    timer.Simple(0, function()
        if not net.Receivers then return end
        for name, recv in pairs(net.Receivers) do
            if type(recv) ~= "function" then continue end
            net.Receivers[name] = wrap(name, recv)
        end
    end)

    if not net._mcity_original_Receive then
        net._mcity_original_Receive = net.Receive
        net.Receive = function(name, handler)
            return net._mcity_original_Receive(name, wrap(name, handler))
        end
    end
end
