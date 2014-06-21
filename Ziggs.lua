if myHero.charName ~= "Ziggs" then return end

local version = 0.90
local AUTOUPDATE = true
local SCRIPT_NAME = "Ziggs"
--[[
TODO list
Бросать самого далёкого от всех в ульте к bestPredPos и пересчет //А может ну нах? Так впадлу!
Преды... //DONE?
Логика ульты //ну я хз даже чего сюда влепить...
Force ultimate cast. //А вот эта пимпа должна работать. Вроде пофикшено. Всё равно бросит куда лучше...
TS - Мыш, чемп, дистанция, первейшие //Ну тип привет
Не интерраптить ульт умершего картуса //Ульт? Упорот? Там вродь на него кастовало ( О_о)
???
PROFIT

Explanation to Smart W:
Escape:
1 - simple jump in direction of mouse cursor
2 - smart wall jump, if hero-mouse passing the wall, then i'll come closer to wall for make perfect jump
3 - turret escape, when you're being focused by turret(it begin shooting you), then press Smart W for escape away from turret
]]
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
if FileExist(LIB_PATH.."Prodiction.lua") then
	require("Prodiction")
end
local RequireI = Require("SourceLib")
RequireI:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireI:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireI:Check()

if RequireI.downloadNeeded == true then return end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
local MainCombo

local ComboMode = false
local Wpos = nil
local Wmode = nil

local NCounter = 0

local underTurretFocus
local focusTime = 0
local TUnit = nil
local escapePos = nil

local SelectedTarget = nil

_Combo, _Farm, _JungleClear, _Escape,_EscapeTurret, _Interrupter = 1, 2, 3, 4, 5
_ToMouse, _FromTurret = 0, 1

spellData = {
    [_Q] = { range = 1400, maxRange=1400, skillshotType = SKILLSHOT_LINEAR,   width = 155,  delay = 0.5, 	 speed = 1750,	  collision = false, maxRangeCollision = true },
    [_W] = { range = 970,   			  skillshotType = SKILLSHOT_CIRCULAR, width = 275,  delay = 0.250,   speed = 1800,	  collision = false },
    [_E] = { range = 900,				  skillshotType = SKILLSHOT_CIRCULAR, width = 235,  delay = 0.700,   speed = 2700,    collision = false }, -- width and delay not correct for better hitting
    [_R] = { range = 5300,				  skillshotType = SKILLSHOT_CIRCULAR, width = 525,  delay = 1.014,   speed = 1750,	  collision = false },
}
local EnemyMinions = minionManager(MINION_ENEMY, spellData[_Q].range, myHero, MINION_SORT_MAXHEALTH_DEC)
local JungleMinions = minionManager(MINION_JUNGLE, spellData[_Q].range, myHero, MINION_SORT_MAXHEALTH_DEC)
function OnLoad()
	VP = VPrediction()
	SOWi = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DLib = DamageLib()
	DManager = DrawManager()

	Q = Spell(_Q, spellData[_Q].range, VIP_USER)
	W = Spell(_W, spellData[_W].range, VIP_USER)
	E = Spell(_E, spellData[_E].range, VIP_USER)
	R = Spell(_R, spellData[_R].range, VIP_USER)
	
	Q:SetSkillshot(VP, SKILLSHOT_LINEAR,   spellData[_Q].width, spellData[_Q].delay, spellData[_Q].speed, spellData[_Q].collision)
	W:SetSkillshot(VP, SKILLSHOT_CIRCULAR, spellData[_W].width, spellData[_W].delay, spellData[_W].speed, spellData[_W].collision)
	E:SetSkillshot(VP, SKILLSHOT_CIRCULAR, spellData[_E].width, spellData[_E].delay, spellData[_E].speed, spellData[_E].collision)
	R:SetSkillshot(VP, SKILLSHOT_CIRCULAR, spellData[_R].width, spellData[_R].delay, spellData[_R].speed, spellData[_R].collision)
	
	Q:SetAOE(true, spellData[_Q].width, 0)
	W:SetAOE(true, spellData[_W].width, 0)
	E:SetAOE(true, spellData[_E].width, 0)
	R:SetAOE(true, spellData[_R].width, 0)

	DLib:RegisterDamageSource(_Q,  _MAGIC, 75, 45,   _MAGIC, _AP, 0.65, function() return (player:CanUseSpell(_Q) == READY) end)
	DLib:RegisterDamageSource(_W,  _MAGIC, 70, 45,   _MAGIC, _AP, 0.35, function() return (player:CanUseSpell(_W) == READY) end)
	DLib:RegisterDamageSource(_E,  _MAGIC, 40, 25,   _MAGIC, _AP, 0.30, function() return (player:CanUseSpell(_E) == READY) end)
	DLib:RegisterDamageSource(_R,  _MAGIC, 250, 125, _MAGIC, _AP, 0.90, function() return (player:CanUseSpell(_R) == READY) end)
	
	MainCombo = {ItemManager:GetItem("DFG"):GetId(), _Q, _W, _E, _R, _IGNITE}
	
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
		_IGNITE = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
		_IGNITE = SUMMONER_2
	else
		_IGNITE = nil
	end
	Menu = scriptConfig("Ziggs", "Ziggs")

	Menu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(Menu.Orbwalking)

	Menu:addSubMenu("Target selector", "STS")
		STS:AddToMenu(Menu.STS)

	Menu:addSubMenu("Combo", "Combo")
		Menu.Combo:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("UseR", "Use R", SCRIPT_PARAM_ONOFF, true)
		Menu.Combo:addParam("Enabled", "Make combo!", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	Menu:addSubMenu("Harass", "Harass")
		Menu.Harass:addParam("UseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("UseE", "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.Harass:addParam("ManaCheck", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Harass:addParam("Enabled", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))

	Menu:addSubMenu("Farm", "Farm")
		Menu.Farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_LIST, 1, { "No", "Freeze", "LaneClear", "Both" })	
		Menu.Farm:addParam("UseE",  "Use E", SCRIPT_PARAM_LIST, 4, { "No", "Freeze", "LaneClear", "Both" })
		Menu.Farm:addParam("ManaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		Menu.Farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		Menu.Farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("JungleFarm", "JungleFarm")
		Menu.JungleFarm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)
		Menu.JungleFarm:addParam("UseW",  "Use W", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("UseE",  "Use E", SCRIPT_PARAM_ONOFF, true)
		Menu.JungleFarm:addParam("Enabled", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	Menu:addSubMenu("Ultimate", "R")
		Menu.R:addParam("RNum", "Use R if it will hit(combo): ", SCRIPT_PARAM_LIST, 1, { "No", "1 target", "2 targets", "3 targets", "4 targets", "5 targets" })
		Menu.R:addParam("Rmode", "Cast mode", SCRIPT_PARAM_LIST, 1, { "Cast to first best position", "Cast to best position near mouse", "Cast to best position near hero"})
		Menu.R:addParam("Rdist", "Distance from pos to place", SCRIPT_PARAM_SLICE, 700, 700, 2000)
		Menu.R:addParam("CastR", "Force ultimate cast", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
		Menu.R:addParam("CastRsel", "Cast R on selected target(combo)", SCRIPT_PARAM_ONOFF, true)
		Menu.R:addParam("CastRtokill", "Cast R only when target is killable", SCRIPT_PARAM_ONOFF, false)

	Menu:addSubMenu("Misc", "Misc")
		Menu.Misc:addParam("GETOVERHERE", "Use W to make target come closer", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addParam("MAKETHEHETOUTTAHEREMAN", "Smart W(wall jump, escape)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
		Menu.Misc:addParam("UseIgnite", "Use ignite on killable targets", SCRIPT_PARAM_ONOFF, true)
		Menu.Misc:addSubMenu("Auto-Interrupt", "Interrupt")
			Interrupter(Menu.Misc.Interrupt, OnInterruptSpell)

	Menu:addSubMenu("Drawings", "Drawings")
		--[[Spell ranges]]
		DManager:CreateCircle(myHero,  spellData[_Q].range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "Q Range", true, true, true)
		DManager:CreateCircle(myHero,  spellData[_W].range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "W Range", true, true, true)
		DManager:CreateCircle(myHero,  spellData[_E].range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "E Range", true, true, true)
		DManager:CreateCircle(myHero,  spellData[_R].range, 1, {255, 255, 255, 255}):AddToMenu(Menu.Drawings, "R Range", true, true, true)
		--[[Predicted damage on healthbars]]
		DLib:AddToMenu(Menu.Drawings, MainCombo)
	Menu:addSubMenu("Debug", "Debug")
		Menu.Debug:addParam("DebugQ", "Draw Q prediction", SCRIPT_PARAM_ONOFF, false)
end
function OnInterruptSpell(unit, spell)
	if (GetDistance(unit, myHero) <= (spellData[_W].range+30+spellData[_W].width)) then
		local pos = GVD(myHero.visionPos, GetDistance(unit, myHero)+20, unit)
		W:Cast(pos.x, pos.z)
		WMode = _Interrupter
	end
end
function OnCreateObj(obj)
	if obj.name == "ZiggsW_mis_ground.troy" then
		blowW = true
		Wpos = obj
	end
end

function OnDeleteObj(obj)
	if obj.name == "ZiggsW_mis_ground.troy" then
		blowW = false
		Wpos = nil
		Wmode = nil
	end
end
local DrawPrediction = nil
function OnDraw()
	if DrawPrediction ~= nil and Menu.Debug.DebugQ then
		DrawCircle(DrawPrediction.x, DrawPrediction.y, DrawPrediction.z, 100, RGB(255, 111, 111))--sorry for colorblind people D:
	end
	--DrawCircle(myHero.x, myHero.y, myHero.z, spellData[_R].width, RGB(255, 111, 111))--sorry for colorblind people D:
	DrawPrediction = nil
end
function Combo()
	local Qtarget = STS:GetTarget(spellData[_Q].range)
	local Wtarget = STS:GetTarget(spellData[_W].range)
	local Etarget = STS:GetTarget(spellData[_E].range)
	local Rtarget = STS:GetTarget(spellData[_R].range)
	if Qtarget and DLib:IsKillable(Qtarget, MainCombo) then
		ItemManager:CastOffensiveItems(Qtarget)
	end

	if Wmode == _Combo and Wpos ~= nil and GetDistance(Wpos, Wtarget)<spellData[_W].width-10 then
		W:Cast()
	end
	local castR = true
	if Menu.R.CastRtokill and SelectedTarget ~= nil and not DLib:IsKillable(SelectedTarget, {_R}) then castR = false end
	
	if Qtarget and Q:IsReady() and Menu.Combo.UseQ then
		Cpos, hitchance = Q:GetPrediction(Qtarget)
		if hitchance and hitchance > 1 then
			DrawPrediction = Cpos
			Q:Cast(Cpos.x, Cpos.z)
		end
	end
	
	if Etarget and E:IsReady() and Menu.Combo.UseE and os.clock()-W:GetLastCastTime() > spellData[_W].delay+1.5  then
		if not ComboMode then
			local EtargetPos = E:GetPrediction(Etarget)
			local pos = GVD(myHero.visionPos, GetDistance(Etarget)+20, Etarget.visionPos)
			if GetDistance(EtargetPos)<=GetDistance(pos) then 
				E:Cast(pos.x, pos.z)
			else
				local pos = GVD(myHero.visionPos, GetDistance(EtargetPos)+20, EtargetPos)
				E:Cast(pos.x, pos.z)
			end
		else
			local EtargetPos, hitchance = E:GetPrediction(Etarget)
			if hitchance and hitchance > 1 then
				E:Cast(EtargetPos.x, EtargetPos.z)
			end
		end
	end
	local IgniteTarget = STS:GetTarget(600)
	if IgniteTarget and DLib:IsKillable(Rtarget, MainCombo) and _IGNITE~=nil and Menu.Misc.UseIgnite then
		CastSpell(_IGNITE, IgniteTarget)
	end
	if Wtarget and W:IsReady() and (((os.clock() - R:GetLastCastTime()) >= 2 and not R:IsReady()) or not castR) and Menu.Combo.UseW and (os.clock()-E:GetLastCastTime()) > 1 then
		if Menu.Misc.GETOVERHERE then
			local pred = W:GetPrediction(Wtarget)
			local pos = GVD(myHero.visionPos, GetDistance(Wtarget)+30, Wtarget.visionPos)
			if GetDistance(pred)<=GetDistance(pos) then 
				W:Cast(pos.x, pos.z)
				Wmode = _Combo
			else
				local pos = GVD(myHero.visionPos, GetDistance(pred)+20, pred)
				W:Cast(pos.x, pos.z)
				Wmode = _Combo
			end
		else
			W:Cast(Wtarget)
			Wmode = _Combo
		end
	end
	if Menu.R.CastRsel and SelectedTarget ~= nil and ValidTarget(SelectedTarget, spellData[_R].range) and R:IsReady() and castR and not Menu.R.CastR then
		Cpos, hitchance = R:GetPrediction(SelectedTarget)
		--PrintChat("Ready to cast ulti, hit chance: "..hitchance.." target: "..SelectedTarget.name)
		if hitchance and hitchance > 1 then
			R:Cast(Cpos.x, Cpos.z)
			SelectedTarget = nil
		end
	elseif NCounter > 1 and R:IsReady() then
		local AVH = {}
		for i, enemyHero in ipairs(GetEnemyHeroes()) do
			if enemyHero.bTargetable then table.insert(AVH, enemyHero) end
		end
		local preds = GetPredictedPositionsTable(VP, AVH, spellData[_R].delay, spellData[_R].width, spellData[_R].range, spellData[_R].speed, myHero, false)
		local BestPos, BestHit = GetBestCircularFarmPosition(spellData[_R].range, spellData[_R].width, preds)
		--Menu.R.Rmode "Cast to first best position", "Cast to best position near mouse", "Cast to best position near hero"})
		if Menu.R.Rmode == 2 then 
			if not GetDistance(BestPos, mousePos) <= Menu.R.Rdist then return end
		elseif Menu.R.Rmode == 3 then 
			if not GetDistance(BestPos) <= Menu.R.Rdist then return end
		end
		if BestHit >= NCounter-1 then
			R:Cast(BestPos.x, BestPos.z)
		end		
	end
end

function Harass()
	if Menu.Harass.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	local Qtarget = STS:GetTarget(spellData[_Q].range)
	local Wtarget = STS:GetTarget(spellData[_W].range)
	local Etarget = STS:GetTarget(spellData[_E].range)
	
	if Qtarget and Q:IsReady() and Menu.Harass.UseQ then
		Q:Cast(Qtarget)
	end
	
	if Etarget and E:IsReady() and Menu.Harass.UseE then
		E:Cast(Etarget)
	end
end

function Farm()
	if Menu.Farm.ManaCheck > (myHero.mana / myHero.maxMana) * 100 then return end
	EnemyMinions:update()

	local UseQ = Menu.Farm.LaneClear and (Menu.Farm.UseQ >= 3) or (Menu.Farm.UseQ == 2)
	local UseE = Menu.Farm.LaneClear and (Menu.Farm.UseE >= 3) or (Menu.Farm.UseE == 2)

	if UseQ and Q:IsReady() then
		local BestPos, BestHit = GetBestCircularFarmPosition(spellData[_Q].range, spellData[_Q].width, GetPredictedPositionsTable(VP, EnemyMinions.objects, spellData[_Q].delay, spellData[_Q].width, spellData[_Q].range, spellData[_Q].speed, myHero, false))
		if BestPos and BestHit > 2 then
			Q:Cast(BestPos.x, BestPos.z)
		end
	end
	if UseE and E:IsReady() then
		local BestPos, BestHit = GetBestCircularFarmPosition(spellData[_E].range, spellData[_E].width+15, GetPredictedPositionsTable(VP, EnemyMinions.objects, spellData[_E].delay, spellData[_E].width+15, spellData[_E].range, spellData[_E].speed, myHero, false))
		if BestPos and BestHit > 2 then
			E:Cast(BestPos.x, BestPos.z)
		end
	end
end
------------------------------
function Escape(mode, unit)
	if mode == _ToMouse and Wmode == nil and W:IsReady() then
		Wmode = _Escape
		local pos = GVD(myHero.visionPos, -35, mousePos)
		if not IsPassWall(myHero, mousePos) then 
			SOWi:MoveTo(mousePos.x, mousePos.z)
		else
			jumpPred = GVD(pos, 750, mousePos)
			if not IsWall(D3DXVECTOR3(jumpPred.x, jumpPred.y, jumpPred.z)) and IsPassWall(myHero, jumpPred) then
				SOWi:MoveTo(myHero.x, myHero.z)
			else
				jumpPredPass = GVD(pos, 150, mousePos)
				SOWi:MoveTo(jumpPredPass.x, jumpPredPass.z)
				return 
			end
		end
		W:Cast(pos.x, pos.z)
	elseif mode == _FromTurret and unit ~= nil and W:IsReady() then
		Wmode = _EscapeTurret
		local pos = GVD(myHero.visionPos, 40, unit)
		escapePos = GVD(myHero.visionPos, -450, unit)
		SOWi:MoveTo(escapePos.x, escapePos.z)
		DelayAction(function() W:Cast(pos.x, pos.z) end, 0.1)
	end
end
--------------------------------
function JungleFarm()
	JungleMinions:update()
	if CountEnemyHeroInRange(spellData[_Q].range + spellData[_R].width, myHero) == 1 then
		ComboMode = false
	else
		ComboMode = true
	end
	local UseQ = Menu.JungleFarm.UseQ
	local UseW = Menu.JungleFarm.UseW
	local UseE = Menu.JungleFarm.UseE
	local minion = JungleMinions.objects[1]
	if minion then
		if UseQ and Q:IsReady() then
			local BestPos, BestHit = GetBestCircularFarmPosition(spellData[_Q].range, spellData[_Q].width, GetPredictedPositionsTable(VP, JungleMinions.objects, spellData[_Q].delay, spellData[_Q].width, spellData[_Q].range, spellData[_Q].speed, myHero, false))
			if BestPos and BestHit >= 1 then
				Q:Cast(BestPos.x, BestPos.z)
			end	
		end
		if UseW then
			local BestPos, BestHit = GetBestCircularFarmPosition(spellData[_W].range, spellData[_W].width, GetPredictedPositionsTable(VP, JungleMinions.objects, spellData[_W].delay, spellData[_W].width, spellData[_W].range, spellData[_W].speed, myHero, false))
			local pos = GVD(myHero.visionPos, GetDistance(BestPos)-30, BestPos)
			W:Cast(pos.x, pos.z)
		end
		if UseE and E:IsReady() then
			local BestPos, BestHit = GetBestCircularFarmPosition(spellData[_E].range, spellData[_E].width, GetPredictedPositionsTable(VP, JungleMinions.objects, spellData[_E].delay, spellData[_E].width, spellData[_E].range, spellData[_E].speed, myHero, false))
			E:Cast(BestPos.x, BestPos.z)
		end
	end
end
function IsPassWall(startPos, endPos)
	count = GetDistance(startPos, endPos)
	i=1
	while i < count do
		i = i+10
		local pos = GVD(startPos,  i, endPos)
		if IsWall(D3DXVECTOR3(pos.x, pos.y, pos.z)) then return true end
	end
	return false
end
function OnProcessSpell(unit, spell)
	if string.find(unit.name, "Turret") and spell.target == myHero then
		underTurretFocus = true
		TUnit = unit
		focusTime = os.clock()
	end
end

function OnTick()
	if blowW and Wmode == _Escape then
		W:Cast()
	end
	if not Wpos ~= nil then 
		Wmode = nil 
	end
	if blowW and Wmode ~= _Combo and Wmode ~= _Escape then W:Cast() end
	if Wmode == _EscapeTurret then
		SOWi:MoveTo(escapePos.x, escapePos.z)
	end
	SOWi:EnableAttacks()
	-----------=================
	if Menu.R.CastR then
		NCounter = 2
	else
		NCounter = Menu.R.RNum
	end
	
	if Menu.Combo.Enabled then
		Combo()
	elseif Menu.Harass.Enabled then
		Harass()
	end
	------------================
	if Menu.Misc.MAKETHEHETOUTTAHEREMAN then
		if underTurretFocus then 
			Escape(_FromTurret, TUnit)
		else
			Escape(_ToMouse)
		end
	end
	if Menu.Farm.Freeze or Menu.Farm.LaneClear then
		Farm()
	end

	if Menu.JungleFarm.Enabled then
		JungleFarm()
	end
	
	if (os.clock()-focusTime) > 5 then
		underTurretFocus = false
		TUnit = nil
	end
end
function OnWndMsg(Msg, Key)
	if Msg == WM_LBUTTONDOWN then
		local dist = 0
		local buf = nil
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy) then
				if GetDistance(enemy, mousePos) <= dist or buf == nil then
					minD = GetDistance(enemy, mousePos)
					buf = enemy
				end
			end
		end
		
		if buf and dist < 100 then
			if SelectedTarget and buf.charName == SelectedTarget.charName then
				SelectedTarget = nil
			else
				SelectedTarget = buf
			end
		end
	end
end
function GVD(startPos, distance, endPos)
	return Vector(startPos) + distance * (Vector(endPos)-Vector(startPos)):normalized()
end
