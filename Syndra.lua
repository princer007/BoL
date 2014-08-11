if myHero.charName ~= "Syndra" then return end
local version = 1.61
local AUTOUPDATE = true
local SCRIPT_NAME = "Syndra"

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

if FileExist(SOURCELIB_PATH) then
	require("SourceLib")
else
	DOWNLOADING_SOURCELIB = true
	DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() PrintChat("Required libraries downloaded successfully, please reload") end)
end

if DOWNLOADING_SOURCELIB then PrintChat("Downloading required libraries, please wait...") return end

if AUTOUPDATE then
	 SourceUpdater(SCRIPT_NAME, version, "raw.github.com", "/princer007/BoL/master/"..SCRIPT_NAME..".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/princer007/BoL/master/"..SCRIPT_NAME..".version"):CheckUpdate()
end

local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
if VIP_USER and FileExist(LIB_PATH.."Prodiction.lua") then
	require("Prodiction")
end
RequireI:Check()

if RequireI.downloadNeeded == true then return end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

_D = 1338111
local MainCombo = {_Q, _W, _E, _R, _R, _R, _IGNITE}
local _QE = 1337
local WObject
--SpellData
local Ranges = {[_Q] = 800,       [_W] = 920,  [_E] = 700,       [_R] = 675}
local Widths = {[_Q] = 180,       [_W] = 200,  [_E] = 45 * 0.5,  [_R] = 1,    [_QE] = 60}
local Delays = {[_Q] = 0.25,      [_W] = 0.5,  [_E] = 0.5,       [_R] = 0.25, [_QE] = 1800} ---_QE delay updates in function of _E delay + Speed and the distance to the ball
local Speeds = {[_Q] = 3000,	  [_W] = 1450, [_E] = 2500,      [_R] = 1100, [_QE] = 1600}
local FocusJungleNames = {"GiantWolf8.1.1","AncientGolem7.1.1","Wraith9.1.1","LizardElder10.1.1","Golem11.1.2","GiantWolf2.1.1","AncientGolem1.1.1",
"Wraith3.1.1","LizardElder4.1.1","Golem5.1.2","GreatWraith13.1.1","GreatWraith14.1.1"}

local pets = {"annietibbers", "shacobox", "malzaharvoidling", "heimertyellow", "heimertblue", "yorickdecayedghoul"}

local Balls = {}
local BallDuration = 6.9

local QERange = (Ranges[_Q] + 500)

local QECombo = 0
local WECombo = 0
local EQCombo = 0

local DrawPrediction = nil

local DontUseRTime = 0
local UseRTime = 0

local RegisterCallbacks = {}
function OnLoad()
	VP = VPrediction()
	SOWi = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	DManager = DrawManager()

	Menu = scriptConfig("Syndra", "Syndra")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseEQ", "Use EQ", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Use Combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("UseEQ", "Use EQ", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.Harass:addParam("PP", "Perfect Poke(Harras when enemy do AA)", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("Enabled2", "Harass (toggle)!", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))

	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 1, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("ManaCheck2", "Don't farm if mana < % (freeze)", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("ManaCheck", "Don't farm if mana < % (laneclear)", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("EQ combo settings", "EQ")
		Menu.EQ:addParam("Order",  "Combo mode", SCRIPT_PARAM_LIST, 1, {"E -> Q" , "Q - > E"})
		Menu.EQ:addParam("Range", "Place Q at range:", SCRIPT_PARAM_SLICE, 700, 0, Ranges[_Q])

	Menu:addSubMenu("Ultimate", "R")
		Menu.R:addSubMenu("Don't use R on", "Targets")
		for i, enemy in ipairs(GetEnemyHeroes()) do
			Menu.R.Targets:addParam(enemy.hash,  enemy.charName, SCRIPT_PARAM_ONOFF, false)
		end
		Menu.R:addParam("CastR", "Force ultimate cast", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))
		Menu.R:addParam("DontUseR", "Don't use R in the next 10 seconds", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))

	Menu:addSubMenu("Misc", "Misc")
		if VIP_USER then
			Menu.Misc:addParam("WPet",  "Auto grab pets using W", SCRIPT_PARAM_ONOFF, true)
		end
		Menu.Misc:addParam("PRQ", "Prediction sensitivity(Q)", SCRIPT_PARAM_SLICE, 2, 1, 4)
		
		Menu.Misc:addParam("Whitchance", "W min hitchance(1 - insta cast)", SCRIPT_PARAM_SLICE, 1, 1, 2)

		Menu.Misc:addSubMenu("Auto-Interrupt", "Interrupt")
			Interrupter(Menu.Misc.Interrupt, OnInterruptSpell)

		Menu.Misc:addSubMenu("Anti-Gapclosers", "AG")
			AntiGapcloser(Menu.Misc.AG, OnGapclose)

		Menu.Misc:addParam("MEQ", "Manual E+Q Combo", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("T"))

	Menu:addSubMenu("Drawings", "Drawings")
		DManager:CreateCircle((myHero), SOWi:MyRange() + 50, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "AA Range", true, true, true)
		--[[Spell ranges]]
		for spell, range in pairs(Ranges) do
			DManager:CreateCircle((myHero), range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, SpellToString(spell).." Range", true, true, true)
		end
		DManager:CreateCircle((myHero), QERange, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "Q+E Range", true, true, true)
		
	Menu:addSubMenu("Debug", "Debug")
		Menu.Debug:addParam("DebugBall",  "Track balls", SCRIPT_PARAM_ONOFF, false)
		Menu.Debug:addParam("DebugCast",  "Cast output", SCRIPT_PARAM_ONOFF, false)
		Menu.Debug:addParam("DebugQ",  "Draw Q prediction", SCRIPT_PARAM_ONOFF, false)
		--Menu.Debug:addParam("DebugW",  "Debug W state", SCRIPT_PARAM_ONOFF, false)
		--Menu.Debug:permaShow("DebugW")
	--[[Predicted damage on healthbars]]
	Menu.Drawings:addParam("DrawPredictedHealth",  "Draw Predicted Health", SCRIPT_PARAM_ONOFF, true)
	--DLib:AddToMenu(Menu.Drawings, MainCombo)

	
	Q = Spell(_Q, Ranges[_Q], VIP_USER)
	W = Spell(_W, Ranges[_W], false)
	W2 = Spell(_W, Ranges[_W], false) 
	E = Spell(_E, Ranges[_E], false)
	EQ = Spell(_E, Ranges[_E], false)
	R = Spell(_R, Ranges[_R], VIP_USER)
	if VIP_USER then
		Q:TrackCasting("SyndraQ")
		Q:RegisterCastCallback(OnCastQ)
		
		W:TrackCasting("SyndraW")
		W:RegisterCastCallback(function() end)
		
		W2:TrackCasting("syndrawcast")
		W2:RegisterCastCallback(OnCastW)
		
		E:TrackCasting({"SyndraE", "syndrae5"})
		E:RegisterCastCallback(OnCastE)
	else
		WTrack = 0
		--RegisterCallbacks = {"SyndraQ", "SyndraW", "syndraw2", "SyndraE", "syndrae5"}
	end

	Q:SetSkillshot (VP, SKILLSHOT_CIRCULAR, Widths[_Q], Delays[_Q], Speeds[_Q], false)
	W:SetSkillshot (VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], Speeds[_W], false)
	W2:SetSkillshot(VP, SKILLSHOT_CIRCULAR, Widths[_W], Delays[_W], Speeds[_W], false)
	E:SetSkillshot (VP, SKILLSHOT_CONE, Widths[_E], Delays[_E], Speeds[_E], false) --E
	EQ:SetSkillshot(VP, SKILLSHOT_LINEAR, 70, Delays[_E], Speeds[_E], false) --EQ

	Q:SetAOE(true)
	W:SetAOE(true)
	DLib:RegisterDamageSource(_D, _MAGIC, 0,  0,  _MAGIC, _AP, 0,    function() return GetInventoryItemIsCastable(ItemManager:GetItem("DFG"):GetId()) end, function(target) return 0.15 * target.maxHealth end)
	DLib:RegisterDamageSource(_Q, _MAGIC, 30, 40, _MAGIC, _AP, 0.60, function() return (player:CanUseSpell(_Q) == READY) end)--Without the 15% increase at rank 5
	DLib:RegisterDamageSource(_W, _MAGIC, 40, 40, _MAGIC, _AP, 0.70, function() return (player:CanUseSpell(_W) == READY) end)
	DLib:RegisterDamageSource(_E, _MAGIC, 25, 45, _MAGIC, _AP, 0.40, function() return (player:CanUseSpell(_E) == READY) end)--70 / 115 / 160 / 205 / 250 (+ 40% AP)
	DLib:RegisterDamageSource(_R, _MAGIC, 45, 45, _MAGIC, _AP, 0.20, function() return (player:CanUseSpell(_R) == READY) end)--1 sphere

	
	EnemyMinions = minionManager(MINION_ENEMY, W.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	JungleMinions = minionManager(MINION_JUNGLE, QERange, myHero, MINION_SORT_MAXHEALTH_DEC)
	PosiblePets = minionManager(MINION_OTHER, W.range, myHero, MINION_SORT_MAXHEALTH_DEC)
	PrintChat("Syndra: Loaded <font color=\"#6699ff\"><b> TTL!</b>")
end
function OnRecvPacket(p)
	if p.header == 113 then
		p.pos = 1
		local NetworkID = p:DecodeF()
		local Active = p:Decode1()

		if NetworkID and Active == 1 then
			if not WObject then
				for i, ball in ipairs(Balls) do
					if ball.networkID == NetworkID then
						Balls[i].endT = os.clock() + BallDuration - GetLatency()/2000
					end
				end
			end
			WObject = objManager:GetObjectByNetworkId(NetworkID)
		else
			WObject = nil
		end
	end
end
------------------------------------------------------------------------------------------------------------------------------------------------------------v
------------------------------------------------------------------------------------------------------------------------------------------------------------v
------------------------------------------------------------------------------------------------------------------------------------------------------------v

--Change the combo table depending on the active balls count.
function GetCombo()
	local result = {}
	for i, spell in ipairs(MainCombo) do
		table.insert(result, spell)
	end
	for i = 1, #GetValidBalls() do
		table.insert(result, _R)
	end
	return result
end

--Track the balls :p
function GetValidBalls(all)
	local result = {}
	for i, ball in ipairs(Balls) do
		if (ball['added'] or ball['startT'] <= os.clock()) and Balls[i]['endT'] >= os.clock() and ball['object']['valid'] then
			if not WObject or ball.object.networkID ~= WObject.networkID then
				table.insert(result, ball)
			end
		end
	end
	return result
end

function AddBall(obj)
	for i = #Balls, 1, -1 do
		if not Balls[i].added and GetDistanceSqr(Balls[i].object, obj) < 50*50 then
			Balls[i].added = true
			Balls[i].object = obj
			do return end
		end
	end

	--R balls
	local BallInfo = {
							 added = true, 
							 object = obj,
							 startT = os.clock(),
							 endT = os.clock() + BallDuration - GetLatency()/2000
					}
	table.insert(Balls, BallInfo)						
end

function OnCreateObj(obj)
	if obj and obj.valid then
		if GetDistanceSqr(obj) < Q.rangeSqr * 2 then
			if obj.name:find("Seed") then
				DelayAction(AddBall, 0, {obj})
			end
		end
	end
end

function OnDeleteObj(obj)
	if obj.name:find("Syndra_") and (obj.name:find("_Q_idle.troy") or obj.name:find("_Q_Lv5_idle.troy")) then
		for i = #Balls, 1, -1 do
			if Balls[i].object and Balls[i].object.valid and GetDistanceSqr(Balls[i].object, obj) < 50 * 50 then
				table.remove(Balls, i)
				break
			end
		end
	end
end

--Remove the non-active balls to save memory
function BTOnTick()
	for i = #Balls, 1, -1 do
		if Balls[i].endT <= os.clock() then
			table.remove(Balls, i)
		end
	end
end

function BTOnDraw()--For testings
	local activeballs = GetValidBalls()
	for i, ball in ipairs(activeballs) do
		DrawCircle(ball['object']['x'], myHero.y, ball['object']['z'], 100, ARGB(255,255,255,255))
	end
end

function IsPet(name) 
	return table.contains(pets, name:lower())
end

function IsPetDangerous(name)
	return (name:lower() == "annietibbers") or (name:lower() == "heimertblue")
end

function AutoGrabPets()
	if W:IsReady() and W.status == 0 then
		local pet = GetPet(true)
		if pet then
			W:Cast(pet.x, pet.z)
			if Menu.Debug.DebugCast then PrintChat("Grab pet by W") end
		end
	end
end

function GetPet(dangerous)
	PosiblePets:update()
	--Priorize Enemy Pet's
	for i, object in ipairs(PosiblePets.objects) do
		if object and object.valid and object.team ~= myHero.team and IsPet(object.charName) and (not dangerous or IsPetDangerous(object.charName)) then
			return object
		end
	end
end

function GetWValidBall(OnlyBalls)
	local all = GetValidBalls()
	local inrange = {}

	local Pet = GetPet(true)
	if Pet then
		return {object = Pet}
	end

	--Get the balls in W range
	for i, ball in ipairs(all) do
		if GetDistanceSqr(ball.object, myHero.visionPos) <= W.rangeSqr then
			table.insert(inrange, ball)
		end
	end

	local minEnd = math.huge
	local minBall

	--Get the ball that will expire earlier
	for i, ball in ipairs(inrange) do
		if ball.endT < minEnd then
			minBall = ball
			minEnd = ball.endT
		end
	end

	if minBall then
		return minBall
	end
	if OnlyBalls then 
		return 
	end

	Pet = GetPet()
	if Pet then
		return {object = Pet}
	end

	EnemyMinions:update()
	JungleMinions:update()
	PosiblePets:update()
	local t = MergeTables(MergeTables(EnemyMinions.objects, JungleMinions.objects), PosiblePets.objects)
	SelectUnits(t, function(t) return ValidTarget(t) and GetDistanceSqr(myHero.visionPos, t) < W.rangeSqr end)
	if t[1] then
		return {object = t[1]}
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function OnProcessSpell(unit, spell)
if not VIP_USER and unit == myHero then
--RegisterCallbacks = {"SyndraQ", "SyndraW", "syndraw2", "SyndraE", "syndrae5"} 
	if spell.name:lower():find("syndraq") then
		OnCastQ(spell)
	elseif spell.name:lower():find("syndrawcast") then
		OnCastW(spell)
	elseif spell.name:lower():find("syndraw") then
		OnCastWB(spell)
	elseif spell.name:lower():find("syndrae") or spell.name:lower():find("syndrae5") then
		OnCastE(spell)
	end
end
if (Menu.Harass.Enabled or Menu.Harass.Enabled2) and Menu.Harass.PP then
		if unit.team ~= myHero.team then
		    if unit.type == myHero.type and unit ~= nil then
		    	if spell.name:lower():find("attack") then
					Harass(target)
		        end
			end
		end
	end
end
function OnInterruptSpell(unit, spell)
	if GetDistanceSqr(unit.visionPos, myHero.visionPos) < E.rangeSqr and E:IsReady() then
		
		if Q:IsReady() then
			if unit.charName ~= "Warwick" then StartEQCombo(unit, false)
			else StartEQCombo(spell.endPos, false) end
			if Menu.Debug.DebugCast then PrintChat("Interrupt, EQ to unit pos") end
		else
			if unit.charName ~= "Warwick" then E:Cast(unit.visionPos.x, unit.visionPos.z)
			else E:Cast(spell.endPos.x, spell.endPos.z) end
			if Menu.Debug.DebugCast then PrintChat("Interrupt, E to unit pos") end
		end

	elseif GetDistanceSqr(unit.visionPos,  myHero.visionPos) < QERange * QERange and Q:IsReady() and E:IsReady() then
		if unit.charName ~= "Warwick" then StartEQCombo(unit)
		else StartEQCombo(spell.endPos) end
		if Menu.Debug.DebugCast then PrintChat("Interrupt, EQ to unit pos") end
	end 
end

function OnGapclose(unit, data)
	if E:IsReady() and GetDistanceSqr(unit) < E.rangeSqr * 4 then
		Qdistance = 300
		StartEQCombo(unit, true)
	end
end

function OnCastQ(spell)
	local BallInfo = {
						added = false, 
						object = {valid = true, x = spell.endPos.x, y = myHero.y, z = spell.endPos.z},
						startT = os.clock() + math.max(0, 0.25 - GetDistance(myHero.visionPos, spell.endPos)/1500) - GetLatency()/2000,
						endT = os.clock() + BallDuration + 1 - GetLatency()/2000
					 }

	table.insert(Balls, BallInfo)
	if os.clock() - QECombo < 1.5 then
		CastSpell(_E, spell.endPos.x, spell.endPos.z)
		QECombo = 0
	end
	Qdistance = nil
	EQTarget = nil
	EQCombo = 0
end
local DPP = nil
function OnCastW(spell)
	if not VIP_USER then WTrack = 0 end
end
function OnCastWB(spell)
	WTrack = 1
end
function OnCastE(spell)
--[[
	if os.clock() - EQCombo < 1.5 and EQTarget then
		DelayAction(function(t) Cast2Q(EQTarget) end, 0.6, {EQTarget})
	end
]]
end

function StartEQCombo(unit, Qfirst)
	if (Menu.EQ.Order == 1 or Qfirst == false) and Qfirst ~= true then
		EQCombo = os.clock()
		EQTarget = unit
		Cast2Q(EQTarget)
		E:Cast(unit.visionPos.x, unit.visionPos.z)
		if Menu.Debug.DebugCast then PrintChat("Cast E to ball pos in direction of enemy (EQCombo)") end
	else 
		QECombo = os.clock()
		Cast2Q(unit)
	end
end

function Cast2Q(target)
	if not Q:IsReady() then return end
	if GetDistanceSqr(target) > Q.rangeSqr then
		EQ.delay = Q.delay
		local spos = Vector(myHero.visionPos) + Menu.EQ.Range * (Vector(target) - Vector(myHero.visionPos)):normalized()
		EQ:SetSource(spos)

		local QEtargetPos, Hitchance, Position = EQ:GetPrediction(target)
		local pos = Vector(myHero.visionPos) + Menu.EQ.Range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
		Q:Cast(pos.x, pos.z)
		if Menu.Debug.DebugCast then PrintChat("Cast Q to max alllowed distance in the direction of enemy (EQCombo)") end
	else
		if Qdistance then
			local pos = Vector(myHero.visionPos) + Qdistance * (Vector(target) - Vector(myHero.visionPos)):normalized()
			Q:Cast(pos.x, pos.z)
			if Menu.Debug.DebugCast then PrintChat("Cast Q in direction of enemy (EQ Combo)") end
		else
			Q:Cast(target)
			if Menu.Debug.DebugCast then PrintChat("Cast Q on enemy (EQ Combo)") end
		end
	end
end

function UseSpells(UseQ, UseW, UseE, UseEQ, UseR, target)
	local Qtarget = STS:GetTarget(Q.range)
	local Wtarget = STS:GetTarget(W.range)
	local QEtarget = STS:GetTarget(QERange)
	local Rtarget = STS:GetTarget(R.range)
	local DFGUsed = false
	if target then
		Qtarget = target
		Wtarget = target
		QEtarget = target
	end

	if (os.clock() - DontUseRTime < 10) then
		UseR = false
	end
	if UseW then
		if Wtarget and W.status == 1 then
			if not VIP_USER then 
				W:Cast(Wtarget)
				if Menu.Debug.DebugCast then PrintChat("Cast W on target in combo") end
			end
			if WObject ~= nil and (WObject.charName == nil or WObject.charName:lower() ~= "heimertblue") then --Don't throw the giant tower :D
				W:Cast(Wtarget)
				if Menu.Debug.DebugCast then PrintChat("Cast W on target in combo") end
			end
		elseif Wtarget and W.status == 0 then
			local validball = GetWValidBall()
			if validball and validball.object then
				W:Cast(validball.object.x, validball.object.z)
				if Menu.Debug.DebugCast then PrintChat("Cast W on ball") end
			elseif validball then
				W:Cast(Wtarget)
				if Menu.Debug.DebugCast then PrintChat("Cast W on target for get W object") end
			end
		end

		if not Qtarget and QEtarget and E:IsReady() and W.status == 1 and (WObject and WObject.name and WObject.name:find("Seed")) then
			--Update the EQ speed and the range
			EQ.delay = Q.range / E.speed + E.delay 
			local QEtargetPos, Hitchance, Position = EQ:GetPrediction(QEtarget)
			local pos = Vector(myHero.visionPos) + W.range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
			if QEtargetPos and GetDistance(QEtargetPos, pos) <= (-0.6 * W.range + 966) then
				WECombo = os.clock()
				if Menu.Debug.DebugCast then PrintChat("Throw ball in WE combo") end
				W:Cast(pos.x, pos.z)
				DelayAction(function() E:Cast(pos.x, pos.z) end, Delays[_W])
			end
		end
	end

	if UseQ then
		if Qtarget and os.clock() - W:GetLastCastTime() > 0.25 and os.clock() - E:GetLastCastTime() > 0.25 then
			VP.ShotAtMaxRange = true
			Q.speed = (Speeds[_Q]*tonumber(Menu.Misc.PRQ))
			--local QtargetPos, hitchance = VP:GetCircularAOECastPosition(Qtarget, Delays[_Q], Widths[_Q], Ranges[_Q], (Speeds[_Q]*tonumber(Menu.Misc.PRQ)), myHero)
			local QtargetPos, hitchance = Q:GetPrediction(Qtarget)
			if QtargetPos and hitchance and hitchance>=2 then
				Q:Cast(QtargetPos.x, QtargetPos.z)
				DrawPrediction = QtargetPos
				if Menu.Debug.DebugCast then PrintChat("Cast Q on target in combo") end
			end
			Q.speed = Speeds[_Q]
			VP.ShotAtMaxRange = false
		end
	end

	if UseEQ then
		if not Qtarget and QEtarget and E:IsReady() and Q:IsReady() then--E + Q at max range
			--Update the EQ speed and the range
			EQ.delay = Q.range / E.speed 
			local QEtargetPos, Hitchance = EQ:GetPrediction(QEtarget)
			local pos = Vector(myHero.visionPos) + Q.range * (Vector(QEtargetPos) - Vector(myHero.visionPos)):normalized()
			if GetDistance(QEtargetPos, pos) <= (-0.6 * Q.range + 966) then
				StartEQCombo(QEtarget)
			end
		end
	end

	if UseE and WECombo == 0 then
		--Check to stun people with E
		local validballs = GetValidBalls()
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				local tmp1, tmp2, enemyPos = VP:GetPredictedPos(enemy, 0.25, QESpeed, myHero.visionPos, false)
				if enemyPos and enemyPos.z then
					for i, ball in ipairs(validballs) do
						if GetDistanceSqr(ball.object, myHero.visionPos) < Q.rangeSqr then
							local Delay = E.delay + GetDistance(myHero.visionPos, ball.object) / E.speed
							local QESpeed = Speeds[_QE]
							local EP = Vector(ball.object) +  (100+(-0.6 * GetDistance(ball.object, myHero.visionPos) + 966)) * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
							local SP = Vector(ball.object) - 100 * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
							local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(SP, EP, enemyPos)
							if isOnSegment and GetDistanceSqr(pointLine, enemyPos) <= (Widths[_QE] + VP:GetHitBox(enemy))^2 then
								CastSpell(_E, ball.object.x, ball.object.z)
								if Menu.Debug.DebugCast then PrintChat("Cast E to ball in direction of enemys in combo") end
							end
						end
					end
				end
			end
		end
	end

	if Rtarget and UseR then
		if IsKillable(Qtarget, GetCombo()) or (os.clock() - UseRTime < 10) then
			--ItemManager:CastOffensiveItems(Rtarget)
			CastItem(ItemManager:GetItem("DFG"):GetId(), Rtarget)
			CastItem(3188, Rtarget)
			DFG = ItemManager:GetItem("DFG"):GetSlot() or GetInventorySlotItem(3188)
			if DFG and myHero:CanUseSpell(DFG) == READY then
				DFGUsed = true
			end
		end

		if _IGNITE and GetDistanceSqr(Qtarget.visionPos, myHero.visionPos) < 600 * 600 and (IsKillable(Rtarget, GetCombo())  or (os.clock() - UseRTime < 10)) then
			CastSpell(_IGNITE, Rtarget)
			if Menu.Debug.DebugCast then PrintChat("Cast ignite on target") end
		end
	end
	if UseR and not Q:IsReady() and R:IsReady() and not DFGUsed then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) and (not Menu.R.Targets[enemy.hash] or (os.clock() - UseRTime < 10)) and GetDistanceSqr(enemy.visionPos, myHero.visionPos) < R.rangeSqr then
				if IsKillable(enemy, GetCombo())  or (os.clock() - UseRTime < 10) then
					if not IsKillable(enemy, {_Q, _E, _W}) and IsKillable(enemy, GetCombo()) or (os.clock() - UseRTime < 10) then
						if not HasBuff(enemy, "UndyingRage") and not HasBuff(enemy, "JudicatorIntervention") then
							R:Cast(enemy)
							if Menu.Debug.DebugCast then PrintChat("UR FACE MY BALLS (R in combo) to target: " .. enemy.charName) end
						end
					end
				end
			end
		end
	end
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function Farm()
	if (Menu.Farm.ManaCheck > (myHero.mana / myHero.maxMana) * 100 and Menu.Farm.LaneClear) or (Menu.Farm.ManaCheck2 > (myHero.mana / myHero.maxMana) * 100 and Menu.Farm.Freeze) then return end
	EnemyMinions:update()
	local UseQ = Menu.Farm.LaneClear and (Menu.Farm.UseQ >= 3) or (Menu.Farm.UseQ == 2 or Menu.Farm.UseQ == 4)
	local UseW = Menu.Farm.LaneClear and (Menu.Farm.UseW >= 3) or (Menu.Farm.UseW == 2 or Menu.Farm.UseW == 4)
	local UseE = Menu.Farm.LaneClear and (Menu.Farm.UseE >= 3) or (Menu.Farm.UseE == 2 or Menu.Farm.UseE == 4)
	
	local CasterMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) and GetDistanceSqr(t) < W.rangeSqr end)
	local MeleeMinions = SelectUnits(EnemyMinions.objects, function(t) return (t.charName:lower():find("basic") or t.charName:lower():find("cannon")) and ValidTarget(t) and GetDistanceSqr(t) < W.rangeSqr end)
	
	if UseW and W:IsReady() then
		if W.status == 0 then
			if #MeleeMinions > 1 then
				W:Cast(MeleeMinions[1].x, MeleeMinions[1].z)
				if Menu.Debug.DebugCast then PrintChat("Cast W to first melee minion") end
			elseif #CasterMinions > 1 then
				W:Cast(CasterMinions[1].x, CasterMinions[1].z)
				if Menu.Debug.DebugCast then PrintChat("Cast W to first caster minion") end
			end
		else
			local BestPos1, BestHit1 = GetBestCircularFarmPosition(Ranges[_W], Widths[_W]*1.1, CasterMinions)
			local BestPos2, BestHit2 = GetBestCircularFarmPosition(Ranges[_W], Widths[_W]*1.1, MeleeMinions)

			if BestHit1 > 2 or (BestPos1 and #CasterMinions <= 2) then
				W:Cast(BestPos1.x, BestPos1.z)
				if Menu.Debug.DebugCast then PrintChat("Cast W on best hit position (Caster)") end
			elseif BestHit2 > 2 or (BestPos2 and #MeleeMinions <= 2) then
				W:Cast(BestPos2.x, BestPos2.z)
				if Menu.Debug.DebugCast then PrintChat("Cast W on best hit position (Melee)") end
			end
		end
	end

	if UseQ and ( not UseW or W.status == 0 ) and Q:IsReady() then
		CasterMinions = GetPredictedPositionsTable(VP, CasterMinions, Delays[_Q], Widths[_Q], Ranges[_Q] + Widths[_Q], math.huge, myHero, false)
		MeleeMinions = GetPredictedPositionsTable(VP, MeleeMinions, Delays[_Q], Widths[_Q], Ranges[_Q] + Widths[_Q], math.huge, myHero, false)

		local BestPos1, BestHit1 = GetBestCircularFarmPosition(Ranges[_Q] + Widths[_Q], Widths[_Q], CasterMinions)
		local BestPos2, BestHit2 = GetBestCircularFarmPosition(Ranges[_Q] + Widths[_Q], Widths[_Q], MeleeMinions)

		if BestPos1 and BestHit1 > 1 then
			CastSpell(_Q, BestPos1.x, BestPos1.z)
			if Menu.Debug.DebugCast then PrintChat("Cast Q on best hit position (Caster)") end
		elseif BestPos2 and BestHit2 > 1 then
			CastSpell(_Q, BestPos2.x, BestPos2.z)
			if Menu.Debug.DebugCast then PrintChat("Cast Q on best hit position (Melee)") end
		end
	end
 
	if UseE and (not Q:IsReady() or not UseQ) and E:IsReady() then
		local AllMinions = SelectUnits(EnemyMinions.objects, function(t) return ValidTarget(t) and GetDistanceSqr(t) < E.rangeSqr end)
		local BestPos, BestHit = GetBestCircularFarmPosition(E.range, Widths[_Q], AllMinions)
		if BestHit > 4 then
			E:Cast(BestPos.x, BestPos.z)
			if Menu.Debug.DebugCast then PrintChat("Cast E if hit >4 minions") end
		else
			local validballs = GetValidBalls()
			local maxcount = 0
			local maxpos

			for i, ball in ipairs(validballs) do
				if GetDistanceSqr(ball.object, myHero.visionPos) < Q.rangeSqr then
					local Count = 0
					for i, minion in ipairs(AllMinions) do
						local EP = Vector(ball.object) +  (100+(-0.6 * GetDistance(ball.object, myHero.visionPos) + 966)) * (Vector(ball.object) - Vector(myHero.visionPos)):normalized()
						local SP = Vector(myHero.visionPos)
						local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(SP, EP, minion)
						if isOnSegment and GetDistanceSqr(pointLine, enemyPos) < Widths[_QE] * Widths[_QE] then
							Count = Count + 1
						end
					end
					if Count > maxcount then
						maxcount = Count
						maxpos = Vector(ball.object)
					end
				end
			end
			if maxcount > 2 then
				E:Cast(maxpos.x, maxpos.z)
				if Menu.Debug.DebugCast then PrintChat("Cast E in farm counting balls") end
			end
		end
	end
end

function JungleFarm()
	JungleMinions:update()
	local UseQ = Menu.JungleFarm.UseQ
	local UseW = Menu.JungleFarm.UseW
	local UseE = Menu.JungleFarm.UseE
	local CloseMinions = SelectUnits(JungleMinions.objects, function(t) return GetDistanceSqr(t) <= W.rangeSqr and ValidTarget(t) end)
	local AllMinions = SelectUnits(JungleMinions.objects, function(t) return ValidTarget(t) end)

	local CloseMinion = CloseMinions[1]
	local FarMinion = AllMinions[1]
	if not CloseMinion and os.clock()-Q:GetLastCastTime()>0.5 then 
		W:__Cast(myHero.x, myHero.z)
	end
	
	if WStatus == "JungleSteal" then
		W:__Cast(myHero.x, myHero.z)
		WStatus = nil
	end
	if ValidTarget(CloseMinion) then
		local selectedTarget = GetTarget()

		if selectedTarget and selectedTarget.type == CloseMinion.type then
			DrawJungleStealingIndicator = true
			SOWi:DisableAttacks()
			if ValidTarget(selectedTarget) and DLib:IsKillable(selectedTarget, {_W}) and GetDistanceSqr(myHero.visionPos, selectedTarget) <= W.rangeSqr and W:IsReady() then
				if WStatus == nil then
					W:__Cast(selectedTarget.x, selectedTarget.z)
					WStatus = "JungleSteal"
				end
			end
		else
			if UseQ and Q:IsReady() then
				Q:__Cast(CloseMinion)
			end
			if UseW then
				local targetBall = nil
				local activeballs = GetValidBalls()
				for i, ball in ipairs(activeballs) do
					targetBall = ball
				end
				if (os.clock()-Q:GetLastCastTime() > Q.delay+0.1) and WStatus == nil and targetBall ~= nil then
					DelayAction(function() return W:__Cast(targetBall.object.x, targetBall.object.z) end, 0.1)
					--W:Cast(targetBall.object.x, targetBall.object.z)
					WStatus = "HaveBall"
				elseif WStatus == "HaveBall" then
					local ValidMinion = nil
					----=== Valid minion
					for i, minion in ipairs(JungleMinions.objects) do
						for j=1, 12 do
							if minion.name == FocusJungleNames[j] then 
								ValidMinion = minion
							end
						end
					end
					if not ValidMinion ~= nil then 
						ValidMinion = CloseMinion 
					end
					----=== Finished
					WStatus = nil
					W:__Cast(ValidMinion.x, ValidMinion.z)
					--W:Cast(myHero.x, myHero.z)
				end
			end
				

			if UseE and os.clock() - Q:GetLastCastTime() > 1 then
				E:__Cast(CloseMinion)
			end
		end
	elseif ValidTarget(FarMinion) and GetDistanceSqr(FarMinion) <= (Q.range + 588)^2 and GetDistanceSqr(FarMinion) > Q.rangeSqr and DLib:IsKillable(FarMinion, {_E}) then
		if Q:IsReady() and E:IsReady() then
			local QPos = Vector(myHero.visionPos) + Q.range * (Vector(FarMinion) - Vector(myHero)):normalized()
			Q:__Cast(QPos.x, QPos.z)
			QECombo = os.clock()
		end
	end	
end

function UpdateSpellData()
	if E.width ~= 2 * Widths[_E] and E:GetLevel() == 5 then
		E.width = 2 * Widths[_E]
	end
	
	if R.range ~= (Ranges[_R] + 75) and R:GetLevel() == 5 then
		R:SetRange(Ranges[_R] + 75)
	end
	if VIP_USER then
		W.status = WObject and 1 or 0
	else 
		W.status = WTrack
	end
end

function Combo()
	W:SetHitChance(Menu.Misc.Whitchance)
	SOWi:DisableAttacks()
	if not Q:IsReady() and (not W:IsReady() or not E:IsReady()) then
		SOWi:EnableAttacks()
	end
	UseSpells(Menu.Combo.UseQ, Menu.Combo.UseW, Menu.Combo.UseE, Menu.Combo.UseEQ, Menu.Combo.UseR)
end

function Harass(target)
	if Menu.Harass.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	UseSpells(Menu.Harass.UseQ, Menu.Harass.UseW, Menu.Harass.UseE, Menu.Harass.UseEQ, false, target)
end

function OnTick()
	DrawPrediction = nil
	W.packetCast = false
	DrawJungleStealingIndicator = false
	BTOnTick()
	SOWi:EnableAttacks()
	DLib.combo = GetCombo()
	UpdateSpellData()--update the spells data
	DrawEQIndicators = false
	--Menu.Debug.DebugW = WTrack or W.status
	--if WTrack == 1 then PrintChat("OLOLOLO") end
	if os.clock() - W:GetLastCastTime() > 1 and not W:IsReady() then
		WStatus = nil
	end
	
	if Menu.Combo.Enabled then
		Combo()
	elseif (Menu.Harass.Enabled or Menu.Harass.Enabled2) and not Menu.Harass.PP then
		Harass()
	end

	if Menu.Farm.LaneClear or Menu.Farm.Freeze then
		Farm()
	end

	if Menu.JungleFarm.Enabled then
		JungleFarm()
	end

	if Menu.R.UseR then
		local Rtarget = STS:GetTarget(R.range)
		if Rtarget then
			R:Cast(Rtarget)
		end
	end

	if Menu.Misc.WPet then
		AutoGrabPets()
	end

	if Menu.R.DontUseR then
		DontUseRTime = os.clock()
		UseRTime = 0
	end

	if Menu.R.CastR then
		UseRTime = os.clock()
		DontUseRTime = 0
	end

	if Menu.Misc.MEQ and Q:IsReady() and E:IsReady() then
		DrawEQIndicators = true
		local PosibleTargets = GetEnemyHeroes()
		local ClosestTargetMouse 
		local closestdist = 200 * 200
		for i, target in ipairs(PosibleTargets) do
			local dist = GetDistanceSqr(mousePos, target)
			if ValidTarget(target) and dist < closestdist then
				ClosestTargetMouse = target
				closestdist = dist
			end
		end
		if ClosestTargetMouse and GetDistanceSqr(ClosestTargetMouse, myHero.visionPos) < (QERange + 300)^2 then
			if GetDistanceSqr(ClosestTargetMouse) < Q.rangeSqr then
				StartEQCombo(ClosestTargetMouse, true)
			else
				StartEQCombo(ClosestTargetMouse)
			end
		end
	end
end

function GetDistanceToClosestHero(p)
	local result = math.huge
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			result = math.min(result, GetDistanceSqr(p, enemy))
		end
	end
	return result
end

myHero.barData = {PercentageOffset = {x = 0, y = 0}}

function OnDraw()
	if DPP ~= nil then DrawCircle3D(DPP.x, myHero.y, DPP.z, 40, 3, ARGB(255, 255, 0, 111), 20) end
	if Menu.Drawings.DrawPredictedHealth then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				DrawIndicator(enemy)
			end
		end
	end
	if Menu.Debug.DebugBall then
		BTOnDraw()
	end
	if DrawEQIndicators then
		DrawCircle3D(mousePos.x, mousePos.y, mousePos.z, 200, 3, GetDistanceToClosestHero(mousePos) < 200 * 200 and ARGB(200, 255, 0, 0) or ARGB(200, 0, 255, 0), 20)--sorry for colorblind people D:
	end

	if GetTarget() and GetTarget().type == 'obj_AI_Minion' and GetTarget().team == TEAM_NEUTRAL then
		DrawCircle3D(GetTarget().x, GetTarget().y, GetTarget().z, 100, 2, Menu.JungleFarm.Enabled and ARGB(175, 255, 0, 0) or ARGB(175, 0, 255, 0), 25) --sorry for colorblind people D:
	end

	if DrawJungleStealingIndicator then
		local pos = GetEnemyHPBarPos(myHero) + Vector(20, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("JungleStealing"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("JungleStealing"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
	end

	if Menu.Harass.Enabled2 then
		local pos = GetEnemyHPBarPos(myHero) + Vector(0, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("AH"), 16, pos.x+1, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("AH"), 16, pos.x, pos.y, ARGB(255, 255, 255, 255))
	end
	if Menu.Harass.PP and (Menu.Harass.Enabled2 or Menu.Harass.Enabled) then
		local pos = GetEnemyHPBarPos(myHero) + Vector(0, -4)
		pos.x = math.floor(pos.x)
		pos.y = math.floor(pos.y)

		DrawText(tostring("PP"), 16, pos.x+20, pos.y+1, ARGB(255, 0, 0, 0))
		DrawText(tostring("PP"), 16, pos.x+20, pos.y, ARGB(255, 255, 255, 255))
	end
	if DrawPrediction ~= nil and Menu.Debug.DebugQ then
		DrawCircle3D(DrawPrediction.x, DrawPrediction.y, DrawPrediction.z, 100, 3, ARGB(200, 255, 111, 111), 20)--sorry for colorblind people D:
	end
end

function IsChasing(target)
	
end
function IsKillable(target, combo)
	for i = 1, target.buffCount do
        local tBuff = target:getBuff(i)
		PrintChat(tBuff.name)
	end
	dmg = DLib:CalcComboDamage(target, combo)	
	if ActDFGed(target) then dmg = dmg*1.2 end
	if target.health <= dmg then
		return true
	else
		return false
	end
end
function ActDFGed(target)
	if TargetHaveBuff("deathfiregraspspell", target) or TargetHaveBuff("itemblackfiretorchspell", target) or GetInventoryItemIsCastable(ItemManager:GetItem("DFG"):GetId()) or GetInventoryItemIsCastable(3188) then
		return true
	else
		return false
	end
end

function DrawIndicator(enemy)
	local damage = DLib:CalcComboDamage(enemy, GetCombo())
	if ActDFGed(enemy) then damage = damage*1.2 end
    local SPos, EPos = GetEnemyHPBarPos(enemy)

    -- Validate data
    if not SPos then return end

    local barwidth = EPos.x - SPos.x
    local Position = SPos.x + math.max(0, (enemy.health - damage) / enemy.maxHealth) * barwidth

    DrawText("|", 16, math.floor(Position), math.floor(SPos.y + 8), ARGB(255,0,255,0))
    DrawText("HP: "..math.floor(enemy.health - damage), 13, math.floor(SPos.x), math.floor(SPos.y), (enemy.health - damage) > 0 and ARGB(255, 0, 255, 0) or  ARGB(255, 255, 0, 0))

end
