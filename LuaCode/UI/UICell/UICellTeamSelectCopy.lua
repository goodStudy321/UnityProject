--region UICellTeamSelectCopy.lua
--Cell 选择副本
--此文件由[HS]创建生成

UICellTeamSelectCopy = baseclass()

--构造函数
function UICellTeamSelectCopy:Ctor(go)
	self.Name = "UICellTeamSelectCopy"
	self.GO = go
	self.trans = self.GO.transform
	self.GO:SetActive(true)

end

--初始化控件
function UICellTeamSelectCopy:Init()
	local C = ComTool.Get
	local T = TransTool.FindChild
	self.BG = C(UISprite, self.trans, "BG", self.Name, false)
	self.NameLabel = C(UILabel, self.trans, "Label", self.Name, false)
	self.Select = T(self.trans, "Select")
end

--玩家数据
function UICellTeamSelectCopy:UpdateData(temp)
	self.Temp = temp
	self:UpdateName(self.Temp.name)
	self:UpdateBGState(temp)
	-- self:Updatelv()
end

function UICellTeamSelectCopy:UpdateBG(index)
	local x = index % 2
	local a = 1
	if x == 0 then a = 0.6 end
	if self.BG then
		self.BG.color = Color.New(1,1,1,a)
	end
end

function UICellTeamSelectCopy:UpdateName(name)
	if self.NameLabel then self.NameLabel.text = name end
end

function UICellTeamSelectCopy:UpdateBGState(Temp)
	local temp = Temp
	if not temp then return end
	local lv = temp.lv
	local isOpen = User.MapData.Level >= lv and CopyMgr:GetPreCopy(CopyMgr.Equip, temp.pre)
	local a = 1
	if not isOpen then
		a = 0
	end
	if self.BG then
		self.BG.color = Color.New(a,1,1,1)
	end
end

function UICellTeamSelectCopy:IsSelect(value)
	if self.Select then
		self.Select:SetActive(value)
	end
end

function UICellTeamSelectCopy:IsOpen(isInit)
	local temp = self.Temp
	local lv = 0
	if temp then
		lv = temp.lv
		if User.MapData.Level < lv and not isInit then
			self:ShowOpenTip(lv)
			return false
		end
		if temp.pre and not CopyMgr:GetPreCopy(CopyMgr.Equip, temp.pre) then
			self:ShowOpenPreTip(temp.pre)
			return false
		end
	end
	return true
end

function UICellTeamSelectCopy:ShowOpenTip(lv)
	UITip.Error(string.format("角色达到%s级开启该玩法",lv))
end

function UICellTeamSelectCopy:ShowOpenPreTip(id)
	local temp = CopyTemp[tostring(id)]
	if not temp then return end
	UITip.Error("没有达到该副本的进入条件")
end

--清楚数据
function UICellTeamSelectCopy:Clean()
	if self.NameLabel then self.NameLabel.text = "" end
	self:IsSelect(false)
end

--释放或销毁
function UICellTeamSelectCopy:Dispose(isDestory)
	--self.GO.transform.parent = nil
	if isDestory then
		Destroy(self.GO)
	end
	self.GO = nil
	self.trans = nil
	self.Name = nil
	self.NameLabel = nil
	self.Select = nil
end
--endregion
