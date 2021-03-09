require("UI/Auction/RItem3")
require("UI/Auction/RItem3X")
UIAuctionR3 = Super:New{Name = UIAuctionR3}
local M = UIAuctionR3

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick
local Add = TransTool.AddChild

local MAXITEMNUM = 3

function M:Init(go)
    self.go = go
    local trans = go.transform

    self.sv = C(UIScrollView,trans,"SV",self.Name,false)
    self.wrap = C(UIWrapContent,trans,"SV/wrap",self.Name,false)
    self.grid = C(UIGrid,trans,"grid",self.Name,false)
    self.grid.gameObject:SetActive(false)

    self.pal = C(UIPanel,trans,"SV",self.Name)
    self.palPos = self.pal.clipOffset

    self.items = {}
    self.realIndexDic = {}
    self.dataList = {}

    self.wrap.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)
end

function M:ShowData(data)
    local firId = AuctionMgr:GetFirId()
    if data then
        self.dataList = data
    else
        if firId == "1000" then
            self.dataList = AuctionMgr:GetAllDecItem(firId)
        else
            self.dataList = AuctionMgr:GetFirstItemDic(firId)
        end
    end
    local dataList = self.dataList
    if dataList == nil or #dataList <= 0 then
        self:ReNewItemNum(0,0)
        return
    end

    local firId = AuctionMgr:GetFirId()
    local val = AucFristType[firId].isPJ
    UIAuction:OpenFilterCout(val == 1,true)
    UIAuction:OpenSearch(true)

    local num = #self.dataList

    local Ynum = math.ceil(num/5)
    local resNum = num%5
    -- local Ynum = Num + 1
    self.wrap.minIndex = - Ynum + 1
    self.wrap.maxIndex = 0

    if Ynum > MAXITEMNUM then
		Ynum = MAXITEMNUM
    end

    self:ReNewItemNum(Ynum,resNum)

    for a=1,Ynum do
        local num = (a-1)*5 + 1
        local data = {}
        for i=num,num + 4 do
            table.insert( data, self.dataList[i] )
        end
        self.items[a]:InitData(data)
    end
    -- self.sv:ResetPosition()
end

function M:OnUpdateItem(go,index,realIndex)
    -- self.pal.clipOffset = Vector2.New(0,0)
    if self.dataList ~= nil then
        local data = {}
        local rIndex = -realIndex  + 1
        local num = #self.dataList
        local Num = math.modf(num/5)
        local resNum = math.fmod(num,5)
        if rIndex == Num + 1 then
            local startIdx = Num*5 + 1
            for i=startIdx,startIdx + resNum do
                table.insert( data, self.dataList[i] )
            end
            if resNum ~= 0 then
                self.items[index + 1]:Show(true,resNum)
            end        
        else
            self.items[index + 1]:Show(true)
            local num = (rIndex-1)*5 + 1
            for i=num,num + 4 do
                table.insert( data, self.dataList[i] )
            end
        end
        self.items[index + 1]:InitData(data)
    end
end


--重置条目数量
function M:ReNewItemNum(Ynum,resNum)
    self.pal.clipOffset = Vector2.New(0,0)
    self.pal.transform.localPosition = Vector3.New(129,-9,0)

    local len = #self.items
    for i = 1,len do
		self.items[i]:Show(false)
    end

    if Ynum <= #self.items then
        for i=1,Ynum do
            self.items[i]:Show(true)
        end
	else
		for i = 1, len do
			self.items[i]:Show(true)
		end

        local needNum = Ynum - #self.items
        if resNum == 0 then
            for i = 1, needNum do
                self:CloneItem(5)
            end
        else
            if Ynum * 5 < #self.dataList then
                for i=1,Ynum do
                    self:CloneItem(5)
                end
            else
                for i = 1, needNum- 1 do
                    self:CloneItem(5)
                end
                self:CloneItem(resNum)
            end
        end
    end


    self.wrap:SortAlphabetically()
end

--//克隆限购物品条目
function M:CloneItem(num)
    local cloneObj = GameObject.Instantiate(self.grid.gameObject)
    cloneObj:SetActive(true)
	local parent=self.wrap.transform
	local AC=TransTool.AddChild
	local trans = cloneObj.transform
	local strans = self.grid.gameObject.transform
	AC(parent,trans)
	trans.localPosition = strans.localPosition
	trans.localRotation = strans.localRotation
	trans.localScale = strans.localScale

	local cell = ObjPool.Get(RItem3X)
    cell:Init(cloneObj)
    cell:Create(num)

    cell.go.name = #self.items + 1
	self.items[#self.items + 1] = cell
end

function M:Open()
    self.go:SetActive(true)
    self:ShowData()
end

function M:Close()
    self.go:SetActive(false)
end

function M:Dispose()
    TableTool.ClearDicToPool(self.items)
	self.items = nil
end

return M