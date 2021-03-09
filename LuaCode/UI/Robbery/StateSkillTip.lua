StateSkillTip = Super:New {Name = "StateSkillTip"}

local My = StateSkillTip


function My:Ctor()
	--技能条目列表
	self.items = {}
end

function My:Init(root)
	self.root = root
	self.gbj = root.gameObject
	local des = self.Names
	local CG = ComTool.Get
	local TFC = TransTool.FindChild
	local tr = TransTool.Find(root, "bg", des)
	self.icon = CG(UITexture, tr, "icon", des)
	self.nameLbl = CG(UILabel, tr, "name", des)
	self.desLbl = CG(UILabel, tr, "des", des)
	self.lock = TFC(tr,"lock", des)
	self.lock:SetActive(false)
	UITool.SetBtnSelf(self.gbj, self.Close, self, nil, false)
	self.bgTran = tr
end

--index:1,奖励box   2,奖励UI点击
function My:Show(it,index)
	local transP = self.bgTran.transform
	-- if index == 1 then
	-- 	transP.localPosition = Vector3.New(-263,87,0)
	-- elseif index == 2 then
	-- 	transP.localPosition = Vector3.New(271,-44,0)
	-- end
	self:ShowByLvID(it)
end

function My:ShowByLvID(data)
	if data == nil then
		return
	end
	self.desLbl.text = data.des or data.desc
	self.nameLbl.text = data.name
	self.gbj:SetActive(true)
	-- self.lock:SetActive(data.id == 24)
	-- self.icon.gameObject:SetActive(data.id ~= 24)
	-- if data.id == 24 then
	-- 	return
	-- end
    self:SetCurR(data.icon)
end

--设置当前奖励
function My:SetCurR(iconName)
    AssetMgr:Load(iconName, ObjHandler(self.LoadIconFin,self))
end

--// 读取图标完成
function My:LoadIconFin(obj)
    self.icon.mainTexture = obj
    self.iconName = self.icon.mainTexture.name
end

function My:ClearIcon()
	if self.iconName then
		AssetMgr:Unload(self.iconName,".png",false)
		self.iconName = nil
	end
end

function My:Close()
	self.gbj:SetActive(false)
end

function My:Dispose()
	self:ClearIcon()
	TableTool.ClearUserData(self)
end

return My
