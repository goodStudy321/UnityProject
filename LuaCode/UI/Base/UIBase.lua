--[[
	AU:Loong
	TM:2017.05.09
	BG:UI基类
--]]

UIBase = Super:New{Name = "UIBase"}

local My = UIBase

--遮挡部件
My.LockGo = nil

--变换组件
My.root = nil

--游戏对象
My.gbj = nil

My.cfg = nil

--lua内全局打开事件
euiopen = Event()

--lua内全局关闭事件
euiclose = Event()

function My:Ctor()
	--0:关闭 1:打开 2:关闭(特效)中
	self.active = 0
	self.Persist = false
	self.Loading = false
	--true:已被设置释放
	self.setDestory = false
	self:SetActiveProp(0)
end

--设置字段active
function My:SetActiveProp(val)
	self.active = val or 0
end

function My:UpdateConfig()
	local cfg = UICfg[self.Name]
	self.cfg = cfg
	if cfg == nil then return end
	local cleanOp = cfg.cleanOp or 0
	if cleanOp == 0 then
		self:SetPersist()
	end
	local cDp = cfg.cDp or 0
	local p = UIMgr.Cam.transform
	if cDp == 1 then
		p = UIMgr.HCam.transform
	end
	local trans = self.root
	trans.parent = p
	trans.localPosition = Vector3.zero

end

--创建遮挡部件
function My:CreateLockGo()
	local maxPnl = UITool.GetMaxDepth(self.gbj)
	if (LuaTool.IsNull(maxPnl)) then return end
	local widget = UITool.CreateMask(UIWidget, self.root, "lock", 10000);
	if(LuaTool.IsNull(widget)) then iTrace.Error("Loong", "widget is null") end
	self.LockGo = widget.gameObject;
	self.LockGo:SetActive(false);
end

--创建背景效果
function My:CreateBgEffect()
	if(self.cfg == nil) then return end
	local root = self.root
	local eBg = self.cfg.eBg
	local UCM = UITool.CreateMask
	self.useShotMask = false;

	if eBg == 1 then
		UCM(UIWidget, root, "transBg", - 10000);
	elseif eBg == 2 then
		local bg = UCM(UITexture, root, "selftransBg", - 10000)
		bg.mainTexture = TexTool.Transparent
	elseif eBg == 3 then
		--local ui = RapidBlurEffectTexture.instance:OnShow(self.gbj)
		--local bg = UCM(UITexture, root, "selftransBg", - 1)
		--bg.mainTexture = TexTool.Transparent
		--bg.color = Color.New(1,1,1,0.8)
	elseif eBg == 4 then
		-- self.useShotMask = true;
		-- EventMgr.Trigger("OpenScreenShotMask", true);
	end
end

--排序
function My:Sort()
	local cfg = self.cfg
	local st = cfg and cfg.sort or 0
	UITool.Sort(self.gbj, st, 20)
end

--自定义初始化
function My:InitCustom()

end

--自定义打开
function My:OpenCustom()

end

--自定义关闭
function My:CloseCustom()

end

--自定义释放
function My:DisposeCustom()

end


--初始化
function My:Init()
	self.root = self.gbj.transform
	self.Loading = false
	self.setDestory = false
	self:UpdateConfig()
	self:CreateLockGo()
	self:CreateBgEffect()
	self:Sort()
	self:InitCustom()
end

--检查有效性
function My:Check()
	if LuaTool.IsNull(self.gbj) then
		-- iTrace.Error("Loong", tostring(self.Name), " 的游戏对象不存在")
		return false
	end
	return true
end

--检查能否关闭
--return:true,能关闭
function My:ChkClose()
	if not self.Loading then return true end
	if self:CloseClean() then self.setDestory = true end
	do return false end
end

--打开事件
function My:OpenEvent()
	euiopen(self.Name)
	EventMgr.Trigger("UIOpen", self.Name)
	UIMgr.eOpenTrig(self.Name)
	self:CloseMainCam()
end

--关闭事件
function My:CloseEvent()
	euiclose(self.Name)
	EventMgr.Trigger("UIClose", self.Name)
	self:OpenMainCam()
end

--检查是否关闭主相机
function My:CheckSwMainCam()
	local cfg = self.cfg
	local op = cfg and cfg.swMainCam or 0
	if op == 0 then
		return false
	else
		return true
	end
end

--打开主相机
function My:OpenMainCam()
	do return end
	if(self:CheckSwMainCam()) then
		EventMgr.Trigger("CamOpen")
	end
end

--关闭住相机
function My:CloseMainCam()
	do return end
	if(self:CheckSwMainCam()) then
		EventMgr.Trigger("CamClose")
	end
end

--打开关联面板
function My:OpenCp()
	local cp = nil
	local cfg = self.cfg
	if cfg then cp = cfg.cp end
	if cp == nil then return end
	UIMgr.Open(cp,self.CheckTopData,self)
	local cpui = UIMgr.Get(cp)
	if cpui == nil then return end
	cpui.rcp = self.Name
	--关联面板
	self.cpui = cpui
end

--检查是否添加货币栏
function My:CheckTopData(cp)
	if cp==UITop.Name then
		local ui = UIMgr.Get(cp)
		if ui then 
			ui:UpData(self.Name)
		end
	end
end

--关闭关联面板
function My:CloseCp()
	local cp = nil
	local cfg = self.cfg
	if cfg then cp = cfg.cp end
	if cp then
		UIMgr.Close(cp)
		self.cpui = nil
	else
		local rcp = self.rcp
		if rcp then
			self.rcp = nil
			UIMgr.Close(rcp)
		end
	end
end

--重构关闭
function My:FinalClose()
	local cfg = self.cfg
	if cfg then
		Audio:Play(cfg.cAudio, 1)
		if cfg.tOn == 1 then UIMgr.OpenRecords(self.Name) end
	end
	self.gbj:SetActive(false)
	self:SetActiveProp(0)
	self:CloseCustom()
	self:CloseEvent()
	if self:CloseClean() then
		UIMgr.Remove(self.Name)
	end
end


--打开效果
function My:OpenEffect()
end

--关闭效果
function My:CloseEffect()
	self:FinalClose()
end

--打开
function My:Open()
	--iTrace.sLog("hs","Open UI=======================>>> "..self.Name)
	if not self:Check() then return end
	if self.active == 1 then
		self:OpenEvent()
	else
		local cfg = self.cfg
		if cfg then
			Audio:Play(cfg.oAudio, 1)
			local tOn = cfg.tOn
			if tOn == 1 then
				if cfg.relifeOpen==1 then
					UIMgr.SetCanClose( false )
				end
				if UIMgr.CanNotClose then
					return;
				end
				UIMgr.Swap(self.Name)
				UIMgr.RecordOpens(self.Name, true)
			end
		end
		self:OpenCp()
		self.gbj:SetActive(true)
		self:SetActiveProp(1)
		self:OpenCustom()
		self:OpenEvent()
		self:OpenEffect()

		local eBg = cfg.eBg
		if  eBg == 4 then
			EventMgr.Trigger("OpenScreenShotMask", true);
		end
	end
end

--通过索引打开分页
--t1(number)1级分页索引:0:代表无分页
--t2(number)2级分页索引
--t3(number)3级分页索引
--t4(number)4级分页索引
function My:OpenTabByIdx(t1, t2, t3, t4)
	local msg = self.Name .. "未重写OpenTabByIdx"
	-- UITip.Error(msg)
	iTrace.eLog("Loong",msg)
end
--通过索引打开分页
--t1(number)1级分页索引:0:代表无分页
--t2(number)2级分页索引
--t3(number)3级分页索引
--t4(number)4级分页索引
function My:OpenTabByIdxBeforOpen(t1, t2, t3, t4)
end
--获取特殊的开启条件
function My:GetSpecial(t1)
	return true
end

--关闭
function My:Close()
	--iTrace.sLog("hs","Close UI=======================>>> "..self.Name)
	if not self:ChkClose() then return end
	if not self:Check() then return end
	self:Lock(false)
	if self.active == 1 then
		local cfg = self.cfg
		self:SetActiveProp(2)
		self:CloseCp()
		if cfg == nil then
			self:FinalClose()
		elseif cfg.eOn == 0 then
			self:FinalClose()
		elseif not UIMgr.UseOnOffEffect then
			self:FinalClose()
		else
			self:SetActiveProp(2)
			self:CloseEffect()
		end

		local eBg = cfg.eBg
		if  eBg == 4 then
			EventMgr.Trigger("OpenScreenShotMask", false);
		end
	else
		self:CloseEvent()
	end
end

--更新
function My:Update()

end

--更新
function My:LateUpdate()

end

--锁定 active:true锁定面板
function My:Lock(active)
	if(LuaTool.IsNull(self.LockGo)) then return end
	self.LockGo:SetActive(active)
end

--清理
function My:Clear(isReconnect)

end

--释放
function My:Dispose()
	if self.Persist then return end
	self:Clear()
	self:SetActiveProp(0)
	if(LuaTool.IsNull(self.gbj)) then return end
	self:DisposeCustom()
	AssetMgr:Unload(self.Name, ".prefab", false)
	GameObject.DestroyImmediate(self.gbj)
	TableTool.ClearUserData(self)
	self.setDestory = false
	--print("释放UI:", self.Name)
end

--设置持久化
function My:SetPersist()
	self.Persist = true;
	AssetMgr:SetPersist(self.Name, ".prefab",true)
end

--是否能被记录
function My:CanRecords()
	do return true end
end

--持续显示 ，不受配置tOn == 1 影响
function My:ConDisplay()
	do return false end
end

--是否关闭时释放
function My:CloseClean()
	local cfg = self.cfg
	local op = cfg and cfg.cleanOp or 0
	if op == 1 then
		return true
	else
		return false
	end
end
