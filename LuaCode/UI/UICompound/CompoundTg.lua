require("UI/UICompound/TBase")
require("UI/UICompound/T1")
require("UI/UICompound/T2")
require("UI/UICompound/T34")
require("UI/UICompound/T5")
require("UI/UICompound/T6")
require("UI/UICompound/EquipPartCell")
require("UI/UICompound/UIEquipItemCell")
require("UI/UICompound/SelectE")
require("UI/UICompound/NaturePartCell")

CompoundTg=EquipTgBase:New{Name="CompoundTg"}
local My = CompoundTg
local GI = GameObject.Instantiate
local CG = ComTool.Get

function My:InitCustom(go)
	local TF = TransTool.FindChild
	self.SelectEgo=TF(self.trans,"W1/TipPanel/SelectE")
    local t1 = ObjPool.Get(T1)
    t1:Init(TF(self.trans,"T1"),self)
    local t2 = ObjPool.Get(T2)
	t2:Init(TF(self.trans,"T2"),self)
	local t34 = ObjPool.Get(T34)
	t34:Init(TF(self.trans,"T34"),self,EquipPartCell)
	t34:DataCustom(1)
	local t5 = ObjPool.Get(T5)
	t5:Init(TF(self.trans,"T5"),self)
	local t6 = ObjPool.Get(T6)
	t6:Init(TF(self.trans,"T6"),self,NaturePartCell)
	t6:DataCustom(5)
    table.insert( self.tgList,t1) --宝石合成
    table.insert( self.tgList,t2) --道具合成
	table.insert( self.tgList,t34) --装备合成
	table.insert( self.tgList,t34) --饰品合成
	table.insert( self.tgList,t5) --首饰进阶
	table.insert( self.tgList,t6) --天机印合成合成
	table.insert( self.tgList,t34) --首饰合成

	self.w1=TF(self.trans,"W1")
	self.eff=TF(self.trans,"W1/eff")
	self.CBtn=TF(self.trans,"W1/CBtn")
	self.bg=TF(self.trans,"W1/bg")
	UIEvent.Get(TF(self.trans,"W1/CBtn")).onPress= UIEventListener.BoolDelegate(self.OnPressCBtn, self)
    if not self.TList then self.TList={} end
    self.Succed=CG(UILabel,self.trans,"W1/bg/Succed",self.Name,false)
	self.Panel=CG(UIPanel,self.trans,"W1/Panel",self.Name,false)
	self.scrollview=CG(UIScrollView,self.trans,"W1/Panel",self.Name,false)
	self.table=CG(UITable,self.Panel.transform,"Table",self.Name,false)
	self.table.onCustomSort=function(a,b) return self:SortName(a,b)end
    self.TAB = self.table.transform
	self.T=TF(self.TAB,"T")
	self.Tg=TF(self.TAB,"Tg")
    self:InitTog(7)
	if not self.timer then self.timer=ObjPool.Get(iTimer) self.timer.complete:Add(self.Complete,self) self.timer.seconds=0.1 end
	if not self.tgRed then self.tgRed={} end --大标签红点
	if not self.tRed then self.tRed={} end --小标签红点

	self:OnTogRed(EquipMgr.redBoolCom["2"],2)
	self:OnTogRed(EquipMgr.redBoolCom["3"],3)
	self:OnTogRed(EquipMgr.redBoolCom["4"],4)
	self:OnTogRed(EquipMgr.redBoolCom["5"],5)
	self:OnTogRed(EquipMgr.redBoolCom["6"],6)
	self:OnTogRed(EquipMgr.redBoolCom["7"],7)

	local open2 = OpenMgr:IsOpen(13)
	self.togList[2].gameObject:SetActive(open2)
	local open34 = OpenMgr:IsOpen(19)
	self.togList[3].gameObject:SetActive(open34)
	self.togList[4].gameObject:SetActive(open34)
	self.togList[7].gameObject:SetActive(open34)
	local open5 = OpenMgr:IsOpen(58)
	self.togList[5].gameObject:SetActive(open5)
	local open6 = OpenMgr:IsOpen(706)
	self.togList[6].gameObject:SetActive(open6)

	self.SelectE=ObjPool.Get(SelectE)
	self.SelectE:Init(self.SelectEgo)
end

function My:SortName(a,b)
	local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:SetEvent(fn)
	EquipMgr.eCompose[fn](EquipMgr.eCompose,self.OnCompose,self)
	EquipMgr.eComRed[fn](EquipMgr.eComRed,self.OnTogRed,self)
	EquipMgr.eChangeComRed[fn](EquipMgr.eChangeComRed,self.OnChangeRed,self)
	PropMgr.eRemove[fn](PropMgr.eRemove,self.PropRmove,self)
	PropMgr.eAdd[fn](PropMgr.eAdd,self.PropAdd,self)
	PropMgr.eUpNum[fn](PropMgr.eUpNum,self.PropUpNum,self)
	SelectE.eSelect[fn](SelectE.eSelect,self.OnSelect,self)
end

function My:OnTogRed(isred,bType,sType)
	local red=self.togRedList[bType]
	red:SetActive(isred)
end

function My:OnChangeRed(bType,sType)
	if UICompound.bTp~=bType then return end
	local dic = nil
	if bType==2 then
		dic=EquipMgr.red32Dic
	elseif bType==3 then
		dic = EquipMgr.red33Dic
	elseif bType==4 then
		dic=EquipMgr.red34Dic
	elseif bType==6 then 
		dic=EquipMgr.red6Dic
	elseif bType==7 then
		dic=EquipMgr.red35Dic
	end
	if not dic then return end
	for i,v in pairs(dic) do
		local isstate = false
		local tgRed = self.tgRed[tostring(i)]
		if not tgRed then return end
		for i1,v1 in pairs(v) do
			local tg=tgRed[tostring(i1)]
			if tg then tg:SetActive(v1) end
			if v1==true then isstate=true end
		end
		local vtg = self.tRed[tostring(i)]
		if vtg then vtg:SetActive(isstate) end
	end
end

function My:PropRmove(id,tp,type_id,action)
	if tp~=1 then return end
	self:UpTgData(type_id)
end

function My:PropAdd(tb,action,tp)
	if tp~=1 then return end
	self:UpTgData(tb.type_id)
end

function My:PropUpNum(tb,tp,num,action)
	if tp~=1 then return end
	self:UpTgData(tb.type_id)
end

function My:OnSelect()
	local tg = self.tgList[self.bTp]
	if tg then
		tg:OnSelect()
	end
end

function My:UpTgData(type_id)
	local item = UIMisc.FindCreate(type_id)
	local uFx = item.uFx
	local tg = self.tgList[self.bTp]
	if uFx==31 then --宝石
		if tg and self.bTp==1 then tg:UpData() end
	elseif uFx==1 then --装备
		
	else --道具
		if tg and (self.bTp==2 ) then tg:UpData() end
	end
end

--合成返回
function My:OnCompose(suc)
    local tg = self.tgList[self.bTp]
    if tg then 
        tg:OnCompose() 
    end
	if suc==true then
		self.eff:SetActive(false)
		self.eff:SetActive(true)
	end
end

-- function My:OnCBtn()
--     -- body
-- end

function My:Complete()
    local tg = self.tgList[self.bTp]
    if tg then 
        tg:OnCbtn() 
    end
    if tg.islong==true then self.timer:Start() end
end

function My:OnPressCBtn(go,ispress)
	local tg = self.tgList[self.bTp]
	if tg and tg.islong==true then 
		if ispress==true and self.ispress~=true then
			self.timer:Start()
			self.ispress=true
		else
			if tg then 
				tg:OnCbtn() 
			end
			self.timer:Stop()
			self.ispress=false
		end
	else
		if tg and ispress==true then 
			tg:OnCbtn() 
		end
	end
end

function My:SwitchTgCustom()
	UICompound.bTp=self.bTp
    local tg = self.tgList[self.bTp]
	if tg then 
		tg.sTp=self.bTp
		self.w1:SetActive(true)
		if self.bTp == 5 then self.w1:SetActive(false) end
		tg:CreateTb(self.id) 
		if self.bTp<=2 then 
			self.CBtn:SetActive(true)
			self.bg:SetActive(true)
		end
		self:OnChangeRed(self.bTp)

		self.scrollview:ResetPosition()
		self.Panel.transform.localPosition=Vector3.New(462,-11,0)
		self.Panel.clipOffset = Vector2.zero

		GetWayFunc.SetJump(UICompound.Name,self.bTp)
	end
end

function My:CreateT(text,i)
	local go = GI(self.T)
	go.transform.parent=self.TAB
	go:SetActive(true)
	go.name=i
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero
	local lab=CG(UILabel,go.transform,"Label",self.Name,false)
	lab.text=text
	local red = TransTool.FindChild(go.transform,"red")
	self.tRed[tostring(i)]=red
	self.TList[#self.TList+1]=go
	return go
end

function My:CreateTg(parent,text,type,rank)
	local go = GI(self.Tg)
	go.transform.parent=parent
	go:SetActive(true)
	go.name=rank
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero
	local lab = ComTool.Get(UILabel,go.transform,"Label",self.Name,false)
	lab.text=text
	local red = TransTool.FindChild(go.transform,"red")
	local redList = self.tgRed[tostring(type)]
	if not redList then redList={} self.tgRed[tostring(type)]=redList end
	redList[rank]=red
	self.TList[#self.TList+1]=go
	return go
end

function My:TgState(bg,state)
	if(state==true)then
		bg.spriteName="ty_a12"
	else
		bg.spriteName="ty_a19"
	end
end

function My:UpData(tId,text)
	if(self.Cell==nil)then  
		self.Cell=ObjPool.Get(UIItemCell)
		self.Cell:InitLoadPool(self.trans,nil,nil,nil,nil,Vector3.New(-102,7.3,0))
	end
	self.type_id=tostring(tId)
	self.Cell:UpData(tId)
	self.start=true
    if not text then
		--text="成功率：100%"
		text=""
    end
    self.Succed.text=text
end

function My:CleanData()
	while(#self.TList>0)do
        local go = self.TList[#self.TList]
        Destroy(go)
		self.TList[#self.TList]=nil
	end
	if self.Cell then
		self.Cell.trans.name="ItemCell"
		self.Cell:DestroyGo()
		ObjPool.Add(self.Cell)
		self.Cell=nil
	end
	TableTool.ClearDic(self.tRed)
	for k,v in pairs(self.tgRed) do
		TableTool.ClearDic(v)
	end
end

function My:DisposeCustom()
	self:CleanData()
	if self.SelectE then ObjPool.Add(self.SelectE) self.SelectE=nil end
end