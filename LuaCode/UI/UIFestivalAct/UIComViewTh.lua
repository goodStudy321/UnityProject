UIComViewTh = Super:New{Name = "UIComViewTh"}

local M = UIComViewTh

require("UI/UIFestivalAct/UIActDLItem")
require("UI/UIFestivalAct/UIActCopyDBItem")

function M:Ctor()
    self.texList = {}
    self.cellList1 = {}  --登陆有礼
    self.cellList2 = {}  --副本装备
    self.cellList3 = {}  --累充大礼
    self.cellList4 = {}  --单充大礼
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.go = go
    self.img = G(UITexture, trans, "Img")
    self.des1 = G(UILabel, trans, "bg1/Des1")
    self.des2 = G(UILabel, trans, "bg1/Des2")
    self.sView = G(UIScrollView, trans, "Container/ScrollView")
    self.grid = G(UIGrid, self.sView.transform, "Grid")
    self.prefab1 = FC(self.grid.transform, "Cell1")
    self.prefab2 = FC(self.grid.transform, "Cell2")
    self.prefab4 = FC(self.grid.transform, "Cell4")
    self.countDown = G(UILabel, trans, "Countdown")

    self.bg1 = FC(trans, "bg1", des)
    self.bg2 = FC(trans, "bg2", des)
    self.des3 = G(UILabel, trans, "Des3")
    self.sView1 = G(UIScrollView, trans, "Container1/ScrollView")
    self.grid1 = G(UIGrid, self.sView1.transform, "Grid")
    self.prefab3 = FC(self.grid1.transform, "item")

    self.des2.spacingY = 10
    --// 延迟重置倒数
	self.delayResetCount = 0;
end

function M:UpdateData(data)
    self.data = data
    self:UpdateImg()
    self:UpdateDes()
    self:UpdateItemList()
    self:UpdateTimer()
end

function M:UpdateTimer()
    local eDate = self.data.eDate
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

function M:InvlCb()
    self.countDown.text = string.format("活动结束倒计时：%s", self.timer.remain)
end

function M:CompleteCb()
    self.countDown.text = "活动结束"
end

function M:HideCellList(list)
    for i=1,#list do
        list[i]:SetActive(false)
    end
end

function M:UpdateItemList()
    local data = self.data
    if data.type == FestivalActMgr.CopyDb then
        self:HideCellList(self.cellList1)
        self:HideCellList(self.cellList4)
        self:UpdateCell(self.cellList2, self.prefab2, UIActCopyDBItem)
    elseif data.type == FestivalActMgr.DLYL then
        self:HideCellList(self.cellList2)
        self:HideCellList(self.cellList4)
        self:UpdateCell(self.cellList1, self.prefab1, UIActDLItem)
    elseif data.type == FestivalActMgr.DCDL then
        self:HideCellList(self.cellList1)
        self:HideCellList(self.cellList2)
        self:UpdateCell(self.cellList4, self.prefab4, UIActItem)
    elseif data.type == FestivalActMgr.LCDL then
        self:UpdateCell(self.cellList3, self.prefab3, UIActDLItem)
    end
end

function M:UpdateCell(list, prefab, class)
    local data = self.data.itemList
    local len = #data
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    local sView = (self.data.type==FestivalActMgr.LCDL) and self.sView1 or self.sView
    local grid = (self.data.type==FestivalActMgr.LCDL) and self.grid1 or self.grid

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(prefab)
            TransTool.AddChild(grid.transform, go.transform)
            local item = ObjPool.Get(class)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    grid:Reposition()
    --sView:ResetPosition()
    self:DelayResetSVPosition();
end

function M:UpdateImg()
    local path = self.data.texPath
    if StrTool.IsNullOrEmpty(path) or path == "0" then
        iTrace.sLog("XGY", "图片路径为空！")
    else
        WWWTool.LoadTex(path, self.LoadTex, self)
    end
end

function M:LoadTex(tex, err)
    if err then
        iTrace.sLog("XGY", "图片加载失败")
    else
        if self.img then
            self.img.mainTexture = tex
            table.insert(self.texList, tex)
        else
            Destroy(tex)
        end
    end
end

function M:UpdateDes()
    local data = self.data
    local isLCDL = (data.type == FestivalActMgr.LCDL)
    self:UpGoState(isLCDL)
    if isLCDL then
        self.des3.text = string.format("[F4DDBDFF]%s[-]", data.explain)
    else
        local DateTime = System.DateTime
        local sTime = DateTime.Parse(tostring(DateTool.GetDate(data.sDate))):ToString("yyyy年MM月dd日")
        local eTime = DateTime.Parse(tostring(DateTool.GetDate(data.eDate))):ToString("yyyy年MM月dd日")
        self.des1.text = string.format("[F4DDBDFF]%s - %s[-]", sTime, eTime)
        self.des2.text = string.format("[F4DDBDFF]%s[-]", data.explain)
    end
end

function M:UpGoState(state)
    self.bg1:SetActive(not state)
    self.bg2:SetActive(state)
    self.des3.gameObject:SetActive(state)
    self.sView.transform.parent.gameObject:SetActive(not state)
    self.sView1.transform.parent.gameObject:SetActive(state)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Open(data)
    self:UpdateData(data)
    self:SetActive(true)
end

function M:Close()
    self:SetActive(false)
end

function M:ClearTexList()
    local list = self.texList
    local len = #list
    for i=1,len do
        Destroy(list[i])
        list[i] = nil
    end
end

function M:Dispose()
    self.data = nil
    self:ClearTexList()
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    ListTool.Clear(self.cellList1)
    ListTool.Clear(self.cellList2)
    ListTool.Clear(self.cellList3)
    ListTool.Clear(self.cellList4)
    TableTool.ClearUserData(self)
end

function M:Update()
    if self.delayResetCount > 0 then
		self.delayResetCount = self.delayResetCount - 1;
		if self.delayResetCount <= 0 then
			self.delayResetCount = 0;
			self.sView:ResetPosition();
		end
	end
end

--// 延迟重置滑动面板位置
function M:DelayResetSVPosition()
	self.delayResetCount = 2;
end

return M