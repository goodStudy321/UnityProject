--[[
装备洗练
--]]
require("UI/UIEquip/AttInfo")
Tg2=Super:New{Name="Tg2"}
local My = Tg2


function My:Ctor()
	self.attList={}
	--self.lockList={}
end

function My:Init(go)
    local CG=ComTool.Get
	local TF=TransTool.FindChild
	self.go=go
	local U = UITool.SetLsnrSelf
    local UB = UITool.SetBtnClick
    local trans = go.transform

	UB(trans,"StrBtn",self.Name,self.StrBtn,self)
	self.Tip=CG(UILabel,trans,"Tip/Label",self.Name,false)
	
	self.fight=CG(UILabel,trans,"bg/fight",self.Name,false)

	self.cell1=ObjPool.Get(UIItemCell)
	self.cell1:InitLoadPool(TF(trans,"di").transform)

	self.cell2=ObjPool.Get(UIItemCell)
	self.cell2:InitLoadPool(trans,0.98,nil,nil,nil,Vector3.New(-5.8,-82,0))

	self.best=CG(UIToggle,trans,"best",self.Name,false)
	UB(trans,"best",self.Name,self.Best,self)
	UB(trans,"Tip",self.Name,self.Bintrodus,self)
	self.bestLab=CG(UILabel,trans,"best/Label",self.Name,false)

	self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
	
	for i=1,5 do
		local gg = TF(trans,"Grid/"..i)
		local att = ObjPool.Get(AttInfo)
		att:Init(gg)
		self.attList[i]=att
		-- self.lockList[i]=false
	end
	self.c1=TF(trans,"Grid/c1")
	

	-- self.add=TF(trans,"Grid/add")
	-- UB(self.add.transform,"AddBtn",self.Name,self.AddBtn,self)

	self.type=1
	self.Lv=User.instance.MapData.Level

    self:ShowVIPAtt()
    
    self.str=ObjPool.Get(StrBuffer)
end

function My:SetEvent(fn)
	EquipMgr.eConciseOpen[fn](EquipMgr.eConciseOpen,self.ShowLock,self)
	EquipMgr.eTime[fn](EquipMgr.eTime,self.UpTip,self)
    AttInfo.eConcise[fn](AttInfo.eConcise,self.UpLockPrice,self)
    EquipPanel.eClick[fn](EquipPanel.eClick,self.OnClickCell,self)
end

function My:Bintrodus( )
    local cur = 1030;
    local str=InvestDesCfg[tostring(cur)].des;
    UIComTips:Show(str, Vector3(132,-54,0),nil,nil,nil,400,UIWidget.Pivot.TopLeft);
end

function My:ShowVIPAtt()
	local vip = VIPMgr.GetVIPLv()
	if vip>=6 then --VIP6开启额外属性
		local att=self.attList[5]
		att.trans.gameObject:SetActive(true)
		self.c1:SetActive(false)
	end
end
 
function My:UpData(tb)
	local equip = EquipBaseTemp[tostring(tb.type_id)]
	self.part=tostring(equip.wearParts)

	local lock = EquipMgr.lockDic[self.part]
	if loack then 
		local cList = tb.cList
		for i,v in ipairs(cList) do
			local state = lock[tostring(i)] or false
			local att = self.attList[i]
			att.tog.value=state
		end	
	end
	----------------
	self.id=tb.type_id
	self:ShowLock(tb)
end

function My:ShowLock(tb)
	self.cell1:TipData(tb)
	self:UpTip()

	local count = #tb.cList
	self.lockMax=count
	--:SetActive(count~=4)
	self:UpAtt(tb.cList)
	self:UpLockPrice()
end

function My:GetConcise(part,cList)
	if #cList==0 then return nil end
	local list = EquipMgr.conciseDic[tostring(part)]
	for i,v in ipairs(list) do
		local consice = EquipConcise[v]
		for i1,kv in ipairs(cList) do
			local id = kv.v
			local val = kv.b
			local prop = PropName[id]
			local nLua = prop.nLua

			local arg=consice[nLua]
			if arg then 
				local min = arg[1]
				local max = arg[2]
				if val>=min and val<=max then 
					return consice
				end
			end
		end
	end
	return iTrace.eError("xiaoyu","装备洗炼品质表为空 id: "..part)
end

function My:UpLockPrice()
	local lockDic = EquipMgr.lockDic[self.part]
	local num = TableTool.GetDicCount(lockDic)
	local islock = num==self.lockMax-1 
	for i,v in ipairs(self.attList) do
		local togvalue=false
		if lockDic then togvalue=lockDic[tostring(i)] end

		local togState = true
		if islock==true and togvalue~=true then 
			togState=false
		end
		v:TogState(togState)

		v.tog.value=togvalue	
	end
	--消耗洗炼丹
	self.str:Dispose()
	local has = PropMgr.TypeIdByNum(103)
	local lock = EquipLock[tostring(num)]
	local need = lock.neednum
	local color = "[ffffff]"
	if has<need then color=UIMisc.LabColor(5) end
	self.islock=has<need and true or false
	self.str:Apd(color):Apd(has):Apd("/"):Apd(need)
	self.cell2:UpData(103,self.str:ToStr())

	--消耗元宝
	self.str:Dispose()
	self.lockPrice=lock.price
	self.str:Apd("[B1A495]消耗[-][67CC67]"):Apd(lock.price):Apd("[-][B1A495]绑元必出一条[-][8b62ff]紫色[-][B1A495]以上属性（绑元不足消耗元宝）[-]")--开启属性槽不消耗
	self.bestLab.text=self.str:ToStr()

	EquipMgr.xilianRed()
end

--显示属性条 and 评分
function My:UpAtt(list)
	local fight = 0
	local consiDic = EquipMgr.conciseDic[self.part]
	
	for i,kv in ipairs(list) do
		self.str:Dispose()
		local index = kv.k
		
		local att = self.attList[index]
		att:SetActive(true)
		--self:ShowLockState(att)
		fight=fight+att:UpData(kv,self.part)
	end
	for i=#list+1,#self.attList do
		local att = self.attList[i]
		att:SetActive(false)
	end
	self.grid:Reposition()

	self.fight.text=math.ceil( fight*10000)
end

-- function My:ShowLockState(att)
-- 	local lockNum = 0
-- 	for i,v in ipairs(self.lockList) do
-- 		if v==true then lockNum=lockNum+1 end
-- 	end
-- 	local ena = self.lockList[index] or false
-- 	local active = false
-- 	if #list==1 then 
-- 		active=true
-- 	else
-- 		if ena==true then 
-- 			active=true
-- 		else
-- 			if lockNum<3 then active=true end
-- 		end
-- 	end

-- 	att:TogState(active)
-- end

--洗炼
function My:StrBtn()
	local opendata = EquipOpenLv[tostring(self.part)]
	if not opendata then iTrace.eError("xiaoyu","装备部位开启表为空 id: "..self.part)return end
    if User.instance.MapData.Level<opendata.lv then 
        UITip.Log("未达到开启等级")
        return 
	end
	for i,v in ipairs(self.attList) do
		local value = v.tog.value
		if value==false and v.kv and v.qua>=4 then 
			MsgBox.ShowYesNo("洗炼列表中含有橙色及以上属性，确定洗炼？",self.StrCb,self)
			return 
		end
	end
	self:StrCb()
end

function My:StrCb()
	local lock = EquipMgr.lockDic[tostring(self.part)]
	if self.islock==true and EquipMgr.freeTime==0 then 
		UIMgr.Open(UIGetWay.Name,self.GetWayCb,self)
		EquipMgr.ReqConcise(self.id,self.type,lock)
		return
	end
	EquipMgr.ReqConcise(self.id,self.type,lock)
end

function My:GetWayCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:SetPos(Vector3.New(192.71,-188.46,0))
		ui:CreateCell("道庭任务",self.OnClkFmlMis,self)
	end
end

--点击道庭任务
function My:OnClkFmlMis()
	if CustomInfo:IsJoinFamily() == false then return true end
	if OpenMgr:IsOpen(33) == false then  UITip.Log("系统未开启") return true end
	UIMgr.Open(UIFamilyMission.Name);
end

function My:OnClickCopyItem()
	local x,y,z,w = CopyMgr:GetCurCopy(CopyType.Glod)
	if y==false then 
		UITip.Error("等级不足系统暂未开启")
		UIMgr.Close(UIGetWay.Name)
		return 
	end
	JumpMgr:InitJump(UIEquip.Name,1,1)
	UICopy:Show(CopyType.Glod)
end

function My:Best()
	if self.best.value==true then
		self.type=2 
	else
		self.type=1
	end
end

--属性
-- function My:OnAtt(name,value)
-- 	local att = self.attList[tonumber(name)]
-- 	--self:ShowLockState(att)
-- 	self.lockList[tonumber(name)]=value
-- 	self:UpLockPrice()
-- end

function My:OnClickCell(part)
    self.part=part
    local tb = EquipMgr.hasEquipDic[part]
    self:UpData(tb)
end

function My:UpTip()
	self.str:Dispose()
	local color = ""
	local count = EquipMgr.freeTime
	if count==0 then 
		self.str:Apd("[99886b]每日免费洗炼次数： [-]"):Apd("[e83030]0[-]"):Apd("[99886b]/3")
	else
		self.str:Apd("[99886b]每日免费洗炼次数： "):Apd(count):Apd("/3")
	end
	self.Tip.text=self.str:ToStr()
end

function My:Open()
	self:SetEvent("Add")
    self.go:SetActive(true)
    if EquipPanel.curPart then self:OnClickCell(EquipPanel.curPart) end
end

function My:Close()
	self:SetEvent("Remove")
	self.go:SetActive(false)
end


function My:Dispose()
    self:Close()
    if self.str then ObjPool.Add(self.str) self.str=nil end
	if self.cell1 then self.cell1:DestroyGo() ObjPool.Add(self.cell1) self.cell1=nil end
	if self.cell2 then self.cell2:DestroyGo() ObjPool.Add(self.cell2) self.cell2=nil end
	ListTool.ClearToPool(self.attList)
	--ListTool.Clear(self.lockList)
	TableTool.ClearUserData(self)
end