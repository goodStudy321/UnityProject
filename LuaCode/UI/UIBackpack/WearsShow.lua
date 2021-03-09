--[[
背包穿戴装备展示
--]]
local Ass=Loong.Game.AssetMgr.Instance
WearsShow=Super:New{Name="WearsShow"}
local My=WearsShow

local cellDic={}
local bgDic = {}
local btns = {"Strengthen"}
local guardBtn = {"Renew"}

function My:Ctor()
	self.addDic={}
end

function My:Init(go)
	local CG=ComTool.Get
	local TF=TransTool.FindChild
	self.trans=go.transform

	UITool.SetBtnClick(self.trans,"ReName",self.Name,self.ReName,self)
	self.NameLab=CG(UILabel,self.trans,"NameLab",self.Name,false)
	self.LvLab=CG(UILabel,self.trans,"LvLab",self.Name,false)
	self.lvbg=CG(UISprite,self.trans,"LvLab/Sprite",self.Name,false)
	self.grid=CG(UIGrid,self.trans,"Grid",self.Name,false)
	self.modRoot = TF(self.trans,"Model")

	self.model=ObjPool.Get(RoleSkin)
	self.model.eLoadModelCB:Add(self.SetPos,self)
	-- self.model:CreateSelf(self.modRoot)

	self:InitCell()
    self:InitData()
	self:ShowName()
	self:ShowLv()

	self:AddE()
end

function My:AddE()
	EventMgr.Add("OnChangeLv",EventHandler(self.ShowLv,self))
	EquipMgr.eLoad:Add(self.EquipLoad,self)
	GuardMgr.eGuardUp:Add(self.OnGuardUp,self)
	GuardMgr.eOverTime:Add(self.OverTime,self)
	--GuardMgr.eOpen:Add(self.BigGuardUp,self)
	FashionMsg.eChgFashion:Add(self.RfRoleMod,self)
	PropMgr.eReName:Add(self.ShowName,self)
end

function My:ReE()
	EventMgr.Remove("OnChangeLv",EventHandler(self.ShowLv,self))
	EquipMgr.eLoad:Remove(self.EquipLoad,self)
	GuardMgr.eGuardUp:Remove(self.OnGuardUp,self)
	GuardMgr.eOverTime:Remove(self.OverTime,self)
	--GuardMgr.eOpen:Remove(self.BigGuardUp,self)
	FashionMsg.eChgFashion:Remove(self.RfRoleMod,self)
	PropMgr.eReName:Remove(self.ShowName,self)
end

function My:RfRoleMod()
	TransTool.ClearChildren(self.modRoot.transform)
	self.model:CreateSelf(self.modRoot)
end

function My:SetPos(go)
	local pos = Vector3.New(-226,-365,22) 
	local scale = Vector3.one*375
	local rota = Vector3.New(0,161,0)
	if User.instance.MapData.Sex==1 then --男
		pos = Vector3.New(-245,-387,222)
		rota = Vector3.New(0,156,0)
	end
	go.transform.localPosition=pos
	go.transform.localScale=scale
	go.transform.localEulerAngles=rota
end

local partList = {"12","10","9","8","7","1","11","3","4","2","5","6"}
function My:InitCell()
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	local U = UITool.SetLsnrSelf
	for i=1,12 do
		local go = TF(self.grid.transform,"ItemCell"..i)
		local part = partList[i]
		go.name=part
		local cell = ObjPool.Get(UIItemCell)
		cell:Init(go)
		cellDic[part]=cell
		local text=UIMisc.WearParts(tonumber(part))
		local p = CG(UILabel,go.transform,"part",self.Name,false)
		p.gameObject:SetActive(true)
		p.text=text
		bgDic[part]=p.gameObject

		if tonumber(part)>=9 and tonumber(part)<=12 then 
			local add = TF(go.transform,"add")
			self.addDic[part]=add
			U(add,self.ClickAdd,self,self.Name) 
			local lv = User.instance.MapData.Level
			local max = 30
			if part=="11" then max=1 end
			if part=="12" then max=300 end
			add:SetActive(lv>=max)
		end
	end
end

--监听等级变化
function My:ShowAdd()
	local lv = User.instance.MapData.Level
	for k,add in pairs(self.addDic) do
		if k=="11" then
			add:SetActive(GuardMgr.tb.type_id==0 and lv>=1)
		elseif k=="12" then
			add:SetActive(GuardMgr.bigTb.type_id==0)
		else
			local equip = EquipMgr.hasEquipDic[k]
			add:SetActive(lv>=30 and not equip)
		end
	end	
end

function My:ClickAdd(go)
	local lv = User.instance.MapData.Level
	local max = 30
	local OpenName = UIGetItem.Name
	local name = go.transform.parent.name
	if name=="11" or name=="12" then max=1 end
	if lv<max then return end
	self.clickPart=name
	UIMgr.Open(OpenName,self.OpenCb,self)
end

function My:OpenCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:UpData(self.clickPart)
	end
end

function My:UpdateTexture()
	for part,tb in pairs(EquipMgr.hasEquipDic) do
		local cell=cellDic[part]
		local item=ItemData[tostring(tb.type_id)]
		cell:UpIcon(item,true)
	end

	local id11 = GuardMgr.tb.type_id
	if id11>0 then 
		local cell11=cellDic["11"]
		local item = UIMisc.FindCreate(id11)
		cell11:UpIcon(item,true)
	end
	local id12 = GuardMgr.bigTb.type_id
	if id12>0 then 
		local cell12=cellDic["12"]
		local item = UIMisc.FindCreate(id12)
		cell12:UpIcon(item,true)
	end

	if self.model then --[[self.model:Clear()]] self.model:CreateSelf(self.modRoot) end
end

function My:InitData()
	for k,v in pairs(EquipMgr.hasEquipDic) do
		self:EquipLoad(v,k)
	end
	self:OnGuardUp()
end

--装备穿戴
function My:EquipLoad(tb,part)
	local cell=cellDic[part]
	local item=ItemData[tostring(tb.type_id)]
	cell:TipData(tb,nil,btns)
	cell:UpBind(tb.bind)

	local pat = bgDic[tostring(part)]
	pat:SetActive(false)
	local add = self.addDic[part]
	if add then add:SetActive(false) end
end

function My:OnGuardUp()
	self:GuardUp()
	self:BigGuardUp()
end

--守护
function My:GuardUp()
	local id = GuardMgr.tb.type_id
	if id==0 then return end
	local cell=cellDic["11"]
	cell.isGuard=true
	if id==40009 then 
		cell:TipData(GuardMgr.tb)
	else
		cell:TipData(GuardMgr.tb,nil,guardBtn)
	end
	bgDic["11"]:SetActive(false)
	self.addDic["11"]:SetActive(false)
end

--守护过期
function My:OverTime(tp)
	local id = tp==1 and "11" or "12"
	local cell=cellDic[id]
	cell:Clean()
	bgDic[id]:SetActive(true)
	self.addDic[id]:SetActive(true)
end

--心结
function My:BigGuardUp()
	local id = GuardMgr.bigTb.type_id
	if id==0 then return end
	local cell=cellDic["12"]
	cell.isGuard=true
	if id==40009 then 
		cell:TipData(GuardMgr.bigTb)
	else
		cell:TipData(GuardMgr.bigTb,nil,guardBtn)
	end
	bgDic["12"]:SetActive(false)
	self.addDic["12"]:SetActive(false)

	-- local id = GuardMgr.bigTb.type_id
	-- local cell=cellDic["12"]
	-- local click = TransTool.FindChild(cell.trans,"Click")
	-- cell:Lock(0.001)
	-- bgDic["12"]:SetActive(false)
	-- local tip = TransTool.FindChild(cell.trans,"tip")
	-- tip:SetActive(false)
	-- if id>0 then --已装备
	-- 	self.addDic["12"]:SetActive(false)		
	-- 	cell.isGuard=true
	-- 	cell:TipData(GuardMgr.bigTb)
	-- 	self.bigTipTp=1
	-- elseif id==0 then --已开启未装备
	-- 	bgDic["12"]:SetActive(true)
	-- 	self.addDic["12"]:SetActive(true)	
	-- 	self.bigTipTp=2
	-- elseif id==-1 and (User.instance.MapData.Level>=300 or VIPMgr.GetVIPLv()>=4) then --可开启
	-- 	tip:SetActive(true)
	-- 	cell:IconUp(false)
	-- 	self.bigTipTp=3
	-- elseif id==-1 then --未解锁
	-- 	cell:Lock(1)	
	-- 	self.bigTipTp=4			
	-- end

	-- if self.bigTipTp>=3 then 		
	-- 	UITool.SetLsnrSelf(click,self.OnOpenTip,self,self.Name)	
	-- end
	-- click:SetActive(self.bigTipTp>=3)
end

function My:OnOpenTip()
	if self.bigTipTp==3 then
		local title = "是否花费200元宝开启高级守护槽孔，开启后可同时装备小精灵和小仙女[CC2500FF](可使用绑元开启)[-]"
		MsgBox.ShowYesNo(title,self.OpenTipCb,self)
	elseif self.bigTipTp==4 then 
		local msg = "该功能达到300级或VIP4可用，是否立即前往开启？"
		MsgBox.ShowYes(msg,self.OpenTipCb2,self,"立即前往")
		--UITip.Error("达到300级开启")
	end	
end

function My:OpenTipCb()
	GuardMgr.ReqOpenGuard()
end

function My:OpenTipCb2()
	VIPMgr.OpenVIP()
end

function My:ShowName()
	if self.NameLab then self.NameLab.text=User.instance.MapData.Name end
end

function My:ShowLv()
	if self.LvLab then self.LvLab.text=tostring(UserMgr:GetGodLv()) end
	local path = "ty_19"
	if UserMgr:IsGod()==true then path = "ty_19A" end
	if self.lvbg then self.lvbg.spriteName=path end
	self:ShowAdd()
	self:BigGuardUp()
end

--改名
function My:ReName()
	UIMgr.Open(UIChangeName.Name,self.ChangeNameCb,self)
end

function My:ChangeNameCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		local global = GlobalTemp["38"]
		ui:UpData(global.Value2[1])
	end
end

function My:ActiveState(state)
	if LuaTool.IsNull(self.trans) then return end
	self.trans.gameObject:SetActive(state)
end

function My:CleanData()
	for k,v in pairs(cellDic) do
		v.trans.name="ItemCell"..k
	end
end

function My:CleanMd()
	self.model:Clear();
end

function My:Dispose()	
	self:ReE()
	if self.model then self.model.eLoadModelCB:Remove(self.SetPos,self) ObjPool.Add(self.model) self.model=nil end
	TableTool.ClearDic(self.addDic)
	TableTool.ClearDic(bgDic)
	local guard = cellDic["11"]
	if guard then guard.isGuard=nil end
	TableTool.ClearDicToPool(cellDic)
	TableTool.ClearUserData(self)
end