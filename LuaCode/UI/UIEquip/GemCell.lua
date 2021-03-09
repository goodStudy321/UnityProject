--[[
宝石格子位置类
--]]
require("UI/UIEquip/GemTip")
GemCell=Super:New{Name="GemCell"}
local My=GemCell
My.eClickGem=Event()

function My:Ctor()
	self.tex=ObjPool.Get(StrBuffer)
	self.att={"hp","atk","def","arm"}
	self.tipStr=ObjPool.Get(StrBuffer)
	self.tipList={}
	self.lock  = false
end

function My:Init(go,index)
	self.index=index
	local trans = go.transform
	local TF=TransTool.FindChild
	local CG=ComTool.Get

	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(trans,0.9)
	self.Add=TF(trans,"Add")
	self.Red=TF(trans,"Red")
	self.Up=TF(trans,"Up")
	self.Att=CG(UILabel,trans,"Att",self.Name,false)
	self.Att.gameObject:SetActive(false)
	self.Lab=TF(trans,"Label")	

	UITool.SetLsnrSelf(self.cell.trans.gameObject,self.ClickGem,self,self.Name, false)
	-- PropMgr.eUpdate:Add(self.OnUpData,self)
	-- EquipMgr.eECompose:Add(self.OnECompose,self)
	-- EquipMgr.ePunch:Add(self.OnPunch,self)
	-- EquipMgr.eRemove:Add(self.OnRemove,self)
	-- EquipMgr.eAKey:Add(self.OnAKey,self)
end

--------   监听事件
function My:OnUpData()
	self:AddRedUp(self.part)
end

function My:OnECompose(tp)	
	if tp==1 then 
		local tb = EquipMgr.hasEquipDic[tostring(self.part)]
		local gemid = tb.stDic[tostring(self.index)]
		if not gemid then return end
		local gem = GemData[tostring(gemid)]
		self:UpData(gemid,"Lv."..gem.lv)
	elseif tp==2 then
		self.cell:Clean()
	end
	self:AddRedUp(self.part)
end

function My:OnPunch()
	self:UpData(self.type_id)
	self:AddRedUp(self.part)
end

function My:OnRemove()
	self:UpData(self.type_id)
	self:AddRedUp(self.part)
end

function My:OnAKey(tp)
	if tp==1 then 
		local tb = EquipMgr.hasEquipDic[tostring(self.part)]
		local gemid = tb.stDic[tostring(self.index)]
		if not gemid then return end
		local gem = GemData[tostring(gemid)]
		self:UpData(gemid,"Lv."..gem.lv)
	elseif tp==2 then
		self.cell:Clean()
	end
	self:AddRedUp(self.part)
end
----------------end

function My:ClickGem()
	GemTip.clickIndex=self.index
	My.eClickGem(self.tipStr:ToStr(),self.tipList,self.lock)
end

function My:UpData(type_id)
	local gem = GemData[tostring(type_id)]
	self.type_id=type_id
	self.cell:UpData(type_id,"Lv."..gem.lv)
	self:AddState(false)

	self.tex:Dispose()

	for i,v in ipairs(self.att) do
		local val = gem[v]
		if(val~=nil and val~=0)then
			if(StrTool.IsNullOrEmpty(self.tex:ToStr())==false)then self.tex:Apd("\n")end
			local name = PropTool.GetName(v)
			self.tex:Apd(name):Apd(" +"):Apd(tostring(val))
		end
	end
	local text = self.tex:ToStr()
	local att = self.Att.gameObject
	if StrTool.IsNullOrEmpty(text) then att:SetActive(false) else att:SetActive(true) end
	self.Att.text=text
end

function My:AddRedUp(part)
	part=tostring(part)
	ListTool.ClearToPool(self.tipList)
	self.tipStr:Dispose()
	self.part=part
	ListTool.Clear(self.gemList)
	self:CleanState()
	local tb = EquipMgr.hasEquipDic[part]
	self.equipId=tb.type_id
	local stDic = tb.stDic
	local id = stDic[tostring(self.index)]
	self.type_id=id
	if id then --已镶嵌
		local upstate =self:GetGem(id)
		local isreplace = true
		local equip = EquipBaseTemp[tostring(self.equipId)]
		local lv = VIPMgr.GetVIPLv()
		local add = lv>=7 and 1 or 0
		local num = equip.holesNum+add		
		local len = LuaTool.Length(stDic)
		local islack = len~=num 
		if islack==false then
			local data = GemData[tostring(id)]
			local tb=PropMgr.GetGemByPart(part)
			if tb then				
				for i,v in ipairs(tb) do
					local gem = GemData[tostring(v)]
					if gem.lv>data.lv then 
						isreplace=false 
						self:RedState(true) 
						return
					end
				end			
			end

			self:UpState(upstate==true and isreplace==true)
		end
	else --宝石孔为空
		local tb=PropMgr.GetGemByPart(part)
		local equip = EquipBaseTemp[tostring(self.equipId)]
		local num = equip.holesNum
		local viplv = VIPMgr.GetVIPLv()	 
		if self.index==6 and viplv>=7 then self:AddState(true)  self:RedState(tb~=nil)
		elseif self.index<=num then self:AddState(true) self:RedState(tb~=nil)
		else self:AddState(false) self:LockState(1) self:LabState(true) end
	end
end

function My:GetGem(curid)
	local hasnum = PropMgr.TypeIdByNum(curid)
	local data = GemData[tostring(curid)]
	if data.canGem==nil then return false end
	local num = data.num-1
	self.tipStr:Apd("需要消耗")
	local boolBack = self:FindNext(num,GemData,curid )
	if boolBack then
		self.tipStr:Apd("将"):Apd(data.lv):Apd("级宝石提升到"):Apd(data.lv+1):Apd("级")
		return true
	else
		soonTool.ObjAddList(self.tipList);
		return false	
	end
end
-- true完成 false到低结束
function My:FindNext( lerp,tab,curid )
	if lerp<=0 then	return true end
	local hasnum = PropMgr.TypeIdByNum(curid)
	local data = tab[tostring(curid)]
	local retBool = false
	if hasnum<lerp then
		self:AddGem(data,hasnum)
		local num = (lerp-hasnum) *(data.num)
		local need = data.need
		if need==nil then	return false end
		retBool = self:FindNext( num,tab,data.need )
	else 
		self:AddGem(data,lerp)
		retBool = true
	end
	return retBool
end

function My:AddGem(data,num)
	if num==0 then return end
	self.tipStr:Apd(data.lv):Apd("级宝石* "):Apd(num):Apd("，")
	local kv = ObjPool.Get(KV)
	kv:Init(data.id,num)
	self.tipList[#self.tipList+1]=kv
end


function My:LockState(a)
	self.lock  = a==1 and true or false
	self.cell:Lock(a)
end
function My:AddState(active)
	self.Add:SetActive(active)
end

function My:RedState(active)
	self.Red:SetActive(active)
end

function My:UpState(active)
	self.Up:SetActive(active)
end

function My:LabState(active)
	self.Lab:SetActive(active)
end

function My:CleanState()
	self:AddState(false)
	self:RedState(false)
	self:UpState(false)
	if self.index~=6 then self:LabState(false) end
end

function My:Clean()
	self.type_id=nil
	self.equipId=nil
	self.Att.text=""
	if self.cell then self.cell:Clean() end
end

function My:Dispose()
	-- PropMgr.eUpdate:Remove(self.OnUpData,self)
	-- EquipMgr.eECompose:Remove(self.OnECompose,self)
	-- EquipMgr.ePunch:Remove(self.OnECompose,self)
	-- EquipMgr.eRemove:Remove(self.OnECompose,self)
	self:Clean()
	if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) self.cell=nil end
end