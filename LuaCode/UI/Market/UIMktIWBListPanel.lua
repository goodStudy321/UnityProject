require("UI/Market/UIMktIWantList")
require("UI/Market/UIMktWBSetPanel")

UIMktIWBListPanel = Super:New{Name = "UIMktIWBListPanel"}

local M = UIMktIWBListPanel

local MAXITEMNUM = 6

local allItem = {}


function M:Init(panObj)

	self.eGetInfo = Event()
    self.obj = panObj
	self.objTrans = self.obj.transform
	local root = self.objTrans

    local C = ComTool.Get
    local T = TransTool.FindChild

	self.item = T(root, "ItemSV/Grid/Item_99")
	self.tipLb = C(UILabel,root, "PropCont/LvCont/Label", tip, false)
	self.goldNum = C(UILabel,root,"MoneyCont/Bg/MoneyNum",tip,false)
	self.inputCom = C(UIInput,root,"InputBg",tip,false)
	
	self.findBtn = T(root,"FindBtn")
    UITool.SetLsnrSelf(self.findBtn,self.ClickToFind,self)

	local tip = "UI市场求购条目面板"
	
	-- 循环控件
	self.itemsSV = C(UIScrollView, root, "ItemSV", tip, false)
	self.wrapContent =  C(UIWrapContent, root, "ItemSV/Grid", tip, false)

    self.goodsList = {}

	self.items = {}

	self.wrapContent.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)
end

function M:OpenMenu(isPz,isPj)
	MarketMgr:SetWBPJIndex(0)
	MarketMgr:SetWBPZIndex(0)
	UIMarketWnd:OpenWBFilterCont(isPz,isPj)
end

function M:CPzOrPj()
	self.goodsList = MarketMgr:GetIWBGoodsByPZorPJ(allItem)
	self:ShowData(false)
end

function M:OnUpdateItem(gObj,index,realIndex)
	if self.goodsList ~= nil then
		local rIndex = -realIndex  + 1
		self.items[index + 1]:Reset()
		self.items[index + 1]:InitCfg(self.goodsList[rIndex],function() self:SelCount(self.goodsList[rIndex]) end)
		self.items[index + 1]:SetSel(MarketMgr:GetSelBuyItemId() == self.goodsList[rIndex].id)
	end
end

-- 搜索
function M:ClickToFind()
	local tStr = self.inputCom.value

	if tStr == nil or tStr == "" then
		return
	end
	self.searchStr = tStr
	local idList = {}
	local allList = MarketMgr:GetItemAndEquipTbl()
	idList = MarketMgr:GetSearchItemIdLocal(self.searchStr,allList)

	local findList = {}
	for k,v in pairs(allList) do
		for i=1,#idList do
			if v.id == idList[i] then
				findList[#findList + 1] = v
			end
		end
	end
	if #findList == 0 or #findList == nil then
		UITip.Log("没有此商品 ！")
	else
		self.goodsList = findList
		self:ShowData(false)
	end
	self.inputCom.value = ""
end

function M:MoneyChange()
	self.goldNum.text = tostring(RoleAssets.Gold);
end

function M:Open()
    self.obj:SetActive(true)
	self:ShowData()
	self:MoneyChange()
end

function M:CopyInfo()
	allItem = {}
	for i,v in ipairs(self.goodsList) do
		allItem[#allItem + 1] = v
	end
end

function M:Close()
    self.obj:SetActive(false)
    UIMarketWnd:CloseFilterCont()
end

function M:Dispose()
	TableTool.ClearDicToPool(self.items)
	TableTool.ClearDic(self.goodsList)
	self.searchStr = ""
end

--// 选择
function M:SelCount(itemList)
	local list = itemList
	if list ~= nil then
		UIMktWBSetPanel:InitFilterBtns(list)
		MarketMgr:SetSelWantItemId(list.id)
		for i = 1,#self.items do
			if self.items[i].data.id == list.id then
				self.items[i]:SetSel(true);
			else
				self.items[i]:SetSel(false);
			end
		end
	end
end

--// 显示数据
function M:ShowData(isShow)
	if isShow == nil then isShow = true end
	local fstId = MarketMgr:GetSelFstId()
	if fstId == 1051 and isShow == true then
		self.tipLb.text = "品阶"
		self.goodsList = MarketMgr:GetWantAllById(fstId,2)
		self:OpenMenu(true,true)
		self:CopyInfo()
	elseif fstId == 1052 and isShow == true then
		self.tipLb.text = "品阶"
		self.goodsList = MarketMgr:GetWantAllById(fstId,1)
		self:OpenMenu(true,true)
		self:CopyInfo()
	elseif isShow == true then
		self.tipLb.text = "等级"
		self.goodsList = MarketMgr:GetWantItemByFstId(fstId)
		self:OpenMenu(true,false)
		self:CopyInfo()
	end
	
	
	local num = #self.goodsList

	self.wrapContent.minIndex = - num + 1
	self.wrapContent.maxIndex = 0

	if num > MAXITEMNUM then
		num = MAXITEMNUM
	end

	self:RenewItemNum(num)

	for i = 1, num do
		self.items[i]:InitCfg(self.goodsList[i],function() self:SelCount(self.goodsList[i]) end)
	end

	if self.items[1] then
		self.items[1]:ClickSelf()
	end
end

--// 克隆商品条目
function M:CloneItem()
	local cloneObj = GameObject.Instantiate(self.item);
	cloneObj.transform.parent = self.item.transform.parent;
	cloneObj.transform.localPosition = self.item.transform.localPosition;
	cloneObj.transform.localRotation = self.item.transform.localRotation;
	cloneObj.transform.localScale = self.item.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIMktIWantList)
	cloneItem:Init(cloneObj)

	local newName = ""
	if #self.items + 1 >= 100 then
		newName = string.gsub(self.item.name, "99", tostring(#self.items + 1))
	elseif #self.items + 1 >= 10 then
		newName = string.gsub(self.item.name, "99", "0"..tostring(#self.items + 1))
	else
		newName = string.gsub(self.item.name, "99", "00"..tostring(#self.items + 1))
	end
	cloneObj.name = newName

	self.items[#self.items + 1] = cloneItem

	return cloneItem
end

--// 重置条目数量
function M:RenewItemNum(number)
	for a = 1, #self.items do
		self.items[a]:Reset()
		self.items[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #self.items then
		for a = 1, realNum do
			self.items[a]:Show(true)
		end
	else
		for a = 1, #self.items do
			self.items[a]:Show(true)
		end

		local needNum = realNum - #self.items
		for a = 1, needNum do
			self:CloneItem()
		end
	end

	self.wrapContent:SortAlphabetically()
	self.itemsSV:ResetPosition()
end

return M