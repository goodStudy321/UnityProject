--region PetMgr.lua
--Date
--此文件由[HS]创建生成

PetMgr = {Name="PetMgr"}
local M = PetMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr
local Players = UnityEngine.PlayerPrefs

local UpLvSound = 112
--注册的事件回调函数
M.eUpdatePetStepExp = Event()
M.eUpdatePetUseJingpoItem = Event()
M.eUpdatePetStep = Event()
M.eUpdatePetStepChange = Event()
M.ePetChangeEquip = Event()
M.eUpdatePetExp = Event()
M.eUpdatePetDev = Event()
M.PetDevRed = false

function M:Init()
	self.SysID = 3

	--宠物资质丹药ids
	local qualIDs = self:GetQualIds(PetJingPoTemp)
	--宠物数量
	self.Len = self:GetLen()
	self.flag = PropsFlag:New()
	self.flag:Init(ItemsCfg[4].ids,qualIDs,nil,3)
	--开启技能类型
	self.OpenSkillsType = {}
	--属性名
	self.ProStr = {}
	self:Clear()
	-- self:InitSkills()
	self:InitPro()
	self:AddProto()
end

function M:GetQualIds(iQualCfg)
	local qualTab = {}
	for k,v in pairs(iQualCfg) do
		if qualTab[v.id] == nil then
			qualTab[v.id] = v
		end
	end
	return qualTab
end

function M:InitSkills()
	local tab = {}
	for i,v in ipairs(PetStepTemp) do
		local list = v.skills
		local open = v.open
		local len = #list
		for i=1,len do
			local id = list[i]
			if id then
				local key = tostring(id)
				if not tab[key] then
					tab[key] = id
					table.insert(self.Skills,id)
				end
				if open then
					local key = tostring(open)
					if not self.OpenSkills[key] then
						self.OpenSkills[key] = v.id
					end
					if not self.OpenSkillsType[key] then
						self.OpenSkillsType[key] = v.type
					end
				end
			end
		end
	end
end

function M:InitPro()
	local temp = PetStepTemp[1]
	PropTool.SetNames(temp, self.ProStr)
	--PropTool.SetNames(self.iSkinCfg[2], self.skinPropNames)
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
	PropMgr.eUpdate:Add(self.PetDevRedState,self)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
	PropMgr.eUpdate:Remove(self.PetDevRedState,self)
end

function M:ProtoHandler(Lsnr)
	Lsnr(20286, self.RespPetInfo, self)	
	Lsnr(20288, self.RespPetStepExp, self)	
	Lsnr(20290, self.RespPetSpiritUpdate, self)	
	Lsnr(20294, self.RespPetLevelUp, self)	
	Lsnr(20296, self.RespPetStepUp, self)	
	Lsnr(20298, self.RespPetChange, self)	
end

--宠物数据
function M:RespPetInfo(msg)
	self:UpdatePetData(msg.level, msg.exp, msg.step_exp, msg.cur_id, msg.pet_id)
	local sList = msg.pet_spirits
	local sLen = #sList
	for i=1,sLen do
		local data = sList[i]
		if data then
			self:UpdatePetUseJingpoItem(data.id, data.val)
		end
	end
	self:IsFullStep(msg.cur_id,msg.pet_id,sList,msg.step_exp)
	self:IsExistCurPet()
end

--宠物进阶精华
function M:RespPetStepExp(msg)
	self:UpdatePetStepExp(msg.exp)
	self.eUpdatePetStepExp(true)
end

--宠物精魄更新
function M:RespPetSpiritUpdate(msg)
	local data = msg.pet_spirit
	if not data then return end
	self:UpdatePetUseJingpoItem(data.id, data.val)
	self.eUpdatePetUseJingpoItem()
end

--宠物吞噬装备升级
function M:RespPetLevelUp(msg)
	if not CheckErr(msg.err_code) then return end
	-- self:UpdatePetLevel(msg.level)
	self:UpdatePetExp(msg.exp)
	-- self:PetDevRedState()
	self.eUpdatePetExp()
end

--宠物进阶
function M:RespPetStepUp(msg)
	if msg.err_code > 0 then
		self.flag.needExp = nil
		self.flag.isFullStep = true
		self.flag:Update()
	end
	if not CheckErr(msg.err_code) then return end
	local step = msg.new_pet_id
	local petStar = step % 10
	local isMaxStep = self:IsMaxStep(step)
	if isMaxStep and petStar == 0 then
		self.flag.needExp = nil
		self.flag.isFullStep = true
		self.flag:Update()
		return
	end
	self:UpdatePetStepExp(msg.new_step_exp)
	self:UpdatePetStepChange(msg.new_pet_id)
	self.eUpdatePetStep(true)
end

--宠物幻化
function M:RespPetChange(msg)
	if not CheckErr(msg.err_code) then return end
	self:UpdatePetChange(msg.cur_id)
	self.ePetChangeEquip()
end

--判断当前宠物资源是否存在
function M:IsExistCurPet()
	local index = self:GetCurIndex()
	if index < 1 then return end
	local temp  = PetTemp[index]
	if not temp then return end
	local modeId = temp.uMod
	local mod = temp.mod
	modeId = tostring(modeId)
	mod = tostring(mod)
	local modeTemp = RoleBaseTemp[modeId]
	local mode = RoleBaseTemp[mod]
	local modePath = modeTemp.path
	local path = mode.path
	local isExist = AssetTool.IsExistAss(modePath)
	local isScExist = AssetTool.IsExistAss(path)
	if isExist == true and isScExist == true then
		return
	elseif isExist == false or isScExist == false then
		self:ReqPetChange(PetStepTemp[1].id)
	end
end

---------------------------------------------------------------------
--判断是否显示红点
function M:IsFullStep(curId,step,sList,curExp)
	local petStep = (step / 100) % 10
	petStep = math.modf(petStep)
	-- local petStepCfg = BinTool.Find(PetStepTemp, step)
	-- local petStep = petStepCfg.step
	local petStar = step % 10

	local isFullStep = false
	local isFullQual = true
	local qualTab = self.flag.getQualById
	local isFullQualTab = self.flag.isFullQualTab
	local sLen = #sList
	for i=1,sLen do
		local data = sList[i]
		local k = data.id
		local usedNum = data.val
		local maxUseNum = AdvMgr:GetUseMax(qualTab[k])
		if usedNum >= maxUseNum then
			isFullQual = false
			isFullQualTab[k].isFull = true
		end
	end
	-- if sList == nil or sLen <= 0 then
	-- 	isFullQual = false
	-- end

	local curExp = curExp
	local curCfg = self:GetPetStepTempOfStepID(step)
	local needExp = curCfg.costSoul
	local exp = needExp - curExp
	self.flag.needExp = exp

	local isMaxStep = self:IsMaxStep(step)

	petStep = math.modf(petStep)
	petStar = math.modf(petStar)
	if isMaxStep and petStar == 0 then
		isFullStep = true
	end
	self.flag.isFullStep = isFullStep
	self.flag.isFullQual = isFullQual
	self.flag.isFullQualTab = isFullQualTab
	self.flag:Update()
end

function M:IsMaxStep(step)
	local isMax = false
	local tempLen = #PetStepTemp
	local tempLenCfg = PetStepTemp[tempLen]
	if tempLenCfg.id == step then
		isMax = true
	end
	return isMax
end

---------------------------------------------------------------------

---------------------------------------------------------------------
--请求宠物吞噬装备升级
function M:ReqPetLevelUp(list)
	local msg = ProtoPool.GetByID(20293)
	for i,v in ipairs(list) do
		msg.goods_list:append(v.id)
	end
	Send(msg)
end

--请求宠物吞噬装备升级
function M.OnReqPetLevelUp(list)
	local msg = ProtoPool.GetByID(20293)
	for i,v in ipairs(list) do
		msg.goods_list:append(v.id)
	end
	Send(msg)
end

--请求宠物幻化
function M:ReqPetChange(id)
	local msg = ProtoPool.GetByID(20297)
	msg.cur_id = id * 100 + 1
	Send(msg)
end

----------------------------------------------------------------------


---------------------------------

--更新数据
function M:UpdatePetData(lv, exp, stepExp, cur, step)
	self:UpdatePetLevel(lv)
	self:UpdatePetExp(exp)
	self:UpdatePetStepExp(stepExp)
	self:UpdatePetChange(cur)
	self:UpdatePetStepChange(step)
	self:PetDevRedState()
end

--伙伴吞噬红点状态
--togVal == true :不再提醒吞噬
--修改吞噬逻辑到背包
function M:PetDevRedState(togVal)
	if togVal == nil then
		togVal = false
	end
	-- local curQ = ItemQuality.All
	-- local curS = ItemStep.All

	-- if Players.HasKey("ShowDev") then
    --     local togIndex = Players.GetInt("ShowDev")
    --     if togIndex == 1 then
    --         togVal = true
    --     else
    --         togVal = false
	-- 	end
	-- else
	-- 	togVal = false
	-- end
	-- if Players.HasKey("IntQ") then
	-- 	local qValue = Players.GetInt("IntQ")
	-- 	curQ = qValue
	-- end

	-- if Players.HasKey("IntS") then
	-- 	local sValue = Players.GetInt("IntS")
	-- 	curS = sValue
	-- end

	local petDItem = PropMgr.GetQUARANKSTART(100, 100, 0)
	local len = #petDItem
	local isPetDev = false
	if len > 0 and togVal == false then
		isPetDev = true
	end
	self.PetDevRed = isPetDev
	self.eUpdatePetDev(isPetDev,8)
end

--判断是否开启吞噬
function M:IsOpenDevour()
	local isOpen = true
	local limit = GlobalTemp["149"].Value1[1].id
    local curState = RobberyMgr.curState
    local curStateCfg = RobberyMgr:GetCurCfg(limit)
	local name = curStateCfg.floorName
	if limit > curState then
		isOpen = false
	end
	return curStateCfg,isOpen
end

--更新使用状态
function M:UpdatePetUseJingpoItem(id, val)
	local isFullQualTab = self.flag.isFullQualTab
	local qualTab = self.flag.getQualById
	local kid = id
	if qualTab[kid] then
		local usedNum = val
		local maxUseNum = AdvMgr:GetUseMax(qualTab[kid])
		if usedNum >= maxUseNum then
			isFullQualTab[kid].isFull = true
		end
	end
	self.flag.isFullQualTab = isFullQualTab
	self.flag:Update()

	local key = tostring(id)
	self.UserDataDic[key] = val
end

--宠物幻化更新
function M:UpdatePetChange(id)
	if id == 0 then
		local temp = PetTemp[1]
		if temp then
			id = temp.id * 100 +1
		end
	end
	self.CurID = id
end

--宠物等阶更新
function M:UpdatePetStepChange(id)
	if id == 0 then
		local temp = PetTemp[1]
		if temp then
			id = temp.id * 100 +1
		end
	end
	local curid = math.floor(self.StepID / 100)
	local newid = math.floor(id / 100)
	if newid > curid then
		self.StepID = id
		self.eUpdatePetStepChange()
		Audio:PlayByID(UpLvSound, 1)
		return
	end
	self.StepID = id
end

--更新精华
function M:UpdatePetStepExp(stepExp)
	self.StepExp = stepExp
end

--更新经验
function M:UpdatePetExp(exp)
	self.Exp = exp
end

--更新宠物等级
function M:UpdatePetLevel(lv)
	if self.Level and lv > self.Level then
		UITip.Error(string.format("伙伴等级提升到%s级", lv))
	end
	self.Level = lv
	if self.PetLvTemplate == nil or self.PetLvTemplate.Lv ~= lv then
		self.PetLvTemplate = PetLvTemp[tostring(lv)]
		if self.PetLvTemplate == nil then return end
		self.LimitExp = self.PetLvTemplate.costExp
	end
end

-------------------------
function M:GetCurIndex()
	local curid = self.StepID 
	if curid and curid ~= 0 then
		local id = math.floor(curid / 100)
		local len = #PetTemp
		for i=1,len do
			local temp = PetTemp[i]
			if temp.id == id then
				return i
			end
		end
	end
	return 1
end

--------------------------

function M:GetChangeIndex()
	local curid = self.CurID 
	if curid and curid ~= 0 then
		local id = math.floor(curid / 100)
		local len = #PetTemp
		for i=1,len do
			local temp = PetTemp[i]
			if temp.id == id then
				return i
			end
		end
	end
	return 1
end

function M:GetLen()
	local index = 0
	local len = #PetTemp
	for i=1,len do
		local temp = PetTemp[i]
		if temp.type == 0 then
			index = index + 1
		end
	end
	return index
end

--增加属性
function M:AddProperty(key, value)
	if value == nil or value == nil then return end
	if not self.ProDic[key] then self.ProDic[key] = 0 end
	self.ProDic[key] = self.ProDic[key] + value
end

--更新属性
function M:UpdateProperty(info)
    self:AddProperty("Attack", info.atk)
end

function M:GetPetTempOfStepID(stepid)
	local id = math.floor(tonumber(stepid)/100)
	for i,v in ipairs(PetTemp) do
		if v.id == id then return v end
	end
	return nil
end

function M:GetPetStepTempOfStepID(stepid)
	local id = tonumber(stepid)
	for i,v in ipairs(PetStepTemp) do
		if v.id == id then return v end
	end
	return nil
end

function M:IsLimitPage(temp)
	local id = temp.id
	local curid = math.floor(self.StepID / 100)
	if id - curid > 1 then return true end
	return false
end

--特殊处理，打开养成伙伴升级界面
function M:OpenPetExpUI()
	local open = OpenMgr:IsOpen("3") or false--判断伙伴是否开启
	if open == false then
		UITip.Log("系统未开启")
		return
	end
	UIMgr.Open(UIAdv.Name,M.AdvCb)
end

function M.AdvCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:SwtichBySysID(3)
		ui.openDic["3"].ExeView:SetActive(true)
	end
end

function M:Clear()
	--当前幻化id
	self.CurID = 0
	--等阶id
	self.StepID = 0
	--等级
	self.Level = nil
	--等级上限
	self.LimitLv = 0
	--经验
	self.Exp = 0
	--经验上限
	self.LimitExp = 0
	--精魄
	self.StepExp = 0
	--战斗力
	self.Fight = 0
	--所有技能列表
	self.Skills = {}
	--开启技能等阶
	self.OpenSkills = {}
	--使用状态
	self.UserDataDic = {}
	--当前等级配置
	self.PetLvTemplate = nil
	self.PetDevRed = false
	self:InitSkills()
end

function M:Dispose()
	self:RemoveProto()
end

return M