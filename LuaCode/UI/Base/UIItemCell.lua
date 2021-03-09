--[[
道具格子
--]]
local AssetMgr=Loong.Game.AssetMgr
UIItemCell=Cell:New{Name="UIItemCell"}
local My=UIItemCell
My.eClick=Event()
My.eClickGM=Event()  --GM测试

--设置道具的获取途径
function My:SetGetWay(uiName,bType,sType)
	self.uiName=uiName
	self.bType=bType
	self.sType=sType
	local add = TransTool.FindChild(self.trans,"add")
	self.add=add
	add:SetActive(true)
	UITool.SetLsnrSelf(add,self.OnGetWay,self,self.Name,false)
end

function My:OnGetWay()
	GetWayFunc.SetJump(self.uiName,self.bType,self.sType)
	GetWayFunc.ItemGetWay(self.type_id)
end

--需要显示基础信息之外的其他信息请传参为tb(PropTb或者 EquipTb)
--ljf 添加isSpir,用于战灵背包格子Tip与战灵穿戴装备比较
function My:TipData(tb,text,btnList,isCompare,isSpir,delayShowEff)
	self.tb=tb
	if self.btnList then ListTool.Clear(self.btnList) end
	if btnList~=nil then 
		for i,v in ipairs(btnList) do
			self.btnList[#self.btnList+1]=v
		end
	end
	self.isCompare=isCompare
	self.isSpir = isSpir;
	self:UpData(tb.type_id,text, nil, nil, nil, delayShowEff)
	local endTime = self.tb.market_end_time
	self:ShowLimit(endTime,self.tb)
end 

function My:TipWhat(tb,text,attWhat)
	self.attWhat=attWhat
	local type_id = nil
	if type(tb)=="table" then
		self.tb=tb
		type_id=tostring(tb.type_id)
	else
		type_id=tostring(tb)
	end
	self:UpData(type_id,text)
end

function My:TipSuit(type_id,suit)
	self.suit=suit
	self:UpData(type_id)
end


function My:OnClick(go)
	if self.IsClick == false then return end
	self.eClickCell(go)
	
	--双击了
	if self.doubleClick==true then 
		if self.timer then self.timer:Stop() self.timer:AutoToPool()  self.timer=nil return end
	end
	if LuaTool.IsNull(self.trans) then return end
	self.pos=self.trans.position
	local x,y = UIMisc.GetInputDir()
	self.xy=Vector3.New(x,y,0)
	if self.isdouble~=true then
		self:Complete()
		return 
	end
	if not self.timer then 
		self.timer=ObjPool.Get(iTimer) 
		self.timer.complete:Add(self.Complete,self)
	end
	self.timer:Stop()
	self.timer.seconds=0.36
	self.timer:Start()
end

function My:SetDoubleClick(tp,isBag)
	self.tp=tp --类型
	if (tp==1 or tp==2) and not isBag then 
		self.isdouble=true
		UIEventListener.Get(self.trans.gameObject).onDoubleClick = function(go) self:OnDoubleClick(go) end 
	end
end

function My:OnDoubleClick(go)
    local id = self.tb.id
    local to = 1
    if self.tp==1 then to=2 end
    PropMgr.ReqDepot(self.tp,to,id)
    self.doubleClick=true
    self:Complete()
end

function My:Complete()
	if self.timer then self.timer:Stop() self.timer:AutoToPool()  self.timer=nil end
	if LuaTool.IsNull(self.trans) then return end 
	My.eClick(self.trans.name,self.index)
	if(self.item==nil)then return end
	My.eClickGM(self.item.id)
	if self.doubleClick~=true then
		iTrace.Log("xiaoyu","================click type_id: ",self.type_id)
		self.uFx=self.item.uFx	
		if(self.uFx==1)then --装备
			EquipTip.showDepotPoint=self.showDepotPoint
			EquipTip.isInWarehouse = self.isInWarehouse
			EquipTip.pos=self.pos
			EquipTip.width=self.width
			UIMgr.Open(EquipTip.Name,self.OpenCb,self)
		elseif self.uFx==28 then --小精灵
			UIMgr.Open(GuardTip.Name,self.OpenCb,self)
		elseif self.uFx==55 then --同心结
			UIMgr.Open(KnotTip.Name,self.OpenKnot,self)
		elseif self.uFx==86 then
			SkyMysteryTip.isInWarehouse = self.isInWarehouse
			UIMgr.Open(SkyMysteryTip.Name,self.OpenSky,self)
		elseif self.uFx==89 then
			UIMgr.Open(UIElixirTip.Name,self.OpenCb,self)
		elseif self.uFx==46 then --仙魂
			UIMgr.Open(ImmortalSoulTip.Name,self.OpenSoulTip,self)
		else--其他道具
			PropTip.isInWarehouse = self.isInWarehouse
			local ui = UIMgr.Get(PropTip.Name)
			PropTip.pos=self.pos
			if ui then
				self:OpenCb(PropTip.Name)
			else
				UIMgr.Open(PropTip.Name,self.OpenCb,self)
			end
		end
	end
	self.doubleClick=false
end



function My:OpenKnot(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpData(self.type_id)
	end
end

function My:OpenSky(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpData(self.item)
		ui:ShowBtn(self.btnList, self)
	end
end

--符文Tip的回调方法
function My:OpenRuneTip(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        local key = tostring(self.type_id)
        local cfg = RuneCfg[key]
		ui:Refresh(cfg, 1)
    end
end

function My:OpenSoulTip(name)
	local ui = UIMgr.Get(name)
	if ui then
		local cfg, temp = BinTool.Find(ImmSoulLvCfg, tonumber(self.type_id))
		ui:UpData(cfg)
		ui:ShowBtn(false,false,false)
	end
end

function My:OpenCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
		ui.isBind=self.isBind or false
		if(self.tb~=nil)then
			self:DealSprite()
			ui:UpData(self.tb,self.isCompare,nil,self.attWhat,self.isSpir)			
		else
			ui:UpData(self.type_id,self.isCompare,self.suit,self.attWhat,self.isSpir)
		end
		ui:ShowBtn(self.btnList,self)
	end
end

function My:DealSprite()
	if self.uFx==28 then
		local now=TimeTool.GetServerTimeNow()*0.001
		local lerp=self.tb.endTime-now
		if lerp<=0 and self.tb.endTime~=self.tb.startTime then 
			ListTool.Clear(self.btnList) 
			self.btnList[1]="Buy"
		end
	end
end


function My:DisposeCus()
	if self.add then self.add:SetActive(false) end
	self.doubleClick=nil
	self.tb=nil
	self.isCompare=nil
	self.isBind=nil
	self.attWhat=nil
end



