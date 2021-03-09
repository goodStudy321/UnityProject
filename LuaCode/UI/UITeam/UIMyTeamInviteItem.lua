UIMyTeamInviteItem = Super:New{Name="UIMyTeamInviteItem"}

local My = UIMyTeamInviteItem

local fMgr = FriendMgr
local uMgr = UserMgr

--初始化控件
function My:Init(go)
	self.Root = go
	self.Name = "UIMyTeamInviteItem"
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = self.Root.transform
	local name = self.Name
	self.Icon = ComTool.Get(UITexture, trans, "Icon", self.Name, false)
	self.Label = ComTool.Get(UILabel, trans, "Label", self.Name, false)
	self.LV = C(UILabel, trans, "LV", name, false)
	self.GLv = C(UILabel, trans, "GLv", name, false)
	self.InvitBtn = C(UIButton, trans, "Button", name, false)
end

--玩家数据
function My:UpdateData(type,data)
	if data == nil then 
		self.Root:SetActive(false) 
		return 
    end
    local category,name,lv = nil,nil,nil
    if type == 1 then
        category = data.Category
        name = data.Name
        lv = data.Level
    elseif type == 2 then
        category = data.category
        name = data.roleName
        lv = data.roleLv
    elseif type == 3 then
        category = data.Category
        name = data.Name
        lv = data.Level
    end
    self:UpdateIcon(category)
	-- if self.Data.Online == true then 
	-- 	name = name.." [ADFF2F]在线[-]"
	-- else
	-- 	name = name.." [919191]离线[-]"
	-- end
	self:UpdateLabel(name)
	self:UpdateLV(lv)
end

function My:UpdateIcon(cate)
	local path = string.format( "tx_0%s.png", cate)
	if self.Icon then
		self:UnloadIcon()
		if StrTool.IsNullOrEmpty(path) == false then	
			self.Icon.gameObject:SetActive(true)
		end
		self.IconName = path
		AssetMgr:Load(path,ObjHandler(self.SetIcon, self))
	end
end

function My:SetIcon(tex)
	if self.Icon then
		self.Icon.mainTexture = tex
	end
end

function My:UnloadIcon()
	if not StrTool.IsNullOrEmpty(self.IconName) then
		AssetMgr:Unload(self.IconName, ".png", false)
	end
	self.IconName = nil
end

--更新Label
function My:UpdateLabel(value)
	if self.Label then
		if value ~= 0 then
			self.Label.text = value
		else
			self.Label.text = ""
		end
	end
end

--更新玩家等级
function My:UpdateLV(lv)
	local isGod = uMgr:IsGod(lv)
	self.LV.gameObject:SetActive(not isGod)
	self.GLv.gameObject:SetActive(isGod)
	self.LV.text = uMgr:GetToLv(lv)
	self.GLv.text = uMgr:GetToLv(lv)
	-- if self.LV then
	-- 	self.LV.text = tostring(lv)
	-- 	self.LV.gameObject:SetActive(true)
	-- end
end

--释放或销毁
function My:Dispose()
	if self.Root then
		self.Root.transform.parent = nil
        Destroy(self.Root)
	end
	self.Root = nil
end