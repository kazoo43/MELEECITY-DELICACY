if SERVER then
    hook.Add("PlayerSay", "mcity_chat_throttle", function(ply, text)
        local now = CurTime()
        ply._mcity_chat_window = ply._mcity_chat_window or now
        ply._mcity_chat_count = (ply._mcity_chat_count or 0) + 1
        if now - ply._mcity_chat_window >= 1 then
            ply._mcity_chat_window = now
            ply._mcity_chat_count = 1
        end
        if ply._mcity_chat_count > 5 then return "" end
    end)
end
