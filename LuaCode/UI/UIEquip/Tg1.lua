--[[
强化
]]
require("UI/UIEquip/Suit")

Tg1=Super:New{Name="Tg1"}
local My = Tg1
local list = {"hp","atk","def","arm"}

function My:Init(go,suitGo)
    self.go=go
    local trans = go.transform
    local TF = TransTool.FindChild
    local CG = ComTool.Get
    local U = UITool.SetBtnClick
    self.str=ObjPool.Get(StrBuffer)
    if not self.attList then self.attList={} end

    U(trans,"SuitBtn",self.Name,self.OnSuit,self)
    U(trans,"StrBtn",self.Name,self.OnStr,self)
	U(trans,"AKeyBtn",self.Name,self.OnAkeyStr,self)
	self.curLvLab=CG(UILabel,trans,"curLv",self.Name,false)
	self.nextLvLab=CG(UILabel,trans,"nextLv",self.Name,false)
	self.aKeyLab = CG(UILabel,trans,"AKeyBtn/Label",self.Name,false)
	self.cell=ObjPool.Get(UIItemCell)
	self.cell:InitLoadPool(trans,nil,nil,nil,nil,Vector3.New(-157.7,-2.94,0))
	self.SVal=CG(UILabel,trans,"SVal",self.Name,false)
	self.slider=CG(UISlider,trans,"Slider",self.Name,false)
	self.numLab=CG(UILabel,trans,"CVal/num",self.Name,false)
	self.attList[1]=TF(trans,"Att1")
	self.attList[2]=TF(trans,"Att2")
	self.eff=TF(trans,"eff")
	self.eff:SetActive(false)
	self.baojieff=TF(self.eff.transform,"FX_baoji")
	self.eff:SetActive(false)

	self.suit=ObjPool.Get(Suit)
	self.suit:Init(suitGo)

	self.curLv=0
    self.isAKey=true
	
	self.timer=ObjPool.Get(iTimer)
	self.timer.complete:Add(self.OnStr,self)
	self.timer.seconds=0.1
end

function My:SetEvent(fn)
	EquipMgr.eRefine[fn](EquipMgr.eRefine,self.OnRefine,self)
	EquipMgr.eRefineFail[fn](EquipMgr.eRefineFail,self.OnRefineFail,self)
	EquipPanel.eClick[fn](EquipPanel.eClick,self.OnClickCell,self)
end

function My:OnRefineFail(tb,part)
	self.isAKey=false
	self:OnAkeyStr()
end

function My:OnClickCell(part)
	self.part=part
	local tb = EquipMgr.hasEquipDic[part]
	self:OnRefineFail()
	self:UpData(tb)
end

--强化返回
function My:OnRefine(tb,part)
	if tb.multi==1 then
		self.baojieff:SetActive(false)
	elseif tb.multi==2 then
		self.baojieff:SetActive(true)
	elseif tb.multi==3 then
		self.baojieff:SetActive(true)
	end
	--iTrace.sLog("xiaoyu","暴击率： ".. tb.multi)
	if part~=self.part then return end
	self:UpData(tb,true)
	self.eff:SetActive(false)
	self.eff:SetActive(true)

	if self.isAKey==false then 
		self.timer:Start()
	end
end

--强化套装
function My:OnSuit() 
	self.suit:UpData(self.tb.type_id)
end

--强化
function My:OnStr()
	if not self.nextatt then 
		UITip.Log("已达到强化等级上限")
		if self.isAKey==false then
			self:OnRefineFail()
		end	
		return 
	end
	if self.nextatt and User.instance.MapData.Level>=self.nextatt.level then
		if self.isenough==false then 
			UITip.Log("银两不足")
			self:OnRefineFail()
			self.pos=Vector3.New(-44.57,-187.63,0)
			UIMgr.Open(UIGetWay.Name,self.GetWayCb,self)
			EquipMgr.ReqRefine(self.tb.type_id)
			return 
		end
		EquipMgr.ReqRefine(self.tb.type_id)
	else
		if self.isAKey==false then
			self:OnRefineFail()
		end	
		UITip.Log("等级不足")
	end
end

--一键强化
function My:OnAkeyStr()
	if self.isAKey==false then --自动强化
		self.aKeyLab.text="自动强化"
		self.isAKey=true
		self.timer:Stop()
	else --取消自动
		self.aKeyLab.text="取消自动"		
		self.isAKey=false
		self.timer:Start()
	end
end

function My:GetWayCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:SetPos(self.pos)
		ui:CreateCell("摇钱树",self.OnMoneyC,self)
		ui:CreateCell("百湾角",self.OnClickCopyItem,self)
		ui:CreateCell("商城",self.OnClickStoreItem,self)
	end
end

function My:UpData(tb,isSlow)
	if not tb then return end
	self.tb=tb
	self.equip=EquipBaseTemp[tostring(tb.type_id)]

	self.cell:TipData(self.tb)
	local lv=tb.lv or 0
	local lastLv = lv+1

	local part = self.equip.wearParts
	local add = EquipMgr.FindType(part)+lv
	self.att=EquipStr[tostring(add)]
	self.nextatt=EquipStr[tostring(add+1)]

	self:UpLv(lv)
	self:UpSlider(lastLv,tb.mas,isSlow)
	
	self:UpAtt(lv)
	self:UpComsume(lastLv)
end

function My:OnMoneyC()
	UIRobbery.OpenIndex=14
	local isOpen=UIRobbery.IsOpen()
	if isOpen==true then		
		UIMgr.Open(UIRobbery.Name,self.OpenMoneyCb,self)
	end
end

function My:OpenMoneyCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:OpenRobbery(14)
	end
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

function My:OnClickStoreItem()
	JumpMgr:InitJump(UIEquip.Name,1,1)
	StoreMgr.OpenVIPStoreId(35001)
end

function My:UpLv(lv)
	self.curLvLab.text=tostring(lv)
	local next = EquipStr[tostring(EquipMgr.FindType(tonumber(self.part))+lv+1)]
	local nextLv = next~=nil and lv+1 or lv
	self.nextLvLab.text=tostring(nextLv)
end

function My:UpSlider(lv,mas,isSlow)
	if not self.nextatt then
		self.SVal.text=tostring(mas).." /MAX "
		self.slider.value=1
		return 
	end
	local tolMas=self.nextatt.mas
	self.SVal.text=tostring(mas).." / ".. tolMas

	if isSlow==true then 
		if self.curLv==lv then 
			self.rate=math.floor((mas/tolMas-self.slider.value)*100)			
		else
			local rate=0
			for i=self.curLv,lv do
				if i==lv then
					rate=rate+mas/(tolMas*1.0)
				elseif i==self.curLv then
					rate=rate+1-self.slider.value
				else
					rate=rate+1.0
				end				
			end
			self.rate=math.floor(rate*100)
			
		end		
		self.isBegain=true
		self.totalRate=mas/(tolMas*1.0)
	else
		self.isBegain=false
	end
	self.slider.value=mas/(tolMas*1.0)
	self.curLv=lv
	self.slider.value=mas/(tolMas*1.0)
end

--强化属性
function My:UpAtt(lv)
	local att =self.nextatt
	if not att then att=self.att end
	for i,v in ipairs(self.attList) do
		v:SetActive(false)
	end

	local part = self.equip.wearParts
	local add = EquipMgr.FindType(part)+lv

	if not self.att then
		if add==10000 then
			self:ShowAtt(1,"攻击",0,self.nextatt["atk"])
			self:ShowAtt(2,"破甲",0,self.nextatt["arm"])
		elseif add==20000 then
			self:ShowAtt(1,"生命",0,self.nextatt["hp"])
			self:ShowAtt(2,"防御",0,self.nextatt["def"])
		end
	else
		local index=0
		for i,v in ipairs(list) do
			local val = self.att[v]
			local lastval=att[v]
			if val ~=nil then 
				index=index+1
				local name = PropTool.Get(v).name
				--显示当前属性值和改变后的属性的值
				self:ShowAtt(index,name,val,lastval)
			end
		end
	end
end

function My:ShowAtt(index,name,curVal,nextVal)
	--赋值显示
	local go=self.attList[index]
	go:SetActive(true)
	local lab = go:GetComponent(typeof(UILabel))
	local lab1=ComTool.Get(UILabel,go.transform,"v1",self.Name,false)
	local lab2=ComTool.Get(UILabel,go.transform,"v2",self.Name,false)
	lab.text=name..":"
	lab1.text=tostring(curVal)
	lab2.text=tostring(nextVal)
end

function My:UpComsume(nextlv)
	local att = self.nextatt
	if not att then att=self.att end
	local tb = EquipMgr.hasEquipDic[tostring(self.equip.wearParts)]
	local lv=tb.lv or 0
	local money = RoleAssets.Silver
	local state = money>=att.money and true or false --and lv<maxLv
	money=money<=1 and money or UIMisc.ToString(money)
	local color = state==false and "[CC2500FF]" or "[F4DDBD]" 
	self.isenough=state
	self.str:Dispose()
	self.str:Apd(color):Apd(money):Apd(" / "):Apd(UIMisc.ToString(att.money))
	self.numLab.text=self.str:ToStr()
end

function My:Open()
	self:SetEvent("Add")
	self.go:SetActive(true)
	if EquipPanel.curPart then self:OnClickCell(EquipPanel.curPart) end
end

function My:Close()
	self:SetEvent("Remove")
	self:OnRefineFail()
	self.go:SetActive(false)
	self.baojieff:SetActive(false)
	self.eff:SetActive(false)
end

function My:Dispose()
	self:Close()
	if(self.cell~=nil)then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
	if self.suit then ObjPool.Add(self.suit) self.suit=nil end
	ListTool.Clear(self.attList)
	self.isAKey=false
	self.aKeyCnt=0
	self.baojieff:SetActive(false)
	self.eff:SetActive(false)
	TableTool.ClearUserData(self)
end