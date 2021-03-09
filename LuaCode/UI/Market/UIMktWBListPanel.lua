require("UI/Market/UIMktWantList")

UIMktWBListPanel = Super:New{Name = "UIMktWBListPanel"}

local M = UIMktWBListPanel
function M:Init(panObj)
    if self.init ~= nil and self.init == true then
        return
    end

    self.searchStr = ""
    self.init = false

    self.obj = panObj
    self.objTrans=self.obj.transform

    local C = ComTool.Get
    local T = TransTool.FindChild

    self.item = T(self.objTrans, "ItemSV/Grid/Item_99")
    self.noGoodSignObj = T(self.objTrans, "NoGoodSign")

    local tip = "UI求购条目面板"
    self.itemsSV = C(UIScrollView, self.objTrans, "ItemSV", tip, false)
    self.itemGrid = C(UIGrid, self.objTrans, "ItemSV/Grid", tip, false)
    self.goldNum = C(UILabel,self.objTrans,"MoneyCont/Bg/MoneyNum",tip,false)

    self.goodsList = nil
    self.items = {}

    self.delayResetCount = 0

    self.init = true
    self.isOpen = false

    self.inputCom = C(UIInput, self.objTrans, "Search/InputBg", tip, false)

    self.search = T(self.objTrans,"Search")

    self.findBtn=T(self.objTrans,"Search/FindBtn")
	UITool.SetLsnrSelf(self.findBtn,self.ClickToFind,self)
    RoleAssets.eUpAsset:Add(function() self:MoneyChange(); end);

    self.itemsSV.onDragFinished = function ()
		self:ContinueSearch();
	end;
    
    -- 总价排序按钮
    self.downBtn = T(self.objTrans,"PropCont/AllPCont/DownBtn")
    self.upBtn = T(self.objTrans,"PropCont/AllPCont/UpBtn")
    UITool.SetLsnrSelf(self.downBtn,self.ClickToSort,self)
    UITool.SetLsnrSelf(self.upBtn,self.ClickToSort,self)

    self.OnData = EventHandler(self.ShowData, self);
    EventMgr.Add("NewMarketGoods", self.OnData);
    
    self.OnUpdateData = EventHandler(self.ShowData, self);
    EventMgr.Add("NewMarketOnShelf", self.OnUpdateData);

    RoleAssets.eUpAsset:Add(function() self:MoneyChange(); end);
    self.eChangeBtn = Event()

    self:SetLsnr("Add")
end

-- 排序
function M:ClickToSort()
    MarketMgr:ResetToFirstState()
	MarketMgr:SetSortType(3)
	if MarketMgr:GetAllPSortType() == 0 then
		MarketMgr:SetAllPSortType(1)
		self:SetAllPSortSpriteShow(0)
	else
		MarketMgr:SetAllPSortType(0)
		self:SetAllPSortSpriteShow(1)
	end
	--// 根据条件向服务器请求数据
	MarketMgr:ReqCurSearchItemInfo()
end


-- 1为升序
function M:SetAllPSortSpriteShow(updown)
    if updown == 1 then
        self.downBtn:SetActive(false)
        self.upBtn:SetActive(true)
    elseif updown == 0 then
        self.downBtn:SetActive(true)
        self.upBtn:SetActive(false)
    else
        self.downBtn:SetActive(true)
        self.upBtn:SetActive(false)
    end
end

function M:SetLsnr(key)
    MarketMgr.eNewWantGoods[key](MarketMgr.eNewWantGoods,self.ShowData,self)
    MarketMgr.eSell[key](MarketMgr.eSell,self.ShowData,self)
end

-- 搜索
function M:ClickToFind()
    MarketMgr:ResetSearchState()
    local tStr = self.inputCom.value;
    if tStr == nil or tStr == "" then
		if tStr == nil or tStr == "" then
			MarketMgr:ClearFilterIds();
			if MarketMgr:HasWantGoods() == false then
				MarketMgr:ResetToFirstState();
				MarketMgr:ReqCurSearchItemInfo();
			end
		end
		return;
    end
    self.searchStr = tStr;
	MarketMgr:FindSearchItemIds(self.searchStr);
	if MarketMgr:HasSearchIds() == false then
		--self.inputCom.value = "";
        --UITip.Error("没有此商品 ！");
        self.noGoodSignObj:SetActive(true)
        self:RenewItemNum(0)
		return;
	end

	MarketMgr:ResetToFirstState();
	MarketMgr:ReqCurSearchItemInfo();
end

function M:MoneyChange()
	self.goldNum.text = tostring(RoleAssets.Gold);
end

--// 更新
function M:Update()
	if self.isOpen == false then
		return;
	end

	if self.delayResetCount > 0 then
		self.delayResetCount = self.delayResetCount - 1;
		if self.delayResetCount <= 0 then
			self.delayResetCount = 0;
			self.itemsSV:ResetPosition();
		end
	end
end

function M:Open()
    self.isOpen = true
    self.obj:SetActive(true)
    self:ShowData()
    self:MoneyChange()
    self:SetAllPSortSpriteShow(-1)
    MarketMgr:SetAllPSortType(1)
    self.inputCom.value = ""
end

function M:Close()
    MarketMgr:SetSelWantItemId(0)
    UIMarketWnd:CloseWBFilterCont()
    self.obj:SetActive(false)
    self.isOpen = false
    self.inputCom.value = ""
end

--//显示数据
function M:ShowData()
    -- MarketMgr:SetWBPJIndex(0)
	-- MarketMgr:SetWBPZIndex(0)
    if self.isOpen == false then
		return
    end
    
    local fstId = MarketMgr:GetSelFstId()
    local secId = MarketMgr:GetSelSecId()

    local tCfg = nil
    if secId > 0 then
        tCfg = MarketDic[tostring(secId)]
    else
        tCfg = MarketDic[tostring(fstId)]
    end
    if tCfg == nil then
        UIMarketWnd:CloseWBFilterCont()
        local showStr = StrTool.Concat("Can not find config in MarketDic !!!  fstId : ", tostring(fstId), "  secId : ", tostring(secId))
    else
        local showColorF = false
        local showQualityF = false

        if tCfg.color == 1 then
            showColorF = true
        end
        if tCfg.quality == 1 then
            showQualityF = true
        end
        UIMarketWnd:OpenWBFilterCont(showColorF,showQualityF)
    end

    local type = 0
    if MarketDic[tostring(fstId)].category == 4 then
        self.goodsList = MarketMgr:GetShelfWantGoods()
        self.search:SetActive(false)
        type = 1;
    else
        self.goodsList = MarketMgr:GetWantGoodsListById(fstId,secId)
        self.search:SetActive(true)
        type = 2;
    end
    
    if self.goodsList == nil or #self.goodsList <= 0 then
        self.noGoodSignObj:SetActive(true)
        self:RenewItemNum(0)
        return
    end

    self.noGoodSignObj:SetActive(false)
    self:RenewItemNum(#self.goodsList)
    for i=1,#self.goodsList do
        self.items[i]:InitCfg(self.goodsList[i])
    end
    self.eChangeBtn(type)
    self.isSort = false
end

--//克隆求购条目
function M:CloneItem()
    local cloneObj = GameObject.Instantiate(self.item)
    cloneObj.transform.parent = self.item.transform.parent
	cloneObj.transform.localPosition = self.item.transform.localPosition
	cloneObj.transform.localRotation = self.item.transform.localRotation
	cloneObj.transform.localScale = self.item.transform.localScale
    cloneObj:SetActive(true)
    
    local cloneItem = ObjPool.Get(UIMktWantList)
    cloneItem:Init(cloneObj)
    
    local newName = ""
	if #self.items + 1 >= 100 then
		newName = string.gsub(self.item.name, "99", tostring(#self.items + 1));
	elseif #self.items + 1 >= 10 then
		newName = string.gsub(self.item.name, "99", "0"..tostring(#self.items + 1));
	else
		newName = string.gsub(self.item.name, "99", "00"..tostring(#self.items + 1));
	end
	cloneObj.name = newName;

	self.items[#self.items + 1] = cloneItem
end

--//重置条目数量
function M:RenewItemNum(num)
    local len = #self.items
    for i=1,len do
        self.items[i]:Show(false)
    end
    local realNum = num
    if realNum <= len then
        for i=1,realNum do
            self.items[i]:Show(true)
        end
    else
        for i=1,len do
            self.items[i]:Show(true)
        end

        local needNum = realNum - len
        for i=1,needNum do
            self:CloneItem()
        end
    end

    self.itemGrid:Reposition()
    self.itemsSV:ResetPosition()
    self:DelayResetSVPosition()
end

--// 延迟重置滑动面板位置
function M:DelayResetSVPosition()
	self.delayResetCount = 2;
end

--// 继续往下搜索
function M:ContinueSearch()
	MarketMgr:ReqCurSearchItemInfo();
end

-- 释放
function M:Dispose()
    EventMgr.Remove("NewMarketGoods",self.OnData)
    EventMgr.Remove("NewMarketOnShelf",self.OnUpdateData)
    self:SetLsnr("Remove")
    
    TableTool.ClearDicToPool(self.items)
    TableTool.ClearDic(self.goodsList)
    self.delayResetCount = nil

    self.init = nil
    self.isOpen = nil
end

return M