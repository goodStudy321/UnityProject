UICopyInfoTreasure = UICopyInfoBase:New{Name = "UICopyInfoTreasure"}

local M = UICopyInfoTreasure

M.HarmCost = GlobalTemp["110"]
M.DefCost = GlobalTemp["111"]

M.cellList = {}

--构造函数
function M:InitSelf()
	local G = ComTool.Get
	local FC = TransTool.FindChild
	local S = UITool.SetLsnrSelf
	local F = TransTool.Find

	local trans = self.left
	self.name = G(UILabel, trans, "Name")
    self.target = G(UILabel, trans, "Target")
    self.grid = G(UIGrid, trans, "Grid")

	local other = F(self.root, "Other")
    self.btnHarm = FC(other, "BtnHarm")
    self.harmDes = G(UILabel, self.btnHarm.transform, "HarmDes")
    self.btnDef = FC(other, "BtnDef")
    self.defDes = G(UILabel, self.btnDef.transform, "DefDes")

    self.CheerView = FC(other, "CheerView")
    local parent = self.CheerView.transform
	self.CheerBlack = FC(parent, "BlackBtn")
	self.CopperT = G(UIToggle, parent, "Copper")
	self.GlodT = G(UIToggle, parent, "Glod")
	self.CopperTL = G(UILabel, parent, "Copper/Label")
	self.GlodTL = G(UILabel, parent, "Glod/Label")
	self.CostC = G(UILabel, parent, "CostC")
	self.CostG = G(UILabel, parent, "CostG")
    self.Btn2 = FC(parent, "Btn2")
    self.BuffDes = G(UILabel, parent, "Buff")
    
    S(self.btnHarm, self.OnAddHarm, self)
	S(self.btnDef, self.OnAddDef, self)
    S(self.Btn2, self.OnClickBtn2, self)
    S(self.CheerBlack, self.OnClickCheerBlack, self)
    S(self.CopperT, self.OnClickCopperT, self)
    S(self.target, self.OnClickTarget, self)

	self:SetEvent(EventMgr.Add)
end


function M:SetEvent(M)
	M("BufValOnChange", EventHandler(self.ChangeBuff, self))
end

function M:OnAddHarm()
    self:OpenCheerView(1)
end

function M:OnAddDef()
    self:OpenCheerView(2)
end

function M:OpenCheerView(_type)
    self.cheerType = _type
    local cheerInfo = CopyMgr:GetCopyCheerById(_type)
    if not cheerInfo then return end
    local cost = self:GetGlobal()
    if cheerInfo.allTimes >= cost.Value2[2] then
        UITip.Error("鼓舞次数已经用完，不能继续鼓舞")
        return
    end
    self.CheerView:SetActive(true)   
    local str = "伤害"
    local num = User:GetBufValBySrID(501)   
    if _type == 2 then
        str = "防御"
        num = User:GetBufValBySrID(502)
    end
	self:UpdateBuffDes(str, num)
	local state = cheerInfo.silverTimes >= cost.Value2[1]
	self.CopperT.value = not state
    self.GlodT.value = state
end

function M:UpdateBuffDes(str, num)
    self.BuffDes.text = string.format("[F4DDBDFF]每次鼓舞可增加角色[F39800]10%%[-]%s，最高[F39800]100%%[-]\n[00FF00FF]当前鼓舞  %s+%s%%", str, str, num)
end

function M:OnClickCopperT(go)
    local cheerInfo = CopyMgr:GetCopyCheerById(self.cheerType)
    if not cheerInfo then return end
    local cost = self.cheerType == 1 and self.HarmCost or self.DefCost
	if cheerInfo.silverTimes >= cost.Value2[1] then
		UITip.Error("已达到银两鼓舞次数上限")
	end
end

function M:ChangeBuff(buffid, value)
	local id = math.floor(buffid/1000)
	if id == 501 then
		local num = value*BuffTemp[tostring(buffid)].valueList[1].v*0.01
        self.harmDes.text = string.format("伤害+%d%%",num)
        self:UpdateBuffDes("伤害", num)
    elseif id == 502 then
		local num = value*BuffTemp[tostring(buffid)].valueList[1].v*0.01
        self.defDes.text = string.format("防御+%d%%", num)
        self:UpdateBuffDes("防御", num)
	end
end


function M:InitData()
    self:InitBuff()
	self:UpdateName()
	self:UpdateSub()
    self:UpdateReward()
end

function M:InitBuff()
	local harm = User:GetBufValBySrID(501)
	local def = User:GetBufValBySrID(502)
	self.harmDes.text = string.format("伤害+%d%%",harm) 
	self.defDes.text = string.format("防御+%d%%",def)
end

function M:UpdateReward()
    local list = self.Temp.sor0
	for i=1, #list do
		local cell = ObjPool.Get(UIItemCell)
		cell:InitLoadPool(self.grid.transform)
		cell:UpData(list[i].k, list[i].v)
		table.insert(self.cellList, cell)
    end
end


function M:UpdateName()
	local temp = self.Temp
	if not temp then return end
	self.name.text = temp.name
end

function M:UpdateSub()
	if self.target then
		local name = ""
		local monster = nil
		local info = CopyMgr.CopyInfo
		local chilTemp = CopyMgr:GetChilTemp(self.Temp, info)
		if not chilTemp then return end
		if chilTemp.mId then
			monster = MonsterTemp[tostring(chilTemp.mId)]
		end
		if monster then name = monster.name end
		self.target.text = string.format("[00FF00][%s](%s/%s)[-]", name, info.Sub, chilTemp.mNum)
	end
end


function M:OnClickBtn2(go)
	local cheerInfo = CopyMgr:GetCopyCheerById(self.cheerType)
    if not cheerInfo then return end
    local temp = self:GetGlobal()
	if cheerInfo.allTimes >= temp.Value2[2] then 
		UITip.Log("鼓舞次数达到上限，不能继续鼓舞！！")
		self.CheerView:SetActive(false)
		return
	end
	local cost = temp.Value1
	if self.CopperT.value == true and cheerInfo.silverTimes < temp.Value2[1] then 
		self:CostCopper(cost[1].id)
	else
		self.CopperT:Set(false,false)
		self.GlodT:Set(true,false)
	end
	if self.GlodT.value == true then
		self:CostGlod(cost[2].id)
	end
 end

function M:OnClickCheerBlack(go)
	if self.CheerView then self.CheerView:SetActive(false) end
end

function M:OnClickTarget(go)
	local temp = self.Temp
	if not temp then return end
	local info = CopyMgr.CopyInfo
	local childTemp = CopyMgr:GetChilTemp(temp, info)
	if not childTemp then return end
	local list = childTemp.pos
	if not list then return end
	local p1 = list[1]
	local p2 = list[2]
	local tPos = Vector3.New((p1.x + p2.x), 0, (p1.y + p2.y)) / 200
	
	User:SetCopyDesPos(tPos.x,tPos.y,tPos.x,tPos.y)
	Hangup:SetAutoSkill(false);
	Hangup:SetSituFight(true);
end


function M:CostCopper(t)
    local Cost = self:GetGlobal()
    local value = Cost.Value1[1].value
    local val = RoleAssets.GetCostAsset(t)
    if val < value then
        local n = GetCurrencyTypeName(t)
        UITip.Error(string.format( "%s不足，鼓舞失败!! 请获取%s", n, n));
        return 
    end
	CopyMgr:ReqCopyCheer(self.cheerType, t)
end

function M:CostGlod(t)
    local Cost = self:GetGlobal()
	local value = Cost.Value1[2].value
	local val = RoleAssets.GetCostAsset(t);
	 if val < value then
		 local n = GetCurrencyTypeName(t)
		 UITip.Error(string.format( "%s不足，鼓舞失败!! 请获取%s", n, n));
		 return 
	 end
	 CopyMgr:ReqCopyCheer(self.cheerType, t)
end

function M:GetGlobal()
    return self.cheerType == 1 and self.HarmCost or self.DefCost
end



function M:SetMenuStatus(value)
	if self.btnDef then
		self.btnDef:SetActive(value)
	end
	if self.btnHarm then
		self.btnHarm:SetActive(value)
	end
end

function M:DisposeSelf()
    self:SetEvent(EventMgr.Remove)
    self.cheerType = nil
    TableTool.ClearListToPool(self.cellList)
end

return M