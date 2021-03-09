--region UserMgr.lua
--Date
--此文件由[HS]创建生成

UserMgr = {Name="UserMgr"}
local M = UserMgr

M.eCreateAccount = Event()
M.eBlackAccount = Event()
M.eLvEvent = Event()	--只更新增长的
M.eLvUpdate = Event()   --设置等级就更新
M.eAddBuff = Event()
M.eDelBuff = Event()
M.eUpdateData = Event()

local data = User.MapData
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr
local Prop = PropTool

function M:Init()
	self:InitData()
	self:AddEvent()
end

function M:InitData()
	self.ChannelID = nil
	self.GameChannelID = nil
	self.BuffList = {}
	self.RebirthLv = GlobalTemp["91"]
	self.RoleLv = GlobalTemp["90"]

	--化神等级阈值,超过此等级为化神
	self.GodLvVpt = 999
end

function M:AddEvent()
   	local EH = EventHandler
   	self.lvFunc = EH(self.ChangeLvHandler, self)
   	self.lvUpdateFunc = EH(self.UpdateLvHandler, self)
   	self.DelBuff = EH(self.OnDelBuff, self)
   	self.AddBuff = EH(self.OnAddBuff, self)
	self.OpenUIToName = EH(self.OnOpenUIToName, self)

	self:Event(EventMgr.Add)
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveEvent()
	self:Event(EventMgr.Remove)
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:Event(E)
	E("OnChangeLv", self.lvFunc)
	E("OnUpdateLv", self.lvUpdateFunc)
	E("DelBuff", self.DelBuff)
	E("AddBuff", self.AddBuff)
	E("OpenUIToName",self.OpenUIToName)
end

function M:ProtoHandler(Lsnr)
	Lsnr(20014, self.RespRoleObserve, self)	
end
------------------------------------------------------------------
function M:RespRoleObserve(msg)
	local err = msg.err_code
	if err~=0 then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	self.OtherInfo = {}
	local info = self.OtherInfo
	info.id = msg.role_id
	info.name = msg.role_name
	info.lv = msg.level
	info.vip = msg.vip_level
	info.sex = msg.sex
	info.cate = msg.category
	info.relive = msg.relive_level
	info.familyId = msg.family_id
	info.familyName = msg.family_name
	info.familyTitle = msg.family_title
	info.power = msg.power
	info.skins = {}
	info.basePro = {}
	info.others = {}
	info.equips = {}
	local skinList = msg.skin_list
	local sLen = #skinList
	for i=1,sLen do
		table.insert(info.skins, skinList[i])
	end
	local roleBase = msg.role_base
	-- local rLen = #roleBase
	for k,v in pairs(roleBase) do
		info.basePro[k]=v
	end
	local otherList = msg.decorations
	local oLen = #otherList
	for i=1,oLen do
		table.insert(info.others, otherList[i])
	end

	local equipList = msg.equip_list
	local eLen = #equipList
	for i=1, eLen do
		local data = EquipMgr.ParseEquip(equipList[i])
		if data then
			table.insert(info.equips, data)
		end
	end
	info.charm = msg.charm
	info.title = msg.title
	info.mount = msg.mount
	info.magicw = msg.magic_weapon
	info.godw = msg.god_weapon
	info.pet = msg.pet


	local rGuard = ObjPool.Get(PropTb)
	info.rGuard = rGuard
	rGuard.type_id=msg.r_guard.id
	rGuard.startTime=0
	rGuard.endTime=msg.r_guard.val

	local lGuard = ObjPool.Get(PropTb)
	info.lGuard = lGuard
	lGuard.type_id=msg.l_guard.id
	lGuard.startTime=0
	lGuard.endTime=msg.l_guard.val

	info.knot_id = msg.knot_id
	self.eUpdateData()
end

function M:ReqRoleObserve(id,iscross)
	if not iscross then iscross=false end
	local msg = ProtoPool.GetByID(20013)
	msg.role_id = id
	msg.is_cross=iscross
	Send(msg)
end
------------------------------------------------------------------
function M:ChangeLvHandler(lv)
	self.eLvEvent()
end

function M:UpdateLvHandler()
	self.eLvUpdate()
end

function M:OnDelBuff(id)
	local key = tostring(id)
	local data = self.BuffList[key]
	table.remove(self.BuffList, key)
	self.eDelBuff(id)
end

--value 叠加数量
function M:OnAddBuff(id, startTime, endTime, value)
	local key = tostring(id)
	local buff = BuffTemp[key]
	if not buff then return end
	local data = {}
	data.Temp = buff
	data.StartTime = startTime
	data.EndTime = endTime
	data.Value = value
	self.BuffList[key] = data
	self.eAddBuff(data)
end

function M:OnOpenUIToName(name)
	UIMgr.Open(name)
end
-----------------------------------------------------

function M:GetAccount()
	if Sdk then 
		if Sdk.uid == "0" then
			iTrace.sLog("hs","SDK有问题")
			 return nil 
		end
		return Sdk.uid
	 end
	 return User.Account 
end

function M:GetChannelId()
	if Sdk then
		return User.ChannelID
	end
	return "0"
end

function M:GetGameChannelID()
	if Sdk then
		return User.GameChannelId
	end
	return "0"
end

function M:MD5()
	if Sdk then
		return "gateway-auth-key"
	end
	return "gateway-auth-key"
end

--獲得等級/化神等级
-- num == true 返回巅峰等级数值
function M:GetLv(num)
	if num == nil then num = false end
	if data then
		local lv = data.Level
		local rolelv = self.RoleLv.Value3
		if lv <= rolelv or RebirthMsg.RbLev < self.RebirthLv.Value3 then
			return tostring(data.Level)
		else
			local l = lv - rolelv
			if num == true then
				return l
			end
			return string.format( "化神%s级",l)
		end
	end
	if num == true then
		return
	end
	return "1"
end
--转换化神等级
function M:chageLv(lv)
	local rolelv = self.GodLvVpt
	if lv > rolelv then
		lv = lv - rolelv
		return string.format( "化神%s级",lv)
	else
		return string.format( "%s级",lv)
	end

end
--转换化神等级
function M:GetChangeLv(lv, isReal, isLabel)
	if isReal == nil then isReal = true end
	if isLabel == nil then isLabel = false end
	local rolelv = self.RoleLv.Value3
	if (lv > rolelv and RebirthMsg.RbLev >= self.RebirthLv.Value3) or isReal == false then
		local l = lv - rolelv
		if l > 0 then
			if isLabel == true then
				return string.format( "化神%s级",l)
			else
				return l
			end
		end
	end
	return lv
end

--真实等级
function M:GetRealLv()
	if data then
		return data.Level
	end
	return 1
end

--达到化神等级获得化神等级反之获得真实等级
function M:GetGodLv()
	local lv = self:GetRealLv()
	local godLvVpt = self.GodLvVpt
	if lv > godLvVpt then
		lv = lv - godLvVpt
	end
	return lv
end

--判断是否达到化神等级
--返回true达到
function M:IsGod(lv)
	if not lv then lv=self:GetRealLv() end
	return lv > self.GodLvVpt
end

--获取境界
function M:GetConfine()
	if data then
		local id = tonumber(data.Confine)
		local confine = BinTool.Find(AmbitCfg,id,"id")
		if confine then
			return confine.stateName
		else
			return ""
		end
	end
end

--获取化神等级
function M:GetToLv(lv)
	local limitLv = GlobalTemp["90"].Value3
	if lv <=limitLv then return lv 
	else return lv-limitLv end
end

----------------------------------------------------
--获取玩家名字
function M:GetName()
	if data then return data.Name end
	return "未知"
end

--获得职业名
function M:GetCareerName(id)
	local career = nil
	if not id then
		if data then
			career = data.Category
		end
	else
		career = tonumber(id)
	end
	return UIMisc.GetWork(career)
end

--获得帮派名
function M:GetFamililyName()
	if data then
		local name = data.FamlilyName
		if not StrTool.IsNullOrEmpty(name) then 
			return name
		end
	end
	return "无"
end

--获取玩家战斗力
function M:GetFight(t)
	local fight = 0
	if data then 
		if t == FightType.All then
			fight = tonumber(data.AllFightValue)
		else
			fight = tonumber(data:GetFightValue(t))
		end
	end
	return CustomInfo:ConvertNum(fight)
end

--获取玩家相对位置
function M:GetPos()
	local pos = User.Pos
	return Vector3.New(pos.x, 0, pos.z)
end

function M:Clear()
	self:InitData()
end

function M:Dispose()
	self:RemoveEvent()
end

return M