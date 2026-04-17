if not SERVER then return end

HGPerf = HGPerf or {}
local PERF = HGPerf

PERF.sections = PERF.sections or {}
PERF.net = PERF.net or {}
PERF.counters = PERF.counters or {}
PERF.tick = PERF.tick or {
	samples = 0,
	total = 0,
	min = math.huge,
	max = 0,
	jitter = 0,
	overBudget = 0
}

local cvEnabled = CreateConVar("hg_perf_monitor_enabled", "0", FCVAR_ARCHIVE, "", 0, 1)
local cvPrint = CreateConVar("hg_perf_monitor_print", "1", FCVAR_ARCHIVE, "", 0, 1)
local cvInterval = CreateConVar("hg_perf_monitor_interval", "10", FCVAR_ARCHIVE, "", 2, 120)
local cvSave = CreateConVar("hg_perf_monitor_save", "1", FCVAR_ARCHIVE, "", 0, 1)

local SysTime = SysTime
local CurTime = CurTime
local TickInterval = engine.TickInterval
local FrameTime = FrameTime
local EngineServerFrameTime = engine and engine.ServerFrameTime

PERF.lastTick = PERF.lastTick or 0
PERF.nextPlayerSampleAt = PERF.nextPlayerSampleAt or 0
PERF.playerPingAvg = PERF.playerPingAvg or 0
PERF.playerPingMax = PERF.playerPingMax or 0
PERF.playerCount = PERF.playerCount or 0
PERF.lastSnapshot = PERF.lastSnapshot or {}

local function resetBucket(bucket)
	for name in pairs(bucket) do
		bucket[name] = nil
	end
end

local function getServerFrameMs()
	if EngineServerFrameTime then
		return math.Round(EngineServerFrameTime() * 1000, 4)
	end
	if FrameTime then
		return math.Round(FrameTime() * 1000, 4)
	end
	return 0
end

local function saveSnapshot(snapshot)
	if not cvSave:GetBool() then return end
	file.CreateDir("hg_perf_monitor")
	local day = os.date("%Y%m%d")
	local path = "hg_perf_monitor/" .. day .. ".jsonl"
	local payload = util.TableToJSON(snapshot, false) or "{}"
	if not file.Exists(path, "DATA") then
		file.Write(path, payload .. "\n")
		return
	end
	file.Append(path, payload .. "\n")
end

function PERF:IsEnabled()
	return cvEnabled:GetBool()
end

function PERF:Begin()
	if not cvEnabled:GetBool() then return nil end
	return SysTime()
end

function PERF:AddSectionSample(name, dt)
	if not cvEnabled:GetBool() then return end
	if not name or dt <= 0 then return end
	local section = self.sections[name]
	if not section then
		section = { calls = 0, total = 0, max = 0, last = 0 }
		self.sections[name] = section
	end
	section.calls = section.calls + 1
	section.total = section.total + dt
	section.last = dt
	if dt > section.max then section.max = dt end
end

function PERF:End(name, startTime)
	if not startTime then return end
	self:AddSectionSample(name, SysTime() - startTime)
end

function PERF:AddNetSample(name, bytes, dt)
	if not cvEnabled:GetBool() then return end
	if not name or dt <= 0 then return end
	local section = self.net[name]
	if not section then
		section = { calls = 0, bytes = 0, total = 0, max = 0, last = 0 }
		self.net[name] = section
	end
	section.calls = section.calls + 1
	section.bytes = section.bytes + (bytes or 0)
	section.total = section.total + dt
	section.last = dt
	if dt > section.max then section.max = dt end
end

function PERF:AddCounter(name, amount)
	if not cvEnabled:GetBool() then return end
	if not name then return end
	self.counters[name] = (self.counters[name] or 0) + (amount or 1)
end

local function samplePlayers()
	local all = player.GetHumans()
	local count = #all
	PERF.playerCount = count
	if count <= 0 then
		PERF.playerPingAvg = 0
		PERF.playerPingMax = 0
		return
	end
	local sum = 0
	local pmax = 0
	for i = 1, count do
		local ply = all[i]
		if IsValid(ply) then
			local ping = ply:Ping()
			sum = sum + ping
			if ping > pmax then pmax = ping end
		end
	end
	PERF.playerPingAvg = sum / count
	PERF.playerPingMax = pmax
end

hook.Add("Tick", "HGPerf_TickSample", function()
	if not cvEnabled:GetBool() then
		PERF.lastTick = SysTime()
		return
	end

	local now = SysTime()
	local last = PERF.lastTick
	if last > 0 then
		local dt = now - last
		local tick = PERF.tick
		tick.samples = tick.samples + 1
		tick.total = tick.total + dt
		if dt < tick.min then tick.min = dt end
		if dt > tick.max then tick.max = dt end
		local target = TickInterval()
		tick.jitter = tick.jitter + math.abs(dt - target)
		if dt > (target * 1.2) then
			tick.overBudget = tick.overBudget + 1
		end
	end
	PERF.lastTick = now

	if CurTime() >= PERF.nextPlayerSampleAt then
		PERF.nextPlayerSampleAt = CurTime() + 1
		samplePlayers()
	end
end)

local function topByTime(bucket, limit)
	local list = {}
	for name, section in pairs(bucket) do
		list[#list + 1] = {
			name = name,
			calls = section.calls,
			total_ms = section.total * 1000,
			avg_ms = (section.total / math.max(section.calls, 1)) * 1000,
			max_ms = section.max * 1000,
			last_ms = section.last * 1000,
			bytes = section.bytes
		}
	end
	table.sort(list, function(a, b)
		return a.total_ms > b.total_ms
	end)
	local output = {}
	for i = 1, math.min(limit, #list) do
		output[#output + 1] = list[i]
	end
	return output
end

function PERF:Snapshot(resetAfter)
	local tick = self.tick
	local samples = tick.samples
	local avgDt = samples > 0 and (tick.total / samples) or 0
	local avgTickRate = avgDt > 0 and (1 / avgDt) or 0

	local snapshot = {
		created_at = os.date("%Y-%m-%d %H:%M:%S"),
		players = self.playerCount,
		player_ping_avg = math.Round(self.playerPingAvg, 2),
		player_ping_max = math.Round(self.playerPingMax, 2),
		memory_kb = math.Round(collectgarbage("count"), 2),
		server_frame_ms = getServerFrameMs(),
		tick = {
			samples = samples,
			avg_rate = math.Round(avgTickRate, 3),
			avg_ms = math.Round(avgDt * 1000, 4),
			min_ms = math.Round((tick.min == math.huge and 0 or tick.min) * 1000, 4),
			max_ms = math.Round(tick.max * 1000, 4),
			jitter_ms = math.Round((samples > 0 and (tick.jitter / samples) or 0) * 1000, 4),
			over_budget = tick.overBudget
		},
		sections_top = topByTime(self.sections, 12),
		net_top = topByTime(self.net, 12),
		counters = table.Copy(self.counters)
	}

	self.lastSnapshot = snapshot

	if resetAfter then
		self.tick.samples = 0
		self.tick.total = 0
		self.tick.min = math.huge
		self.tick.max = 0
		self.tick.jitter = 0
		self.tick.overBudget = 0
		resetBucket(self.sections)
		resetBucket(self.net)
		resetBucket(self.counters)
	end

	return snapshot
end

local function canUseCommand(ply)
	if not IsValid(ply) then return true end
	if ply:IsListenServerHost() then return true end
	return ply:IsSuperAdmin()
end

concommand.Add("hg_perf_snapshot", function(ply)
	if not canUseCommand(ply) then return end
	local snapshot = PERF:Snapshot(false)
	saveSnapshot(snapshot)
	print(util.TableToJSON(snapshot, true))
end)

concommand.Add("hg_perf_snapshot_reset", function(ply)
	if not canUseCommand(ply) then return end
	local snapshot = PERF:Snapshot(true)
	saveSnapshot(snapshot)
	print(util.TableToJSON(snapshot, true))
end)

timer.Create("HGPerf_AutoReport", 1, 0, function()
	if not cvEnabled:GetBool() then return end
	local interval = math.max(2, cvInterval:GetInt())
	PERF.nextReportAt = PERF.nextReportAt or CurTime() + interval
	if CurTime() < PERF.nextReportAt then return end
	PERF.nextReportAt = CurTime() + interval
	local snapshot = PERF:Snapshot(true)
	saveSnapshot(snapshot)
	if cvPrint:GetBool() then
		print(util.TableToJSON(snapshot, true))
	end
end)
