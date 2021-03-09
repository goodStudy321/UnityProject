
--region UICellSelect.lua
--Cell 道具类 拥有品质，强化等级 UILabel 一般用作数量
--此文件由[HS]创建生成

UICellJingPoIItem = baseclass(UICellQuality)

--local PetMgs = PetMessage.instance

--构造函数
function UICellJingPoIItem:Ctor(go)
	self.Name = "UICellSelect"
end

--初始化控件
function UICellJingPoIItem:Init()
	self:Super("Init")
	self.Value = ComTool.Get(UILabel, self.trans, "Value", self.Name, false)
	self.Title = ComTool.Get(UILabel, self.trans, "Title", self.Name, false)
	self.Slider = ComTool.Get(UISlider, self.trans, "Slider", self.Name, false)
	self.Button = ComTool.Get(UIButton, self.trans, "Button", self.Name, false)
	self.Grid = ComTool.Get(UIGrid, self.trans, "LabelGrid", self.Name, false)
	self.Prefab = TransTool.FindChild(self.trans, "LabelGrid/Item")
	self.Count = 0
	self.Num = 0
	if self.Button then
		UIEvent.Get(self.Button.gameObject).onClick = function(gameObject) self:OnClickButton(gameObject) end
	end
end

function UICellJingPoIItem:UpdateInfo(info)
	self.Info = info
	if self.Info == nil then
		self:Clean()
		return
	end
	self:UpdateItemData(tostring(info.id))
	self:UpdateIcon(info.icon)
	self:UpdateTitle(info.name)
	self.Limit = info.useNum
	self:UpdateSlider()
	self:UpdateProperty()
end

function UICellJingPoIItem:UpdateTitle(name)
	if self.Title then
		self.Title.text = name
	end
end

function UICellJingPoIItem:UpdateItemData(id)
	self.temp = ItemData[id]
	if self.temp == nil then return end
	self:UpdateNum()
	self:UpdateQuality(self.temp.quality)
end

function UICellJingPoIItem:UpdateNum()
	if not self.temp then return end
	local key = tostring(self.temp.id)
	self.Num = PropMgr.TypeIdByNum(key)
	self:UpdateLabel(self.Num)
end

function UICellJingPoIItem:UpdateProperty()
	if self.Info == nil then return end
	self:AddProperty(ProType.HP, self.Info.hp)
	self:AddProperty(ProType.Atk, self.Info.atk)
	self:AddProperty(ProType.Def, self.Info.def)
	--self:AddProperty(13, self.Info.crit_max)
	self:AddProperty(ProType.Crit, self.crit)
	self.Grid:Reposition()
end

function UICellJingPoIItem:UpdateSlider()
	if self.Info == nil or self.limit == 0 then
		self.Value.text = ""
		self.Slider.value = 0
	else
		self.Count = 0
		local key = tostring(self.Info.id)
		if self.Info ~= nil and PetMgr.UserDataDic[key] then
			self.Count = PetMgr.UserDataDic[key]
		end
		self.Value.text = self.Count.."/"..self.Limit
		self.Slider.value = self.Count / self.Limit
	end
end

function UICellJingPoIItem:AddProperty(type, num )
	if num == nil then return end
	if self.Count ~= nil then num = num * self.Count end
	if num == 0 then return end
	local go = GameObject.Instantiate(self.Prefab)
	go.name = string.gsub(go.name, "%(Clone%)", "")
	go.name = go.name.."_"..type
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	local label = ComTool.Get(UILabel, go.transform, "Name", self.Name, false)
	local value = ComTool.Get(UILabel, go.transform, "Value", self.Name, false)
	if label == nil then return end
	label.text = GetProName(type)
	value.text = tostring(num)
end

function UICellJingPoIItem:OnClickButton(go)
	if self.Count == self.Limit then
		UITip.Error("已经达到使用上限，不能继续使用！！")
		return
	end
	if not self.temp then
		UITip.Error("没有找到可以使用的精魄！！")
		return
	end
	-- local dic = PropMgr.typeIdDic[tostring(self.temp.id)]
	-- local len = LuaTool.Length(dic)
	-- if not self.Num or self.Num == 0 or len == 0 then
	-- 	UITip.Error("没有精魄可以使用！！")
	-- 	return
	-- end
	-- for k,v in pairs(dic) do
	-- 	--EventMgr.Trigger("m_item_use_tos",v.id, 1)
	-- 	return
	-- end
	local type_id = tostring(self.temp.id)
	local id = PropMgr.TypeIdById(type_id)
	local num = PropMgr.TypeIdByNum(type_id)
	if(id==nil or num==0)then
		UITip.Error("没有精魄可以使用！！")
		return
	end
	PropMgr.ReqUse(id,1)
end

function UICellJingPoIItem:UpdateItemList()
	self:UpdateNum()
end

--清楚数据
function UICellJingPoIItem:Clean()
	self:Super("Clean")
end

--释放或销毁
function UICellJingPoIItem:Dispose(isDestory)
	self.Value = nil
	self.Title = nil
	self.Slider = nil
	self.Button = nil
	self.Grid = nil
	self.Prefab = nil
	self.Count = nil
	self.Num = nil
	self.Button = nil
	self.Info = nil
	self:Super("Dispose", isDestory)
end
--endregion
