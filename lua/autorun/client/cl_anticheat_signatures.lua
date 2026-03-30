if CLIENT then
    local suspectFonts = {
        "UI_Verdana",
        "UI_VerdanaBold",
        "UI_TahomaBig",
        "UI_Tahoma",
        "UI_TahomaBold",
        "UI_SmallFont",
        "kefir.main",
        "kefir.main.small",
        "kefir.main.qcold",
        "kefir.main.tiny",
        "kefir.main.nano"
    }
    local trackedFonts = {}
    local originalCreateFont = surface.CreateFont
    surface.CreateFont = function(name, data)
        if type(name) == "string" and name ~= "" then
            trackedFonts[name] = true
        end
        return originalCreateFont(name, data)
    end

    local function sendScreengrabFail(id, reason)
        net.Start("mcity_ac_sg_fail")
        net.WriteString(id or "")
        net.WriteString(reason or "unknown")
        net.SendToServer()
    end

    local function collectSuspiciousFonts()
        local listed = {}
        if type(surface.GetLuaFonts) == "function" then
            listed = surface.GetLuaFonts() or {}
        elseif type(surface.GetFonts) == "function" then
            listed = surface.GetFonts() or {}
        end
        local lookup = {}
        for i = 1, #listed do
            lookup[listed[i]] = true
        end
        for fontName, _ in pairs(trackedFonts) do
            lookup[fontName] = true
        end
        local found = {}
        for i = 1, #suspectFonts do
            local fontName = suspectFonts[i]
            if lookup[fontName] then
                found[#found + 1] = fontName
            end
        end
        return found
    end

    local function sendFontReport()
        local found = collectSuspiciousFonts()
        if #found <= 0 then return end
        net.Start("mcity_ac_font_report")
        net.WriteUInt(#found, 8)
        for i = 1, #found do
            net.WriteString(found[i])
        end
        net.SendToServer()
    end

    local pendingShot = nil
    local activeUpload = nil
    local pendingView = nil

    local function showScreengrabImage(targetName, targetSteamID, jpegData)
        if not jpegData or jpegData == "" then return end
        local b64 = util.Base64Encode(jpegData)
        if not b64 or b64 == "" then return end

        if IsValid(MCityACScreengrabFrame) then
            MCityACScreengrabFrame:Remove()
        end

        local frame = vgui.Create("DFrame")
        frame:SetSize(ScrW() * 0.9, ScrH() * 0.9)
        frame:Center()
        frame:SetTitle("Screengrab - " .. (targetName or "Unknown") .. " (" .. (targetSteamID or "") .. ")")
        frame:MakePopup()
        MCityACScreengrabFrame = frame

        local html = vgui.Create("DHTML", frame)
        html:Dock(FILL)
        html:SetHTML("<html><body style='margin:0;background:black;display:flex;align-items:center;justify-content:center;'><img style='max-width:100%;max-height:100%;' src='data:image/jpeg;base64," .. b64 .. "'/></body></html>")
    end

    local function sendScreengrabData(id, jpeg, quality)
        if not jpeg or jpeg == "" then
            sendScreengrabFail(id, "empty_capture")
            return
        end

        if type(render.Capture) ~= "function" then
            sendScreengrabFail(id, "render_capture_invalid")
            return
        end

        if type(render.CapturePixels) ~= "function" then
            sendScreengrabFail(id, "render_capturepixels_invalid")
            return
        end

        local compressed = util.Compress(jpeg)
        if not compressed or compressed == "" then
            sendScreengrabFail(id, "compress_failed")
            return
        end

        local split = 60000
        local totalLen = #compressed
        local parts = math.ceil(totalLen / split)
        local crc = util.CRC(jpeg)

        net.Start("mcity_ac_sg_init")
        net.WriteString(id)
        net.WriteUInt(parts, 16)
        net.WriteString(crc)
        net.SendToServer()

        activeUpload = { id = id }
        local chunkTimer = "mcity_ac_sg_chunks_" .. id
        local idx = 1
        timer.Create(chunkTimer, 0.05, parts, function()
            if not activeUpload or activeUpload.id ~= id then
                timer.Remove(chunkTimer)
                return
            end

            local s = (idx - 1) * split + 1
            local e = math.min(idx * split, totalLen)
            local chunk = string.sub(compressed, s, e)
            local len = #chunk

            net.Start("mcity_ac_sg_chunk")
            net.WriteString(id)
            net.WriteUInt(idx, 16)
            net.WriteUInt(len, 16)
            net.WriteData(chunk, len)
            net.SendToServer()

            idx = idx + 1
        end)

        timer.Simple(parts * 0.05 + 0.1, function()
            if not activeUpload or activeUpload.id ~= id then return end
            net.Start("mcity_ac_sg_done")
            net.WriteString(id)
            net.SendToServer()
            activeUpload = nil
        end)
    end

    hook.Add("PostRender", "mcity_ac_sg_capture", function()
        if not pendingShot then return end
        if pendingShot.frame > FrameNumber() then return end

        local id = pendingShot.id
        local q = pendingShot.quality
        local frame1 = FrameNumber()
        local jpeg = render.Capture({
            format = "jpeg",
            quality = q,
            x = 0,
            y = 0,
            w = ScrW(),
            h = ScrH()
        })
        local frame2 = FrameNumber()

        if frame1 ~= frame2 then
            pendingShot = nil
            sendScreengrabFail(id, "frame_shift")
            return
        end

        render.CapturePixels()
        pendingShot = nil
        sendScreengrabData(id, jpeg, q)
    end)

    net.Receive("mcity_ac_sg_request", function()
        local id = net.ReadString()
        local quality = net.ReadUInt(7)
        if pendingShot or activeUpload then
            sendScreengrabFail(id, "busy")
            return
        end
        if quality <= 0 or quality > 100 then
            quality = 60
        end
        pendingShot = {
            id = id,
            quality = quality,
            frame = FrameNumber() + 1
        }
    end)

    net.Receive("mcity_ac_font_probe", function()
        sendFontReport()
    end)

    net.Receive("mcity_ac_sg_view_init", function()
        pendingView = {
            id = net.ReadString(),
            targetName = net.ReadString(),
            targetSteamID = net.ReadString(),
            parts = net.ReadUInt(16),
            chunks = {},
            received = 0
        }
    end)

    net.Receive("mcity_ac_sg_view_chunk", function()
        if not pendingView then return end
        local id = net.ReadString()
        local idx = net.ReadUInt(16)
        local len = net.ReadUInt(16)
        local data = net.ReadData(len)

        if id ~= pendingView.id then return end
        if idx <= 0 or idx > pendingView.parts then return end
        if not pendingView.chunks[idx] then
            pendingView.received = pendingView.received + 1
        end
        pendingView.chunks[idx] = data

        if pendingView.received >= pendingView.parts then
            local blob = table.concat(pendingView.chunks)
            local jpeg = util.Decompress(blob)
            if jpeg and jpeg ~= "" then
                showScreengrabImage(pendingView.targetName, pendingView.targetSteamID, jpeg)
            end
            pendingView = nil
        end
    end)

    hook.Add("InitPostEntity", "mcity_ac_font_initial_scan", function()
        timer.Simple(6, sendFontReport)
    end)

    timer.Create("mcity_ac_font_scan", 30, 0, sendFontReport)
end
