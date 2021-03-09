--region UIScrollViewBase.lua
--UIScrollView基类
--此文件由[HS]创建生成

UIScrollViewBase = baseclass()

--构造函数
function UIScrollViewBase:Ctor(go)
	self.Name = "UIScrollViewBase"
	self.gameObject = go
	self.trans = self.gameObject.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	--获取控件
	self.ScrollView = self.gameObject:GetComponent("UIScrollView")
	if not self.ScrollView then 
		self.ScrollView = C(UIScrollView, self.trans, "ScrollView", self.Name, false) 
	end
	self.Grid = C(UIGrid, self.ScrollView.transform, "Grid", self.Name, false)
	self.Prefab = T(self.ScrollView.transform, "Grid/Item")
	--定义参数对象
	self.ScrollLimit = 4
	self.MinCount = 8
	self.ItemScale = 1
	self.Items = {}
end

--初始化
function UIScrollViewBase:Init()
	-- body
end
--注册侦听事件
function UIScrollViewBase:AddEvent()
end
--更新数据
function UIScrollViewBase:UpdateData()
	-- body
end
--更新Item数据
function UIScrollViewBase:UpdateItemData( ... )
	-- body
end

--检查Items数量
--param count 当前拥有的数据数量
function UIScrollViewBase:CheckItemsCount(count)
	local itemsCount = LuaTool.Length(self.Items) 
	if itemsCount ~= count then
		self:UpdateItems(count)
	end
end

--更新Items 判断进行增加/移除
function UIScrollViewBase:UpdateItems(limit)
	if limit == nil or limit == 0 then 
		self:CleanCells()  
		return 
	end 
	local start = 0	
	local offset = 0 				-- 差值
	local row = 0					-- 新增行
	local itemsCount = LuaTool.Length(self.Items)
	if limit >= itemsCount then
		offset = limit - itemsCount	-- 差值
		row = math.ceil(offset / self.ScrollLimit)
		total = row * self.ScrollLimit + itemsCount
		start = itemsCount
		self:AddItems(start, total)
	elseif limit >= self.MinCount and limit < itemsCount then
		row = math.ceil(limit / self.ScrollLimit)
		start = row * self.ScrollLimit - 1
		total = itemsCount
		self:RemoveItems(start, total)
	end		
	self:GridReposition()							
end

--增加Items 
--param start 启始位置
--param total 最多位置
function UIScrollViewBase:AddItems(start,total)
	for i = start , total - 1 do
		self:AddItem(tostring(i))
	end
end

function UIScrollViewBase:RemoveItems(start,total)
	while start < total do
		self:RemoveItem(tostring(total))
		total = total - 1
	end
end

--增加Item
--param key item标识
function UIScrollViewBase:AddItem(key)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = string.gsub(go.name, "%(Clone%)", "")
	go.name = go.name.."_"..key
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one * self.ItemScale
	go:SetActive(true)
	self:AddCell(key, go)
end

--增加关联Cell
function UIScrollViewBase:AddCell(key, go)
	self.Items[key] = ObjPool.Get(UIItemCell)
	self.Items[key]:Init(go)
	UIEventListener.Get(go).onClick = function(gameobject) 
		self:OnClickItem(gameobject)  
	end
end

--移除Item Item中需要有gameObject对象 没有进行销毁移除的Item对象
function UIScrollViewBase:RemoveItem(key)
	if not self.Items or not self.Items[key] then return end
	self:RemoveCell(self.Items[key])
	self.Items[key] = nil
	table.remove(self.Items, key)
end

--移除Cell 需要有Dispos函数进行销毁
function UIScrollViewBase:RemoveCell(cell)
	if not cell or LuaTool.IsNull(cell.trans) then return end
	GameObject.Destroy(cell.trans.gameObject)
	cell = nil
end

--点击ItemCell
function UIScrollViewBase:OnClickItem(go)
end

--重置ScrollView是否可以拖动状态
function UIScrollViewBase:GridReposition()
	self.Grid:Reposition()
	if self.Grid:GetChildList().Count > self.ScrollLimit then 
		self.ScrollView.isDrag = true
	else
		self.ScrollView.isDrag = false
	end
end

--设置显示隐藏 显示的时候刷新数据
function UIScrollViewBase:SetActive(value)
	if self.gameObject then self.gameObject:SetActive(value) end
	if value == true then 
		self:Open()
		self:UpdateData() 
	else
		self:Close()
	end
end

function UIScrollViewBase:ActiveSelf()
	if self.gameObject then 
		return self.gameObject.activeSelf 
	end
	return false
end

function UIScrollViewBase:Open()
	-- body
end

function UIScrollViewBase:Close()
	-- body
end

--清除Item Cell数据
function UIScrollViewBase:CleanCells()
	if not self.Items then return end
	for k,v in pairs(self.Items) do
		v:Clean()
	end
end

--移除Item
function UIScrollViewBase:CleanItems()
	if not self.Items then return end
	for k,v in pairs(self.Items) do
		self:RemoveItem(k)
	end
end

--清楚数据
function UIScrollViewBase:Clean()
	self:CleanItems()
end

--释放或销毁
function UIScrollViewBase:Dispose(isDestory)
	self:Clean()
	self.gameObject = nil
	self.trans = nil
	self.ScrollView = nil
	self.Grid = nil
	self.Prefab = nil
	self.Items = nil
	if isDestory then
		self.gameObject.transform.parent = nil
		GameObject.Destroy(self.gameObject)
	end
end
--endregion
