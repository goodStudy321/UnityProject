TransAppMgr = {Name="TransAppMgr"}
local My = TransAppMgr
local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

local TAI = require("Data/TransApp/TransAppInfo")
TransAppMgr = Super:New{Name = "TransAppMgr"}
local My = TransAppMgr
local GetErr = ErrorCodeMgr.GetError


function My:Init()
	--信息字典 k:id前5位 v:TransAppInfo
	self.dic = {}
	self.upgCfg = self.iCfg[1]
	--皮肤属性名称列表
	self.skinPropNames = {}

	self.SkinRedTab = {}

	self.isTransRed = false
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
	self:Reset()
	self:AddProto()
	PropTool.SetNames(self.iSkinCfg[1], self.skinPropNames)
end

function My:Reset()
	--当前选择的道具ID
	self.curSelectId = nil
	--当前选择信息Adv
	self.info = nil
	 --幻化ID
	--  self.chgID = 0
	 TableTool.ClearDicToPool(self.dic)
	 self:SetDic()
	 TableTool.ClearDic(self.SkinRedTab)
	 My.isTransRed = false
end

--设置信息字典
function My:SetDic()
	local dic = self.dic
	local GetKey, GetBID = My.GetKey, My.GetBID
	local id, bid, info = nil, nil , nil
	local BF, OG = BinTool.Find, ObjPool.Get
	local iCfg, iSkinCfg = self.iCfg, self.iSkinCfg
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
		local maxCId = bid * 100 + 50
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

--获得皮肤完整的道具ID
function My.GetPIdByBId(BId)
	local v = BId * 100
	return v
end

--获取前5位字符
function My.GetKey(id)
	local v = My.GetBID(id)
	return v
end

  --获得皮肤升级最大ID
function My.GetMaxIdByBId(BId)
	local v = BId * 100 + 10
	return v
end

--通过皮肤ID获取基础配置
function My:GetBCfg(id)
	local bid = My.GetBID(id)
	local cfg = BinTool.Find(self.iCfg, bid)
	return cfg
end

--初始经验
function My:SetInfos(lst)
	if lst == nil or #lst == 0 then return end
	local id , info = nil, nil
	local dic, iSkinCfg = self.dic, self.iSkinCfg
	local iCfg = self.iCfg
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

function My:UpdatePropNum()
	local dic = self.dic
	if dic == nil then return end
	local sysId = self.sysId
	-- if sysId == 2 then --暂时屏蔽伙伴数据
	-- 	iTrace.eError("GS","1111")
	-- end
	local id,info,bid,exp,lock,sCfg,maxStars,needSoul = nil,nil,nil,nil,nil,nil,nil,nil
	local needExp = 0
	local items = self.iItemsIds
	local totalExp = 0
	for i,v in pairs(items) do
		local num1 = PropMgr.TypeIdByNum(v)
		num1 = num1 or 0
		if num1 > 0 then
		  local cfg = ItemData[tostring(v)]
		  local exp1 = cfg.uFxArg[1] * num1
		  totalExp = totalExp + exp1
		end
	end

	local isRed = false
	TableTool.ClearDic(self.SkinRedTab)
	for k,v in pairs(dic) do
		info = v
		bid = k
		if self.info == nil then
			self.info = v
		end
		exp = info.exp
		lock = info.lock
		sCfg = info.sCfg
		maxStars = sCfg.stars
		needSoul = sCfg.costSoul
		needExp = needSoul - exp
		local propId = bid * 100
		local propNum = PropMgr.TypeIdByNum(propId)
		local needNum = sCfg.propNum
		if lock == true and propNum > 0 then --未激活状态，可激活红点
			self.SkinRedTab[bid] = info
			isRed = true
		elseif lock == false and sCfg.propId > 0 and propNum > 0 and propNum >= needNum and maxStars >= 10 then -- 激活状态，已满星 
			self.SkinRedTab[bid] = info
			isRed = true
		elseif lock == false and maxStars < 10 and totalExp >= needExp then --可升阶状态
			local firstNum = PropMgr.TypeIdByNum(items[1])
			local secondNum = PropMgr.TypeIdByNum(items[2])
			if firstNum > 0 or secondNum > 0 then
				self.SkinRedTab[bid] = info
				isRed = true
			end
		end
	end
	self.isTransRed = isRed
	self.eRespRed(isRed,4)
end

function My:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
	PropMgr.eUpdate:Add(self.UpdatePropNum, self)
end

function My:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
	PropMgr.eUpdate:Remove(self.UpdatePropNum, self)
end

function My:ProtoHandler(Lsnr)
		-- iTrace.Error("GS","self.tcSkinID===  20284  ",self.tcSkinID)
		Lsnr(self.tcInfoID, self.RespInfo, self) -- 上线登陆返回
		-- Lsnr(self.tcSkinID, self.RespSkin, self)
		Lsnr(self.tcASkinID, self.RespActive, self) -- 皮肤激活返回
		Lsnr(self.tcStepID, self.RespSkin, self) -- 皮肤进阶返回
		Lsnr(self.tcChgID, self.RespChange, self) --更换返回
end

--登陆时获取信息
function My:RespInfo(msg)
	--iTrace.Error("GS","上线登陆：","msg.cur_id=",msg.cur_id)--," petTab=",msg.pet_surface)
	if self.sysId == 1 then
		local mi = msg.mount_info
		self.chgID = mi.cur_id
		self:SetInfos(mi.surface_list)
		self:IsExistCur(1)
		AdvMgr.eSkinActive(mi.surface_list)
	elseif self.sysId == 2 then
		self.chgID = msg.cur_id
		self:SetInfos(msg.pet_surface)
		self:IsExistCur(2)
		AdvMgr.eSkinActive(msg.pet_surface)
	end
	-- self:UpdatePropNum()
end

--响应皮肤激活
function My:RespActive(msg)
	-- iTrace.Error("GS","  响应皮肤激活 ")
	-- iTrace.Error("GS","error===",msg.err_code)
	local skin = msg.surface
	local id = skin.id
	local k = self.GetKey(id)
	local info = self.dic[k]
	if info == nil then
		return
	end
	info.exp = skin.val
	-- iTrace.Error("GS","皮肤激活","skin.id=",skin.id," skin.val=",skin.val)
	if info.id ~= id then
	  info.id = id
	  info.sCfg = BinTool.Find(self.iSkinCfg, id)
	end
	local unlock = false
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
	-- iTrace.Error("GS","  响应皮肤升级 ")
	local skin = msg.surface
	local id = skin.id
	local k = self.GetKey(id)
	local info = self.dic[k]
	if info == nil then
		return
	end
	info.exp = skin.val
	-- iTrace.Error("GS","皮肤升级","skin.id=",skin.id," skin.val=",skin.val)
	if info.id ~= id then
	  info.id = id
	  info.sCfg = BinTool.Find(self.iSkinCfg, id)
	end
	local unlock = false
	self:UpdatePropNum()
	self.eRespRefine(id, unlock)
end

--响应幻化
function My:RespChange(msg)
	local err, id = msg.err_code, msg.cur_id
	-- iTrace.Error("GS","响应幻化","err=",err," msg.cur_id=",id)
	if err > 0 then
	  MsgBox.ShowYes(GetErr(err))
	else
	  self.chgID = id
	end
	self.eRespChange(err)
end

--请求激活
--id(number):基础id
function My:ReqAcive(id)
	--iTrace.Error("GS","请求激活：","self.tsASkinID==",self.tsASkinID," id==",id)
	local tsASkin= self.tsASkinID
	local msg = ProtoPool.GetByID(tsASkin)
	if msg == nil then return end
	msg.base_id = id
	ProtoMgr.Send(msg)
end

--请求进阶
--baseId(number):基础id
--propId(number):道具id
function My:ReqStep(baseId,propId,num)
	-- iTrace.Error("GS","请求进阶：","self.tsStepID==",self.tsStepID," id==",baseId,"  propid==",propId)
	local tsChgID = self.tsStepID
	local msg = ProtoPool.GetByID(tsChgID)
	if msg == nil then return end
	msg.base_id = baseId
	msg.item_id = propId
	msg.item_num = num
	ProtoMgr.Send(msg)
end

--请求幻化
--id(number):幻化ID
function My:ReqChange(id)
	-- iTrace.Error("GS","请求幻化：","self.tsChgID==",self.tsChgID," id==",id)
	local tsChgID = self.tsChgID
	local msg = ProtoPool.GetByID(tsChgID)
	if msg == nil then return end
	msg.cur_id = id
	ProtoMgr.Send(msg)
end

--index:系统id  1:坐骑（chgID=基础Id）  2:伙伴(chgID~=基础Id)
function My:IsExistCur(index)
	if self.chgID == 0 or self.chgID == nil then
		return
	end
	local curCfg = nil
	if index == 1 then
		curCfg = BinTool.Find(self.iCfg, self.chgID)
	else
		curCfg = self:GetBCfg(self.chgID)
	end
	if curCfg == nil then
		return
	end
	local name = AssetTool.GetSexModName(curCfg)
	local scName = AssetTool.GetSexScModName(curCfg)
	local isExist = AssetTool.IsExistAss(name)
	local scIsExist = AssetTool.IsExistAss(scName)
	if isExist == true and scIsExist == true then
		return
	elseif isExist == false or scIsExist == false then
		if index == 1 then
			MountsMgr.ReqChange(MountCfg[1].id)
		else
			PetMgr:ReqPetChange(PetStepTemp[1].id)
		end
	end
end

function My:Clear()
	self:Reset()
end

return My