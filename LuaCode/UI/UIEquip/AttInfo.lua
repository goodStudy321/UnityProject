--[[
洗练属性
--]]
AttInfo=Super:New{Name="AttInfo"}
local My = AttInfo
My.eConcise=Event()
local str = ObjPool.Get(StrBuffer)

function My:Init(go)
    local CG=ComTool.Get
	local TF=TransTool.FindChild
    self.trans=go.transform
    
    self.a1=CG(UILabel,self.trans,"a1",self.Name,false)
    self.tog=CG(UIToggle,self.trans,"a1/tog",self.Name,false)
    UITool.SetBtnClick(self.trans,"a1/tog",self.Name,self.TogClick,self)
    self.b1=CG(UILabel,self.trans,"b1",self.Name,false)
    UITool.SetBtnClick(self.trans,"b1/AddBtn",self.Name,self.AddClick,self)
end

function My:UpData(kv,part)
	EquipPanel.curPart=part
	str:Dispose()
    local fight = 0
    self:SetActive(true)
	self.kv=kv

    local index = kv.k
    local id = kv.v
    local val = kv.b
    local nLua = PropName[id].nLua
	local consiDic=EquipMgr.conciseDic[tostring(EquipPanel.curPart)]
	for i2,key in ipairs(consiDic) do
		local consi = EquipConcise[key]
		local at = consi[nLua]
		if at then 
			local min = at[1]
			local max = at[2]
			if val>=min and val<=max then 
				local minval =PropTool.GetValByID(id,min)
				local maxval = PropTool.GetValByID(id,max)
				local name = PropTool.GetNameById(id)
				local va = PropTool.GetValByID(id,val)
				local color = UIMisc.LabColor(consi.qua)
				self.qua=consi.qua
				str:Apd(color):Apd(name):Apd(" +"):Apd(va):Apd("("):Apd(minval):Apd(" - "):Apd(maxval):Apd(")")
				self.a1.text=str:ToStr()
				fight=fight+min/max
				return fight
			end
		end
	end
	--如果查找不到
	self.qua=1
	local color = UIMisc.LabColor(1)
	local name = PropTool.GetNameById(id)
	local va = PropTool.GetValByID(id,val)
	str:Apd(color):Apd(name):Apd(" +"):Apd(va)
	self.a1.text=str:ToStr()
	return fight
end

--锁定属性
function My:TogClick()
	local lockList = EquipMgr.lockDic[tostring(EquipPanel.curPart)]
	if not lockList then 
		lockList={}  
		EquipMgr.lockDic[tostring(EquipPanel.curPart)]=lockList 
	end
	local value = self.tog.value
	local index = self.trans.name
	if value==true then 
		lockList[index]=true 
	else
		lockList[index]=nil
	end
	My.eConcise()
	EquipMgr.SetUserData()
end

--开启额外属性
function My:AddClick()
	local opendata = EquipOpenLv[tostring(EquipPanel.curPart)]
	if not opendata then iTrace.eError("xioayu","装备部位开启表为空 id: "..EquipPanel.curPart)return end
    if User.instance.MapData.Level<opendata.lv then 
        UITip.Log("未达到开启等级")
        return 
    end
    MsgBox.ShowYesNo("是否确定花费100绑元开启一条属性(绑元不足消耗元宝)",self.AddCb,self)
end

function My:AddCb()
	local tb = EquipMgr.hasEquipDic[tostring(EquipPanel.curPart)]
    local id = tb.type_id
	EquipMgr.ReqOpen(id)
end

function My:TogState(state)
    self.tog.gameObject:SetActive(state)
end

function My:SetActive(state)
    self.a1.gameObject:SetActive(state)
    self.b1.gameObject:SetActive(not state)
end