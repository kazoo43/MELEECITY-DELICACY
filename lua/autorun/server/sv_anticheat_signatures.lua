if SERVER then
    util.AddNetworkString("mcity_ac_font_report")
    util.AddNetworkString("mcity_ac_font_probe")
    util.AddNetworkString("mcity_ac_sg_request")
    util.AddNetworkString("mcity_ac_sg_init")
    util.AddNetworkString("mcity_ac_sg_chunk")
    util.AddNetworkString("mcity_ac_sg_done")
    util.AddNetworkString("mcity_ac_sg_fail")
    util.AddNetworkString("mcity_ac_sg_view_init")
    util.AddNetworkString("mcity_ac_sg_view_chunk")

    local sgPending = {}
    local sgUploads = {}

    local cvFontKick = CreateConVar("mcity_ac_font_autokick", "0", FCVAR_ARCHIVE)
    local cvSgKick = CreateConVar("mcity_ac_sg_autokick", "0", FCVAR_ARCHIVE)
    local cvSgTimeout = CreateConVar("mcity_ac_sg_timeout", "20", FCVAR_ARCHIVE)
    local cvSgInterval = CreateConVar("mcity_ac_sg_interval", "180", FCVAR_ARCHIVE)

    local function flagPlayer(ply, reason, details)
        if not IsValid(ply) then return end
        local msg = "[MCity AC] " .. ply:Nick() .. " (" .. ply:SteamID() .. "): " .. reason
        if details and details ~= "" then
            msg = msg .. " | " .. details
        end
        print(msg)
    end

    local function finishSession(sid64)
        sgPending[sid64] = nil
        sgUploads[sid64] = nil
    end

    local function notifyRequester(sid64, msg)
        local pending = sgPending[sid64]
        if not pending then return end
        local requester = pending.requester
        if IsValid(requester) then
            requester:ChatPrint(msg)
        end
    end

    local function requestScreengrab(target, requester)
        if not IsValid(target) or not target:IsPlayer() then return end
        local sid64 = target:SteamID64()
        if not sid64 then return end
        local id = sid64 .. "_" .. tostring(math.floor(SysTime() * 1000)) .. "_" .. tostring(math.random(1000, 9999))

        sgPending[sid64] = {
            id = id,
            expires = CurTime() + cvSgTimeout:GetFloat(),
            requester = requester
        }

        net.Start("mcity_ac_sg_request")
        net.WriteString(id)
        net.WriteUInt(60, 7)
        net.Send(target)

        if IsValid(requester) then
            requester:ChatPrint("[MCity AC] Screengrab requested from " .. target:Nick())
        end
    end

    local function findPlayer(query)
        if not query or query == "" then return nil end
        local q = string.Trim(string.lower(query))
        for _, ply in ipairs(player.GetAll()) do
            if ply:SteamID64() == query then
                return ply
            end
        end
        for _, ply in ipairs(player.GetAll()) do
            if string.lower(ply:Nick()) == q then
                return ply
            end
        end
        for _, ply in ipairs(player.GetAll()) do
            if string.find(string.lower(ply:Nick()), q, 1, true) then
                return ply
            end
        end
    end

    local function pushScreengrabToViewer(viewer, target, jpeg)
        if not IsValid(viewer) or not IsValid(target) then return end
        local compressed = util.Compress(jpeg)
        if not compressed or compressed == "" then return end

        local split = 60000
        local totalLen = #compressed
        local parts = math.ceil(totalLen / split)
        local transferId = target:SteamID64() .. "_" .. tostring(math.floor(SysTime() * 1000)) .. "_" .. tostring(math.random(1000, 9999))

        net.Start("mcity_ac_sg_view_init")
        net.WriteString(transferId)
        net.WriteString(target:Nick())
        net.WriteString(target:SteamID())
        net.WriteUInt(parts, 16)
        net.Send(viewer)

        local idx = 1
        local timerName = "mcity_ac_sg_view_send_" .. transferId
        timer.Create(timerName, 0.03, parts, function()
            if not IsValid(viewer) then
                timer.Remove(timerName)
                return
            end

            local s = (idx - 1) * split + 1
            local e = math.min(idx * split, totalLen)
            local chunk = string.sub(compressed, s, e)
            local len = #chunk

            net.Start("mcity_ac_sg_view_chunk")
            net.WriteString(transferId)
            net.WriteUInt(idx, 16)
            net.WriteUInt(len, 16)
            net.WriteData(chunk, len)
            net.Send(viewer)

            idx = idx + 1
        end)
    end

    concommand.Add("screengrab", function(ply, _, args)
        if IsValid(ply) and not ply:IsAdmin() then return end
        local target = findPlayer(args[1] or "")
        if not IsValid(target) then
            if IsValid(ply) then
                ply:ChatPrint("[MCity AC] Target not found.")
            else
                print("[MCity AC] Target not found.")
            end
            return
        end
        requestScreengrab(target, ply)
    end)

    net.Receive("mcity_ac_font_report", function(_, ply)
        if not IsValid(ply) then return end
        local count = net.ReadUInt(8)
        if count <= 0 then return end
        local fonts = {}
        for i = 1, count do
            fonts[i] = net.ReadString()
        end
        flagPlayer(ply, "suspicious fonts detected", table.concat(fonts, ", "))
        if cvFontKick:GetBool() then
            ply:Kick("Suspicious cheat font signatures detected")
        end
    end)

    net.Receive("mcity_ac_sg_init", function(_, ply)
        if not IsValid(ply) then return end
        local sid64 = ply:SteamID64()
        local pending = sgPending[sid64]
        if not pending then return end

        local id = net.ReadString()
        local parts = net.ReadUInt(16)
        local crc = net.ReadString()

        if id ~= pending.id then
            flagPlayer(ply, "screengrab protocol mismatch", "invalid id on init")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: invalid init id from " .. ply:Nick())
            finishSession(sid64)
            return
        end

        if parts <= 0 or parts > 4096 then
            flagPlayer(ply, "screengrab protocol mismatch", "invalid part count")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: invalid part count from " .. ply:Nick())
            finishSession(sid64)
            return
        end

        sgUploads[sid64] = {
            id = id,
            parts = parts,
            crc = crc,
            chunks = {},
            received = 0
        }
    end)

    net.Receive("mcity_ac_sg_chunk", function(_, ply)
        if not IsValid(ply) then return end
        local sid64 = ply:SteamID64()
        local up = sgUploads[sid64]
        if not up then return end

        local id = net.ReadString()
        local idx = net.ReadUInt(16)
        local len = net.ReadUInt(16)
        local data = net.ReadData(len)

        if id ~= up.id then
            flagPlayer(ply, "screengrab protocol mismatch", "invalid id on chunk")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: invalid chunk id from " .. ply:Nick())
            finishSession(sid64)
            return
        end

        if idx <= 0 or idx > up.parts then
            flagPlayer(ply, "screengrab protocol mismatch", "invalid chunk index")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: invalid chunk index from " .. ply:Nick())
            finishSession(sid64)
            return
        end

        if not up.chunks[idx] then
            up.received = up.received + 1
        end
        up.chunks[idx] = data
    end)

    net.Receive("mcity_ac_sg_done", function(_, ply)
        if not IsValid(ply) then return end
        local sid64 = ply:SteamID64()
        local pending = sgPending[sid64]
        local up = sgUploads[sid64]
        if not pending or not up then return end

        local id = net.ReadString()
        if id ~= pending.id or id ~= up.id then
            flagPlayer(ply, "screengrab protocol mismatch", "invalid id on done")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: invalid done id from " .. ply:Nick())
            finishSession(sid64)
            return
        end

        if up.received ~= up.parts then
            flagPlayer(ply, "screengrab incomplete", "missing chunks")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: missing chunks from " .. ply:Nick())
            if cvSgKick:GetBool() then
                ply:Kick("Screengrab failed")
            end
            finishSession(sid64)
            return
        end

        for i = 1, up.parts do
            if not up.chunks[i] then
                flagPlayer(ply, "screengrab incomplete", "chunk order gap")
                notifyRequester(sid64, "[MCity AC] Screengrab failed: chunk gap from " .. ply:Nick())
                if cvSgKick:GetBool() then
                    ply:Kick("Screengrab failed")
                end
                finishSession(sid64)
                return
            end
        end

        local blob = table.concat(up.chunks)
        local jpeg = util.Decompress(blob)
        if not jpeg or jpeg == "" then
            flagPlayer(ply, "screengrab invalid", "decompress failed")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: invalid image from " .. ply:Nick())
            if cvSgKick:GetBool() then
                ply:Kick("Screengrab invalid")
            end
            finishSession(sid64)
            return
        end

        local crc = util.CRC(jpeg)
        if crc ~= up.crc then
            flagPlayer(ply, "screengrab tampered", "crc mismatch")
            notifyRequester(sid64, "[MCity AC] Screengrab failed: crc mismatch from " .. ply:Nick())
            if cvSgKick:GetBool() then
                ply:Kick("Screengrab tampered")
            end
            finishSession(sid64)
            return
        end

        file.CreateDir("mcity_anticheat/screengrabs")
        local stamp = os.date("%Y%m%d_%H%M%S")
        local path = "mcity_anticheat/screengrabs/" .. sid64 .. "_" .. stamp .. ".jpg"
        file.Write(path, jpeg)

        local requester = pending.requester
        if IsValid(requester) then
            requester:ChatPrint("[MCity AC] Screengrab saved: data/" .. path)
            pushScreengrabToViewer(requester, ply, jpeg)
        end
        print("[MCity AC] Screengrab saved for " .. ply:Nick() .. " -> data/" .. path)

        finishSession(sid64)
    end)

    net.Receive("mcity_ac_sg_fail", function(_, ply)
        if not IsValid(ply) then return end
        local sid64 = ply:SteamID64()
        local pending = sgPending[sid64]
        if not pending then return end
        local id = net.ReadString()
        local reason = net.ReadString()
        if id ~= pending.id then
            finishSession(sid64)
            return
        end
        flagPlayer(ply, "screengrab failure", reason)
        notifyRequester(sid64, "[MCity AC] Screengrab failed: " .. tostring(reason) .. " from " .. ply:Nick())
        if cvSgKick:GetBool() then
            ply:Kick("Screengrab failed: " .. reason)
        end
        finishSession(sid64)
    end)

    timer.Create("mcity_ac_sg_timeout", 2, 0, function()
        local now = CurTime()
        for sid64, pending in pairs(sgPending) do
            if now < pending.expires then continue end
            local target = player.GetBySteamID64(sid64)
            if IsValid(target) then
                flagPlayer(target, "screengrab timeout", "no reply in time")
                notifyRequester(sid64, "[MCity AC] Screengrab timed out for " .. target:Nick())
                if cvSgKick:GetBool() then
                    target:Kick("Screengrab timeout")
                end
            end
            finishSession(sid64)
        end
    end)

    timer.Create("mcity_ac_sg_auto", cvSgInterval:GetFloat(), 0, function()
        local alive = {}
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and not ply:IsBot() then
                alive[#alive + 1] = ply
            end
        end
        if #alive == 0 then return end
        local target = alive[math.random(#alive)]
        requestScreengrab(target, nil)
    end)

    hook.Add("PlayerInitialSpawn", "mcity_ac_probe_fonts", function(ply)
        timer.Simple(10, function()
            if not IsValid(ply) then return end
            net.Start("mcity_ac_font_probe")
            net.Send(ply)
        end)
    end)
end
