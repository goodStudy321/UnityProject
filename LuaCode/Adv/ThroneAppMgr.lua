ThroneAppMgr = {Name="ThroneAppMgr"}
local My = ThroneAppMgr

local TAI = require("Adv/ThroneAppInfo")
local GetErr = ErrorCodeMgr.GetError

function My:Init()
	--信息字典 k:id前5位 v:TransAppInfo
	self.dic = {}
	self.upgCfg = ThroneChangeCfg[1]
	--皮肤属性名称列表
	self.skinPropNames = {}

	self.SkinRedTab = {}

	--红点事件
	self.eRespRed = Event()

	--响应幻化事件
	self.eRespChange = Event()
	--升星/进阶
	self.eStep = Event()
	--响应精炼事件
	self.eRespRefine = Event()
	--响应激活事件
	self.eRespActive = Event()

	--响应状态事件
	self.eRespStatus = Event()

	self:Reset()
	self:AddProto()
	PropMgr.eUpdate:Add(self.UpdatePropNum, self)
	PropTool.SetNames(ThroneChangeLvCfg[1], self.skinPropNames)
end

function My:Reset()
	--当前选择信息Adv
	self.info = nil
	 --幻化ID
	 self.chgID = 0
	 self.status = 0
	 self.isTransRed = false
	 TableTool.ClearDicToPool(self.dic)
	 self:SetDic()
	 TableTool.ClearDic(self.SkinRedTab)
end

--红点状态信息
function My:UpdatePropNum()
	local dic = self.dic
	if dic == nil then return end
	local isRed = false
	TableTool.ClearDic(self.SkinRedTab)
	local info,bid = nil,nil
	for k,v in pairs(dic) do
		info = v
		bid = k
		if self.info == nil then
			self.info = v
		end
		local lock = info.lock
		local sCfg = info.sCfg
		local maxStars = sCfg.stars
		local propId = sCfg.propId
		if propId <= 0 then --满级状态
			self.isTransRed = isRed
			self.eRespRed(isRed,7)
			return
		end
		local propNum = PropMgr.TypeIdByNum(propId)
		if lock == true and propNum > 0 then --未激活状态，可激活红点
			self.SkinRedTab[bid] = info
			isRed = true
		elseif lock == false and maxStars < 5 and propNum > 0 then --可升阶状态
			self.SkinRedTab[bid] = info
			isRed = true
		end
	end
	self.isTransRed = isRed
	self.eRespRed(isRed,7)
end

--设置信息字典
function My:SetDic()
	local dic = self.dic
	local GetKey, GetBID = My.GetKey, My.GetBID
	local id, bid, info = nil, nil , nil
	local BF, OG = BinTool.Find, ObjPool.Get
	local iCfg, iSkinCfg = ThroneChangeCfg, ThroneChangeLvCfg
	for i, v in ipairs(iSkinCfg) do
	  id = v.id
	  bid = GetBID(id)
	  info = dic[bid]
	  if self.info == nil then
		self.info = info
	  end
	  if info == nil then
		info = OG(TAI)
		dic[bid] = info
		info.sCfg = v
		info.skinCfg = iSkinCfg
		info.bCfg = BF(iCfg, bid)
		local maxCId = bid * 100 + 6
		info.sCfgSkill = BF(iSkinCfg, maxCId)
	  end
	end
end

--获取基础ID
function My.GetBID(id)
	local v = id * 0.01
	v = math.floor(v)
	return v
end

--获取前5位字符
function My.GetKey(id)
	local v = My.GetBID(id)
	return v
end

--通过皮肤ID获取基础配置
function My:GetBCfg(id)
	local bid = My.GetBID(id)
	local cfg = BinTool.Find(ThroneChangeCfg, bid)
	return cfg
end

--初始经验
function My:SetInfos(lst)
	if lst == nil or #lst == 0 then return end
	local id , info = nil, nil
	local dic, iSkinCfg = self.dic, ThroneChangeLvCfg
	local iCfg = ThroneChangeCfg
	local isShowRed = false
	local BF = BinTool.Find
	for i, v in ipairs(lst) do
		id = v.id
		bId = self.GetBID(id)
		info = dic[bId]
		info.exp = v.val
		info.bCfg = BF(iCfg, bId)
		info.lock = false
		info.sCfg = BF(iSkinCfg, id)
	end
	self:UpdatePropNum()
end

function My:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
end

function My:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function My:ProtoHandler(Lsnr)
    Lsnr(28030, self.RespInfo, self) -- 上线登陆返回
    Lsnr(28038, self.RespActive, self) -- 皮肤激活返回
    Lsnr(28040, self.RespSkin, self) -- 皮肤进阶返回
    Lsnr(28042, self.RespChange, self) --更换返回
    Lsnr(28044, self.RespStatus, self) --状态返回
end

--登陆时获取信息
function My:RespInfo(msg)
    local mi = msg.throne_info
	self.chgID = mi.cur_id
	self.status = mi.status
	self:SetInfos(mi.surface_list)
	self:IsExistCurThrone()
	AdvMgr.eSkinActive(mi.surface_list)
end

--响应皮肤激活
function My:RespActive(msg)
    local err = msg.err_code
	if self:CheckErr(err) then return end
	local surface = msg.surface
    local info = self:SetInfo(surface)
	local unlock = false
	local id = info.id
	if info.lock then
	  info.lock = false
	  unlock = true
	  AdvMgr.eSkinActive(id)
	end
	self:UpdatePropNum()
	self.eRespActive(id,unlock)
end

--响应皮肤升级
function My:RespSkin(msg)
    local err = msg.err_code
	if self:CheckErr(err) then return end
	local surface = msg.surface
	local info = self:SetInfo(surface)
	local id = info.id
	local unlock = false
	self:UpdatePropNum()
	self.eRespRefine(id, unlock)
end

--响应幻化
function My:RespChange(msg)
    local err = msg.err_code
	if self:CheckErr(err) then return end
	local id = msg.throne_id
	self.chgID = id
	self.eRespChange(err)  
end

--响应状态
function My:RespStatus(msg)
	local status = msg.status
	self.status = status
	self.eRespStatus()
end

function My:SetInfo(surface)
	local id = surface.id
    local k = self.GetKey(id)
	local info = self.dic[k]
	info.exp = surface.val
	if info.id ~= id then
	  info.id = id
	  info.sCfg = BinTool.Find(ThroneChangeLvCfg, id)
	end
	return info
end

--请求激活
--id(number):升阶id
function My:ReqAcive(id)
	local tsASkin= 28037
	local msg = ProtoPool.GetByID(tsASkin)
	if msg == nil then return end
	msg.surface_id = id
	ProtoMgr.Send(msg)
end

--请求进阶
--id(number):升阶id
--propId(number):道具id
function My:ReqStep(id)
	local tsChgID = 28039
	local msg = ProtoPool.GetByID(tsChgID)
	if msg == nil then return end
	msg.surface_id = id
	ProtoMgr.Send(msg)
end

--请求幻化
--id(number):幻化ID
function My:ReqChange(id)
	local tsChgID = 28041
	local msg = ProtoPool.GetByID(tsChgID)
	if msg == nil then return end
	msg.throne_id = id
	ProtoMgr.Send(msg)
end

--请求设置显示状态
--index(number):状态id   0-隐藏，1-使用
function My:ReqStatus(index)
	local tsStatue = 28043
	local msg = ProtoPool.GetByID(tsStatue)
	if msg == nil then return end
	msg.status = index
	ProtoMgr.Send(msg)
end

--判断当前宝座资源是否存在
function My:IsExistCurThrone()
	if self.chgID == 0 or self.chgID == nil then
		return
	end
	local temp = self:GetBCfg(self.chgID)
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
		local id = ThroneCfg[1].id
		id = id * 100 + 1
		ThroneMgr.ReqChange(id)
	end
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return true
    end
    return false
end

function My:GetFight()
    do return User.MapData:GetFightValue(36) end
end

function My:Clear()
	self:Reset()
	PropMgr.eUpdate:Remove(self.UpdatePropNum, self)
end

return My