--[[
	新的活动管理器
]]

require("Liveness/NewActivInfo");

NewActivMgr = {Name = "NewActivMgr"};
local My = NewActivMgr;

My.SCBS = 2000  --首充倍送
My.ZCM = 2001  --招财猫
My.XYZD = 2002   --幸运砸蛋
My.HSJB = 2003   --黑市鉴宝
My.XYSSQ = 2004  --幸运上上签
My.XYJB = 2005  --幸运鉴宝
My.JBHL = 2006--绝版壕礼
My.MRBX = 2007--每日宝箱
My.HLBX = 2008--欢乐宝箱
My.TTBT = 2009--通天宝塔
My.XLMJ = 2010 --修炼秘籍
My.QFHB = 2011   --全服红包

My.TDQY = 2012  --天道情缘
My.QCRL = 2013   --嗨点活动(全程热恋)
My.XSDL = 2014   --限时掉落

My.ZDYHTHD = 99999 --自定义后台活动id
My.ZDYSMBZ = 99998 --自定义后台活动 神秘宝藏

My.RecordTabUI = {}
My.RecordTabUIName = {}
My.isExit = true

function My:Init()
	self:SetLsnr(ProtoLsnr.Add);
	self.eUpActivInfo = Event();
	self:SetEvent("Add")
end


function My:SetEvent(fn)
	PracSecMgr.eUpUI[fn](PracSecMgr.eUpUI, self.OpenRecordUI, self)
	--PracSecMgr.ePracInfo[fn](PracSecMgr.ePracInfo, self.OpenRecordUI, self)
	DrawLotsNetwork.eInfo[fn](DrawLotsNetwork.eInfo, self.OpenRecordUI, self)
	FestivalActMgr.eFestivalInfo[fn](FestivalActMgr.eFestivalInfo, self.AddFestivalId, self)
end

function My:AddFestivalId(isOpen)
	if isOpen then
		self:AddRecordTab(self.ZDYHTHD)
	end
	local isOpenTrea = FestivalActMgr:IsOpenSMBZ() --神秘宝藏是否开启
	if isOpenTrea then
		self:AddRecordTab(self.ZDYSMBZ)
	end
end

function My:AddCloseUI()
	euiclose:Add(self.CheckCloseName,self);
end

function My:RemoveCloseUI()
	euiclose:Remove(self.CheckCloseName,self);
end

function My:CheckCloseName(uiName)
	local isCanOpen = false
	if self.isExit then return end
	if uiName == UIPayMul.Name then
		isCanOpen = true
	elseif uiName == UIFortuneCatPanel.Name then
		isCanOpen = true
	elseif uiName == UIZaDan.Name then
		isCanOpen = true
	elseif uiName == UIBlackMarket.Name then
		isCanOpen = true
	elseif uiName == UIDrawLots.Name then
		isCanOpen = true
	elseif uiName == UILuckFull.Name then
		isCanOpen = true
	elseif uiName == UIOutGift.Name then
		isCanOpen = true
	elseif uiName == UILvAward.Name then
		isCanOpen = true
	elseif uiName == UIHappyChest.Name then
		isCanOpen = true
	elseif uiName == UITongTianTower.Name then
		isCanOpen = true
	elseif uiName == UIPracticeSec.Name then
		isCanOpen = true
	elseif uiName == UIFestivalAct.Name then
		isCanOpen = true
	elseif uiName == UITreaFever.Name then
		isCanOpen = true
	elseif uiName == UIHeavenLove.Name then
		isCanOpen = true
	end
	-- euiclose ui关闭事件回传多次，self.isExit 用来标识是否已经存在
	if isCanOpen then
		if not My.RecordTabUIName[uiName] then
			My.RecordTabUIName[uiName] = uiName
			local len = #self.RecordTabUI
			if not len or len <= 0 then
				if PrayMgr.canOpenUI then
					local active = UIMgr.GetActive(UIOffLineTip.Name)
					if active == -1 then
						UIMgr.Open(UIOffLineTip.Name)
					end
				end
			end
			self:OpenRecordUI()
		end
	end
end

function My:OpenRecordUI()
	-- if PracSecMgr.pracInfoTab.pracExp == nil then return end
	self.isExit = true
	local tab = self.RecordTabUI
	local len = #tab
	if len > 0 then
		self:OpenUIByActId(len)
		self.isExit = false
	else
		self:RemoveCloseUI()
	end
end

function My:OpenUIByActId(len)
	local tab = self.RecordTabUI
	if len == nil or len <= 0 then return end
	local actId = tab[len]
	if actId == self.SCBS then --首充倍送
		UIPayMul:OpenTab(1)
	elseif actId == self.ZCM then --招财猫
		FortuneCatMgr.OpenUI()
	elseif actId == self.XYZD then --幸运砸蛋
		UIMgr.Open(UIZaDan.Name)
	elseif actId == self.HSJB then --黑市鉴宝
		UIMgr.Open(UIBlackMarket.Name)
	elseif actId == self.XYSSQ then --幸运上上签
		--if DrawLotsNetwork.lv == nil then
		--	return
		--end
		DrawLotsMgr.OpenUI()
	elseif actId == self.XYJB then --幸运鉴宝
		UIMgr.Open("UILuckFull")
	elseif actId == self.JBHL then --绝版壕礼
		UIOutGift:OpenTab(1)
	elseif actId == self.MRBX then --每日宝箱
		if not self.RecordTabUIName[UILvAward.Name] then
			UILvAward:OpenTab(8)
		end
	elseif actId == self.HLBX then --欢乐宝箱
		UIMgr.Open(UIHappyChest.Name)
	elseif actId == self.TTBT then --通天宝塔
		TongTianTowerMgr:OpenUI()
	elseif actId == self.XLMJ then --修炼秘籍
		--if PracSecMgr.pracInfoTab.pracExp == nil then
		--	return
		--end
		UIPracticeSec:OpenTab(1)
	elseif actId == self.QFHB then --全服红包
		if not self.RecordTabUIName[UILvAward.Name] then
			UILvAward:OpenTab(9)
		end
	elseif actId == self.ZDYHTHD then -- 自定后台活动
		local actMgr = FestivalActMgr
		local ldlTab = {actMgr.BestAlchemy,actMgr.CommonAlchemy,actMgr.AlchemyStore}
		local isLdl = false
		for i = 1,#ldlTab do
			isLdl = actMgr:IsOpen(ldlTab[i])
			if isLdl then
				break
			end
		end
		if isLdl then
			UIMgr.Open(UIAlchemy.Name)
		else
			UIMgr.Open(UIFestivalAct.Name)
		end
	elseif actId == self.ZDYSMBZ then
		UIMgr.Open(UITreaFever.Name)
	elseif actId == self.TDQY then --天道情缘
		HeavenLoveMgr.OpenUI(1)
	-- elseif actId == self.QCRL then --嗨点活动(全程热恋)
	-- 	HeavenLoveMgr.OpenUI(3)
	-- elseif actId == self.XSDL then --限时掉落
	-- 	HeavenLoveMgr.OpenUI(5)
	end
	table.remove(self.RecordTabUI,len)
end

function My:AddRecordTab(actId)
	local maxRecord = 3
	local tab = self.RecordTabUI
	local len = #tab
	-- if actId == self.TDQY or actId == self.QCRL or actId == self.XSDL then
	-- 	return
	-- end
	if actId == self.QCRL or actId == self.XSDL then
		return
	end
	if len < maxRecord then
		if actId == 2011 then
			for i = 1, #self.RecordTabUI do
				if self.RecordTabUI[i] == 2007 then
					return
				end
			end
		end
		if actId == 2007 then
			for i = 1, #self.RecordTabUI do
				if self.RecordTabUI[i] == 2011 then
					return
				end
			end
		end
		table.insert(self.RecordTabUI,actId)
	end
end

--事件监听
function My:SetLsnr(fun)
	fun(26478, self.ResqActivInfo, self);
	fun(26480, self.ResqUpActivInfo, self);
end

--获取对应活动信息
--activId 活动ID
function My:GetActivInfo(activId)
	local id = tostring(activId);
	if not NewActivInfo.ActivInfo[id] then 
		return false;
	end
	return NewActivInfo.ActivInfo[id];
end

--活动是否开启
function My:ActivIsOpen(activId)
	local id = tostring(activId);
	if not NewActivInfo.ActivInfo[id] then
		return false;
	end
	if NewActivInfo.ActivInfo[id].val == 1 then
		return true;
	end
		return false;
end

--响应活动信息
function My:ResqActivInfo(msg)
	local list = msg.act_list;
	for k,v in ipairs(list) do
		NewActivInfo:SetActivInfo(v.id ,v.val, v.config_num, v.start_time, v.end_time);
		self:AddRecordTab(v.id)
	end
	if not self.timer then
		self.timer=ObjPool.Get(iTimer)
		self.timer.complete:Add(self.OnEnd,self)
		self.timer.seconds=1
	end
	self.timer:Start()
	--self:OpenRecordUI()
	self:AddCloseUI()
	self.eUpActivInfo();
end

function My:OnEnd()
	self:OpenRecordUI()
end

--更新活动信息
function My:ResqUpActivInfo(msg)
	local act = msg.act;
	NewActivInfo:SetActivInfo(act.id , act.val, act.config_num, act.start_time, act.end_time);
	self.eUpActivInfo(act.id);
end

--清理缓存
function My:Clear()
	TableTool.ClearDic(self.RecordTabUI)
	TableTool.ClearDic(self.RecordTabUIName)
    NewActivInfo:Dispose();
end
    
--释放资源,其实本方法没有调用！
function My:Dispose()
	if self.timer then self.timer:AutoToPool() self.timer=nil end
	TableTool.ClearDic(self.RecordTabUI)
	TableTool.ClearDic(self.RecordTabUIName)
	self:SetLsnr(ProtoLsnr.Remove)
	self:SetEvent("Remove")
end

return My;