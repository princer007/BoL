--[[[

Feel free using this, but please, report about an "unusual" moves or things

http://botoflegends.com/forum/user/89725-princer007/
Include screenshot and describing of error(what were you doing when it appear)

]]
if myHero.charName ~= "Orianna" then return end

local version = 1.190
local AUTOUPDATE = true
local SCRIPT_NAME = "Orianna"
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
RequireI:Check()

if RequireI.downloadNeeded == true then return end
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local InitiatorsList =
{
["Vi"] = "ViQ",--R
["Vi"] = "ViR",--R
["Malphite"] = "Landslide",--R UFSlash
["Nocturne"] = "NocturneParanoia",--R
["Zac"] = "ZacE",--E
["MonkeyKing"] = "MonkeyKingNimbus",--R
["MonkeyKing"] = "MonkeyKingSpinToWin",--R
["MonkeyKing"] = "SummonerFlash",--Flash
["Shyvana"] = "ShyvanaTransformCast",--R
["Thresh"] = "threshqleap",--Q2
["Aatrox"] = "AatroxQ",--Q
["Renekton"] = "RenektonSliceAndDice",--E
["Kennen"] = "KennenLightningRush",--E
["Kennen"] = "SummonerFlash",--Flash
["Olaf"] = "OlafRagnarok",--R
["Udyr"] = "UdyrBearStance",--E
["Volibear"] = "VolibearQ",--Q
["Talon"] = "TalonCutthroat",--e?
["JarvanIV"] = "JarvanIVDragonStrike",--Q
["Warwick"] = "InfiniteDuress",--R
["Jax"] = "JaxLeapStrike",--Q
["Yasuo"] = "YasuoRKnockUpComboW",--Q
["Diana"] = "DianaTeleport",
["LeeSin"] = "BlindMonkQTwo",
["Shen"] = "ShenShadowDash",
["Alistar"] = "Headbutt",
["Amumu"] = "BandageToss",
["Urgot"] = "UrgotSwap2",
["Rengar"] = "RengarR",
}

--[[Spell data]]
spellData = {
    [_Q] = { range = 800,  skillshotType = SKILLSHOT_LINEAR,   width = 90,  delay = 0, 	   speed = 1800,	  collision = false },
    [_W] = { range = 0,    skillshotType = SKILLSHOT_CIRCULAR, width = 250, delay = 0.25,  speed = math.huge, collision = false },
    [_E] = { range = 1000, skillshotType = SKILLSHOT_LINEAR,   width = 60,  delay = 0.25,  speed = 1400,      collision = true  },
    [_R] = { range = 0,	   skillshotType = SKILLSHOT_CIRCULAR, width = 400, delay = 0.5,   speed = math.huge, collision = false },
}
------------------------------------------------------------------------------------------------
local MainCombo = {_Q, _W, _R, _Q, _IGNITE}
local Far = 1.3

local DrawPrediction = nil
--[[Ball]]
local BallPos
local BallMoving = false

--[[CDS]]
local IGNITEREADY = true

local NCounter = nil


local EnemyMinions = minionManager(MINION_ENEMY, spellData[_Q].range, myHero, MINION_SORT_MAXHEALTH_DEC)
local JungleMinions = minionManager(MINION_JUNGLE, spellData[_Q].range, myHero, MINION_SORT_MAXHEALTH_DEC)
--[[VPrediction]]
local VP

local Menu = nil

local SelectedTarget = nil

local DamageToHeros = {}
local lastrefresh = 0

local ComboMode
local _ST, _TF  = 1,2

local LastChampionSpell = {}

function OnLoad()
	Menu = scriptConfig("Orianna", "Orianna")
	BallPos = myHero
	--[[Spells]]
	spellQ = Spell(_Q, spellData[_Q].range, false)
	spellW = Spell(_W, spellData[_W].range, false)
	spellE = Spell(_E, spellData[_E].range, false)
	spellR = Spell(_R, spellData[_R].range, false)
	--[[Combo]]

	VP = VPrediction()
	SOWi = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	DManager = DrawManager()
	
	Menu:addSubMenu("Orbwalking", "Orbwalking")
	SOWi:LoadToMenu(Menu.Orbwalking)
	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)
	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseRN", "Use R at least in", SCRIPT_PARAM_LIST, 1, { "1 target", "2 targets", "3 targets", "4 targets" , "5 targets"})
		Menu.Combo:addParam("UseI", "Use Ignite if enemy is killable", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Normal combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("UseW", "Auto-W if it will hit", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
		Menu.Misc:addParam("UseR", "Auto-ultimate if it will hit", SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
		Menu.Misc:addParam("EQ", "Use E + Q if tEQ < %x * tQ", SCRIPT_PARAM_SLICE, 100, 0, 200)
		Menu.Misc:addParam("PaR", "Cast R if hit 1 enemy in combo(hold)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))
		Menu.Misc:addParam("AARange", "NOT CONFIGURABLE", SCRIPT_PARAM_SLICE, 300, 300, 300)
		Menu.Misc:addSubMenu("Auto-E on initiators", "AutoEInitiate")
		local added = false
		for champion, spell in pairs(InitiatorsList) do
			for i, ally in ipairs(GetAllyHeroes()) do
				if ally.charName == champion then
					added = true
					Menu.Misc.AutoEInitiate:addParam(champion..spell, champion.." ("..spell..")", SCRIPT_PARAM_ONOFF, true)
				end
			end
		end
	
		if not added then
			Menu.Misc.AutoEInitiate:addParam("info", "Info", SCRIPT_PARAM_INFO, "Not supported initiators found")
		else
			Menu.Misc.AutoEInitiate:addParam("Active", "Active", SCRIPT_PARAM_ONOFF, true)
		end
		Menu.Misc:addSubMenu("Auto-Interrupt", "Interrupt")
			Interrupter(Menu.Misc.Interrupt, OnInterruptSpell)
		--Menu.Misc:addParam("BlockR", "Block R if it is not going to hit", SCRIPT_PARAM_ONOFF, true)

	--[[Harassing]]
	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF , true)
		Menu.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, false)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		Menu.Harass:addParam("Enabled2", "Harass (TOGGLE)!", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
	
	--[[Farming]]
	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 4, { "No", "Freezing", "LaneClear", "Both" })
		Menu.Farm:addParam("UseW",  "Use W", SCRIPT_PARAM_LIST, 3, { "No", "Freezing", "LaneClear", "Both" })
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 3, { "No", "Freezing", "LaneClear", "Both" })
		Menu.Farm:addParam("ManaCheck", "Don't laneclear if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Freeze", "Farm Freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
	
	--[[Jungle farming]]
	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Enabled", "Farm jungle!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
	
	--[[Drawing]]
	Menu:addSubMenu("Drawing", "Drawing")
	--[[
		DManager:CreateCircle(myHero,  spellData[_Q].range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawing, "Q Range", true, true, true)
		DManager:CreateCircle(BallPos, spellData[_W].width, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawing, "W Range", true, true, true)
		DManager:CreateCircle(myHero,  spellData[_E].range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawing, "E Range", true, true, true)
		DManager:CreateCircle(BallPos, spellData[_R].width, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawing, "R Range", true, true, true)
		DManager:CreateCircle(myHero,  tonumber(Menu.Misc.AARange),   1, {255, 255, 255, 255}):AddToMenu(Menu.Drawing, "AA Distance", true, true, true)
	]]
		Menu.Drawing:addParam("AADistance", "Draw AA distance", SCRIPT_PARAM_ONOFF, false)
		Menu.Drawing:addParam("Qrange", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
		Menu.Drawing:addParam("Wrange", "Draw W radius", SCRIPT_PARAM_ONOFF, false)
		Menu.Drawing:addParam("Erange", "Draw E radius", SCRIPT_PARAM_ONOFF, false)
		Menu.Drawing:addParam("Rrange", "Draw R radius", SCRIPT_PARAM_ONOFF, false)
		Menu.Drawing:addParam("DrawBall", "Draw ball position", SCRIPT_PARAM_ONOFF, true)
		DLib:AddToMenu(Menu.Drawing, MainCombo)
	Menu:addSubMenu("Debug", "Debug")
		Menu.Debug:addParam("DebugQ",  "Draw Q prediction", SCRIPT_PARAM_ONOFF, false)
	Menu:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)
	spellW:SetAOE(true)
	spellR:SetAOE(true)
	local passiveDmg = {10, 10, 10, 18, 18, 18, 26, 26, 26, 34, 34, 34, 42, 42, 42, 50, 50, 50}
	DLib:RegisterDamageSource(_Q, _MAGIC, 30,  30,  _MAGIC, _AP, 0.5, function() return spellQ:IsReady() end)
	DLib:RegisterDamageSource(_W, _MAGIC, 35, 45, _MAGIC, _AP, 0.7, function() return spellW:IsReady() end)
	DLib:RegisterDamageSource(_E, _MAGIC, 30,  30,  _MAGIC, _AP, 0.3, function() return spellE:IsReady() end)
	DLib:RegisterDamageSource(_R, _MAGIC, 75, 75, _MAGIC, _AP, 0.15, function() return spellR:IsReady() end)
	--DLib:RegisterDamageSource(_AA, _PHYSICAL, 0, 0, _PHYSICAL, _AP, 0, function() return SOWi:CanAttack() end, function() return myHero.totalDamage+passiveDmg[myHero.lvl] end)
	
	
 	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		_IGNITE = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		_IGNITE = SUMMONER_2
	else
		_IGNITE = nil
	end
	PrintChat("<font color=\"#81BEF7\">[Orianna] Command: Load</font>")
end

--[[Check the number of enemies hit by casting W]]
function CheckEnemiesHitByW()
	local enemieshit = {}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local position = VP:GetPredictedPos(enemy, spellData[_W].delay)
		if ValidTarget(enemy) and GetDistance(position, BallPos) <= spellData[_W].width and GetDistance(enemy.visionPos, BallPos) <= spellData[_W].width then
			table.insert(enemieshit, enemy)
		end
	end
	return #enemieshit, enemieshit
end

--[[Check the number of enemies hit by casting E]]
function CheckEnemiesHitByE(To)
	local enemieshit = {}
	local StartPoint = Vector(BallPos.x, 0, BallPos.z)
	local EndPoint = Vector(To.x, 0, To.z)
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local cp, hc, position = VP:GetLineCastPosition(enemy, spellData[_E].delay, spellData[_E].width, math.huge, spellData[_E].speed, StartPoint)
		if position then
			local PointInLine, tmp, isOnSegment = VectorPointProjectionOnLineSegment(StartPoint, EndPoint, position)
			if ValidTarget(enemy) and isOnSegment and GetDistance(PointInLine, position) <= (spellData[_E].width + VP:GetHitBox(enemy)) and GetDistance(PointInLine, enemy.visionPos) < (spellData[_E].width) * 2 + 30 then
				table.insert(enemieshit, enemy)
			end
		end
	end
	return #enemieshit, enemieshit
end

--[[Check number of enemies hit by casting R]]
function CheckEnemiesHitByR()
	local enemieshit = {}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local position = VP:GetPredictedPos(enemy, spellData[_R].delay)
		if ValidTarget(enemy) and GetDistance(position, BallPos) <= spellData[_R].width and GetDistance(enemy.visionPos, BallPos) <= 1.25 * spellData[_R].width  then
			table.insert(enemieshit, enemy)
		end
	end
	return #enemieshit, enemieshit
end

function CastQ(target, fast)
	local Speed = spellData[_Q].speed
	local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(target, spellData[_Q].delay, spellData[_Q].width, spellData[_Q].range, Speed, BallPos)
	local CastPoint = CastPosition
	if (HitChance < 2) then return end
	DrawPrediction = CastPoint

	if GetDistance(myHero.visionPos, Position) > spellData[_Q].range + spellData[_W].width + VP:GetHitBox(target) then
		target2 = GetBestTarget(spellData[_Q].range, target)
		if target2 then
			CastPosition,  HitChance,  Position = VP:GetLineCastPosition(target2, spellData[_Q].delay, spellData[_Q].width, spellData[_Q].range, Speed, BallPos)
			CastPoint = CastPosition
	DrawPrediction = CastPoint
		else
			do return end
		end
	end

	if GetDistance(myHero.visionPos, Position) > (spellData[_Q].range + spellData[_W].width + VP:GetHitBox(target))  then
		do return end
	end

	if spellE:IsReady() and Menu.Misc.EQ ~= 0 then
		local TravelTime = GetDistance(BallPos, CastPoint) / spellData[_Q].speed
		local MinTravelTime = GetDistance(myHero, CastPoint) / spellData[_Q].speed + GetDistance(myHero, BallPos) / spellData[_E].speed
		local Etarget = myHero

		for i, ally in ipairs(GetAllyHeroes()) do
			if ValidTarget(ally, spellData[_E].range, false) then
				local t = GetDistance(ally, CastPoint) / spellData[_Q].speed + GetDistance(ally, BallPos) / spellData[_E].speed
				if t < MinTravelTime then
					MinTravelTime = t
					Etarget = ally
				end
			end
		end


		if MinTravelTime < (Menu.Misc.EQ / 100) * TravelTime and (not Etarget.isMe or GetDistance(BallPos, myHero) > 100) and GetDistance(Etarget) < GetDistance(CastPoint) then
			CastE(Etarget)
			do return end
		end
	end
	if GetDistanceSqr(myHero.visionPos, CastPoint) < spellData[_Q].range^2 then
		spellQ:Cast(CastPoint.x, CastPoint.z)
	else
		CastPoint = Vector(myHero.visionPos) + spellData[_Q].range * (Vector(CastPoint) - Vector(myHero)):normalized()
		spellQ:Cast(CastPoint.x, CastPoint.z)
	end
end

function CastW()
	local hitcount, hit = CheckEnemiesHitByW()
	if hitcount >= 1 then
		spellW:Cast()
	end
end

function CastE(target)
	if target then
		spellE:Cast(target)
	end
end

function CastECH(target, n)
	local hitcount, hit = CheckEnemiesHitByE(target)
	if hitcount >= n then
		CastE(target)
	end
end

function CastR(target)
	local position = VP:GetPredictedPos(target, spellData[_R].delay)
	if GetDistance(position, BallPos) < spellData[_R].width and GetDistance(target, BallPos) < spellData[_R].width then
		spellR:Cast()
	end
end

function GetNMinionsHit(Pos, radius)
	local count = 0
	for i, minion in pairs(EnemyMinions.objects) do
		if GetDistance(minion, Pos) < radius then
			count = count + 1
		end
	end
	return count
end

function GetNMinionsHitE(Pos)
	local count = 0
	local StartPoint = Vector(Pos.x, 0, Pos.z)
	local EndPoint = Vector(myHero.x, 0, myHero.z)
	for i, minion in pairs(EnemyMinions.objects) do
		local position = Vector(minion.x, 0, minion.z)
		local PointInLine = VectorPointProjectionOnLineSegment(StartPoint, EndPoint, position)
		if GetDistance(PointInLine, position) < spellData[_E].width then
			count = count + 1
		end
	end
	return count
end

function Farm(Mode)
	local UseQ
	local UseW
	local UseE
	if not SOWi:CanMove() then return end

	EnemyMinions:update()
	if Mode == "Freeze" then
		UseQ =  Menu.Farm.UseQ == 2
		UseW =  Menu.Farm.UseW == 2 
		UseE =  Menu.Farm.UseE == 2 
	elseif Mode == "LaneClear" then
		UseQ =  Menu.Farm.UseQ == 3
		UseW =  Menu.Farm.UseW == 3 
		UseE =  Menu.Farm.UseE == 3 
	end
	
	UseQ =  Menu.Farm.UseQ == 4 or UseQ
	UseW =  Menu.Farm.UseW == 4  or UseW
	UseE =  Menu.Farm.UseE == 4 or UseE
	
	if UseQ and spellQ:IsReady() then
		if UseW then
			local MaxHit = 0
			local MaxPos = 0
			for i, minion in pairs(EnemyMinions.objects) do
				if GetDistance(minion) <= spellData[_Q].range then
					local MinionPos = VP:GetPredictedPos(minion, spellData[_Q].delay, spellData[_Q].speed, BallPos)
					local Hit = GetNMinionsHit(minion, spellData[_W].width)
					if Hit >= MaxHit then
						MaxHit = Hit
						MaxPos = MinionPos
					end
				end
			end
			if MaxHit > 0 and MaxPos then
				spellQ:Cast(MaxPos.x, MaxPos.z)
			end
		else
			for i, minion in pairs(EnemyMinions.objects) do
				if minion.health + 15 < DLib:CalcSpellDamage(minion, _Q) and not SOWi:InRange(minion) then
					local MinionPos = VP:GetPredictedPos(minion, spellData[_Q].delay, spellData[_Q].speed, BallPos)
					spellQ:Cast(MinionPos.x, MinionPos.z)
					break
				end
			end
		end
	end

	if UseW and spellW:IsReady() then
		local Hit = GetNMinionsHit(BallPos, spellData[_W].width)
		if Hit >= 3 then
			spellW:Cast()
		end
	end
	
	if UseE and spellE:IsReady() then
		local Hit = GetNMinionsHitE(BallPos)
		if Hit >= 3 and (not spellW:IsReady() or not UseW) then
			CastE(myHero)
		end
	end
end

function FarmJungle()
	JungleMinions:update()
	local UseQ = Menu.JungleFarm.UseQ 
	local UseW = Menu.JungleFarm.UseW 
	local UseE = Menu.JungleFarm.UseE 
	
	local Minion = JungleMinions.objects[1] and JungleMinions.objects[1] or nil
	
	if Minion then
		local Position = VP:GetPredictedPos(Minion, spellData[_Q].delay, spellData[_Q].speed, BallPos)
		if UseQ and spellQ:IsReady() then
			spellQ:Cast(Position.x, Position.z)
		end
		
		if UseW and spellW:IsReady() and GetDistance(BallPos, Minion) < spellData[_W].width then
			spellW:Cast()
		end
		
		if UseE and (not spellW:IsReady() or not UseW) and spellE:IsReady() and GetDistance(Minion) < 700 then
			local starget = myHero
			local dist = GetDistanceSqr(Minion)
			for i, ally in ipairs(GetAllyHeroes()) do
				local dist2 = GetDistanceSqr(ally, Minion)
				if ValidTarget(ally, spellData[_E].range, false) and dist2 < dist then
					dist = dist2
					starget = ally
				end
			end
			CastE(starget)
		end
	end
end

function FindBestLocationToQ(target)
	local points = {}
	local targets = {}
	
	local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(target, spellData[_Q].delay, spellData[_Q].width, spellData[_Q].range, spellData[_Q].speed, BallPos)
	table.insert(points, Position)
	table.insert(targets, target)
	
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, spellData[_Q].range + spellData[_R].width) and enemy.networkID ~= target.networkID then
			CastPosition,  HitChance,  Position = VP:GetLineCastPosition(enemy, spellData[_Q].delay, spellData[_Q].width, spellData[_Q].range, spellData[_Q].speed, BallPos)
			table.insert(points, Position)
			table.insert(targets, enemy)
		end
	end
	

	for o = 1, 5 do
		local MECa = MEC(points)
		local Circle = MECa:Compute()
		
		if Circle.radius <= spellData[_R].width and #points >= 3 and spellR:IsReady() then
			return Circle.center, 3
		end
	
		if Circle.radius <= spellData[_W].width and #points >= 2 and spellW:IsReady() then
			return Circle.center, 2
		end
		
		if #points == 1 then
			return Circle.center, 1
		elseif Circle.radius <= (spellData[_Q].width + 50) and #points >= 1 then
			return Circle.center, 2
		end
		
		local Dist = -1
		local MyPoint = points[1]
		local index = 0
		
		for i=2, #points, 1 do
			if GetDistance(points[i], MyPoint) >= Dist then
				Dist = GetDistance(points[i], MyPoint)
				index = i
			end
		end
		if index > 0 then
			table.remove(points, index)
		end
	end
end


function GetBestTarget(Range, Ignore)
	local LessToKill = 100
	local LessToKilli = 0
	local target = nil
	
	local target = STS:GetTarget(Range)
	
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, Range) and (Ignore == nil or (Ignore.networkID ~= SelectedTarget.networkID)) then
		target = SelectedTarget
	end
	
	return target
end

function OnTickChecks()
	DrawPrediction = nil
	IGNITEREADY = _IGNITE and myHero:CanUseSpell(_IGNITE) == READY or false
	--[[When the ball reaches an ally]]
	for i,ally in ipairs(GetAllyHeroes()) do
		if TargetHaveBuff("orianaghostself", ally) then
			BallMoving = false
			BallPos = ally
		end
	end
	if CountEnemyHeroInRange(spellData[_Q].range + spellData[_R].width, myHero) == 1 then
		ComboMode = _ST
	else
		ComboMode = _TF
	end

	
	if Menu.Misc.UseW > 1 and spellW:IsReady() then
		local hitcount, hit = CheckEnemiesHitByW()
		if hitcount >= (Menu.Misc.UseW -1) then
			spellW:Cast()
		end		
	end
	
	if Menu.Misc.UseR > 1 and spellR:IsReady() then
		local hitcount, hit = CheckEnemiesHitByR()
		if (hitcount >= (Menu.Misc.UseR - 1)) and GetDistanceToClosestAlly(BallPos) < spellData[_Q].range * Far then
			spellR:Cast()
		end		
	end
	
	if Menu.Misc.AutoEInitiate.Active and spellE:IsReady() then
		for i, unit in ipairs(GetAllyHeroes()) do
			if GetDistance(unit) < spellData[_E].range then
				for champion, spell in pairs(InitiatorsList) do
					if LastChampionSpell[unit.networkID] and LastChampionSpell[unit.networkID].name ~=nil and Menu.Misc.AutoEInitiate[champion.. LastChampionSpell[unit.networkID].name] and (os.clock() - LastChampionSpell[unit.networkID].time < 1.5) then
						spellE:Cast(Unit)
					end
				end
			end
		end
	end
end

function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local minD = 0
		local starget = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= minD or starget == nil then
					minD = GetDistance(enemy, mousePos)
					starget = enemy
				end
			end
		end
		
		if starget and minD < 100 then
			if SelectedTarget and starget.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = starget
				print("<font color=\"#FF0000\">Orianna: New target selected: "..starget.charName.."</font>")
			end
		end
	end
end

function Harass(target)
	if Menu.Harass.UseQ and target then
		CastQ(target)
	end
	if Menu.Harass.UseW then
		CastW()
	end
end

function GetDistanceToClosestAlly(p)
	local d = GetDistance(p, myHero)
	for i, ally in ipairs(GetAllyHeroes()) do
		if ValidTarget(ally, math.huge, false) then
			local dist = GetDistance(p, ally)
			if dist < d then
				d = dist
			end
		end
	end
	return d
end

function CountAllyHeroInRange(range, point)
	local n = 0
	for i, ally in ipairs(GetAllyHeroes()) do
		if ValidTarget(ally, math.huge, false) and GetDistanceSqr(point, ally) <= range * range then
			n = n + 1
		end
	end
	return n
end

function Combo(target)
		if Menu.Combo.UseI and target and _IGNITE and IGNITEREADY and GetDistanceSqr(target.visionPos, myHero.visionPos) < 600 * 600 and DLib:IsKillable(target, MainCombo) then
			CastSpell(_IGNITE, target)
		end
    -- TODO: Single target / team fight checks
    if SINGLE_TARGET then
        if target and ((GetDistanceSqr(target) > tonumber(Menu.Misc.AARange)^2) or ((player.health/player.maxHealth <= 0.25) and (player.health/player.maxHealth < target.health/target.maxHealth))) then
            SOWi:DisableAttacks()
		end

        if target and Menu.Combo.UseR and CountEnemyHeroInRange(1000, target) >= CountAllyHeroInRange(1000, target)  then
            if target and DLib:CalcComboDamage(target, MainCombo) > target.health and GetDistanceToClosestAlly(BallPos) < spellData[_Q].range * Far then
                local hitcount, hit = CheckEnemiesHitByR()
                if hitcount >= NCounter then
                    spellR:Cast()
                end
            end
        end

        if Menu.Combo.UseW then
            CastW()
        end
        
        if Menu.Combo.UseQ and target then
            CastQ(target)
        end
        
        if Menu.Combo.UseE then
            for i, ally in ipairs(GetAllyHeroes()) do
                if ValidTarget(ally, math.huge, false) and GetDistance(ally) < spellData[_E].range and CountEnemyHeroInRange(400, ally) >= 1 and (target == nil or GetDistance(ally, target) < 400) then
                    CastE(ally)
                end
            end
        end
        
        if Menu.Combo.UseE then
            CastECH(player, 1)
        end
    else
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) and (GetDistanceSqr(enemy) < tonumber(Menu.Misc.AARange)^2) and (player.health/player.maxHealth <= 0.25) then
                SOWi:DisableAttacks()
            end
        end
        if Menu.Combo.UseR then
            if CountEnemyHeroInRange(800, BallPos) > 1 then
                local hitcount, hit = CheckEnemiesHitByR()
                local potentialkills, kills = 0, 0
                if hitcount >= 2 then
                    for i, champion in ipairs(hit) do
                        if (champion.health - DLib:CalcComboDamage(champion, MainCombo)) < 0.4*champion.maxHealth or (DLib:CalcComboDamage(champion, MainCombo) >= 0.4*champion.maxHealth) then
                            potentialkills = potentialkills + 1
                        end
                        if (champion.health - DLib:CalcComboDamage(champion, MainCombo)) < 0 then
                            kills = kills + 1
                        end
                    end
                end
				if ((GetDistanceToClosestAlly(BallPos) < spellData[_Q].range) and (hitcount >= CountEnemyHeroInRange(spellData[_R].width, BallPos) or potentialkills >= 2 or kills >= 1) and hitcount >= NCounter) then
                    spellR:Cast()
                end
            elseif NCounter == 1 then
                if (Menu.Misc.PaR and target) or (target and DLib:CalcComboDamage(target, {_Q, _W, _R}) > target.health and GetDistanceToClosestAlly(BallPos) < spellData[_Q].range * Far) then
					CastR(target)
                end
            end
        end
        
        if Menu.Combo.UseW then
            CastW()
        end
        if target and SOWi:InRange(target) then
            SOWi:ForceTarget(target)
        end

        if Menu.Combo.UseQ and target then
            local Qposition, hit = FindBestLocationToQ(target)
            
            if Qposition and hit > 1 then
                spellQ:Cast(Qposition.x, Qposition.z)
            else
                CastQ(target)
            end
        end
        
        if Menu.Combo.UseE and spellE:IsReady() then
            if CountEnemyHeroInRange(800, BallPos) <= 2 then
                CastECH(player, 1)
            else
                CastECH(player, 2)
            end
            
            
            for i, ally in ipairs(GetAllyHeroes()) do
                if ValidTarget(ally, spellData[_E].range, false) and CountEnemyHeroInRange(300, ally) >= 3 and (target == nil or GetDistance(ally, target) < 300) then
                    CastE(ally)
                end
            end
        end
    end

end

function OnTick()
	DManager:OnDraw()
	OnTickChecks()
	SOWi:EnableAttacks()
	SOWi:ForceTarget()
	if Menu.Misc.PaR then
		NCounter = 1
	else
		NCounter = Menu.Combo.UseRN
	end
	local target = GetBestTarget(spellData[_Q].range + spellData[_Q].width)
	if not target then
		target = GetBestTarget(spellData[_Q].range + spellData[_Q].width * 2)
	end
	if Menu.Combo.Enabled then
		Combo(target)
	elseif (Menu.Harass.Enabled or Menu.Harass.Enabled2) and (Menu.Harass.ManaCheck <= (myHero.mana / myHero.maxMana * 100)) then
		Harass(target)
	end

	if Menu.Farm.Freeze or Menu.Farm.LaneClear then
		local Mode = Menu.Farm.Freeze and "Freeze" or "LaneClear"
		if Menu.Farm.ManaCheck >= (myHero.mana / myHero.maxMana * 100) then
			Mode = "Freeze"
		end

		Farm(Mode)
	end
	
	if Menu.JungleFarm.Enabled then
		FarmJungle()
	end
end

function OnDraw()
	if Menu.Drawing.AADistance then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, tonumber(Menu.Misc.AARange), 1, ARGB(255, 0, 255, 0), 180)
	end

	if Menu.Drawing.Qrange then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, spellData[_Q].range, 1, ARGB(255, 0, 255, 0), 180)
	end

	if Menu.Drawing.Erange then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, spellData[_E].range, 1, ARGB(255, 0, 255, 0), 180)
	end

	if Menu.Drawing.Wrange then
		DrawCircle3D(BallPos.x, BallPos.y, BallPos.z, spellData[_W].width, 1, ARGB(255, 0, 255, 0), 180)
	end

	if Menu.Drawing.Rrange then
		DrawCircle3D(BallPos.x, BallPos.y, BallPos.z, spellData[_R].width, 1, ARGB(255, 0, 255, 0), 180)
	end

	if Menu.Drawing.DrawBall then
		DrawCircle3D(BallPos.x, BallPos.y, BallPos.z, 100, 1, ARGB(255, 0, 255, 0), 180)
	end
	if DrawPrediction ~= nil and Menu.Debug.DebugQ then
		DrawCircle3D(DrawPrediction.x, DrawPrediction.y, DrawPrediction.z, 100, 3, ARGB(200, 255, 111, 111), 20)--sorry for colorblind people D:
	end
end
------------------------------------------------------------------------------------------------
-----------------------------============LISTENERS====================--------------------------
------------------------------------------------------------------------------------------------

--[[Ball location]]
function OnCreateObj(obj)
	--[[Casting Q creates this object when ball lands]]
        if obj.name:lower():find("yomu_ring_green") then
                BallPos = obj
                BallMoving = false
        end
        
        --[[When ball goes out of range it returns to Orianna and creates this object]]
        if (obj.name:lower():find("orianna_ball_flash_reverse")) then
            BallPos = myHero
			BallMoving = false
        end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name:lower():find("orianaizunacommand") then--Q
		BallMoving = true
		DelayAction(function(p) BallPos = Vector(p) end, GetDistance(spell.endPos, BallPos) / spellData[_Q].speed - GetLatency()/1000 - 0.35, {Vector(spell.endPos)})
	end

	if unit.isMe and spell.name:lower():find("orianaredactcommand") then--E
		BallMoving = true
		BallPos = spell.target
	end
	
	if unit.type == "obj_AI_Hero" then
		LastChampionSpell[unit.networkID] = {name = spell.name, time=os.clock()}
	end
end
--[[End of ball location]]
function OnInterruptSpell(unit, spell)
	if GetDistanceSqr(unit.visionPos, myHero.visionPos) < (spellData[_Q].range^2+(spellData[_R].width^2)) and spellR:IsReady() then
		if spellQ:IsReady() then
			spellQ:Cast(unit.visionPos.x, unit.visionPos.z)
		else
			if not BallMoving then
				spellR:Cast()
			end
		end
	end
end
