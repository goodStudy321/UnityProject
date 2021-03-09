UIActComViewF = Super:New{Name = "UIActComViewF"}

local M = UIActComViewF

require("UI/UIFestivalAct/UIActItem")

function M:Ctor()
    self.texList = {}
    self.itemList = {}
end

function M:Init(go)
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local trans = go.transform

    self.go =go
    self.countDown = G(UILabel, trans, "Countdown")
    self.img = G(UITexture, trans, "Img")
    self.sView = G(UIScrollView, trans, "Container/ScrollView")
    self.grid = G(UIGrid, self.sView.transform, "Grid")
    self.prefab = FC(self.grid.transform, "Cell")
    self.Tip = FC(trans,"spr");
    self.prefab:SetActive(false)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateImg()
    self:UpdateItemList()
    self:UpdateTimer()
    self:UpdateTip()
end

function M:UpdateImg()
    local path = self.data.texPath
    if StrTool.IsNullOrEmpty(path) or path == "0" then
        iTrace.sLog("XGY", "图片路径为空！")
    else
        WWWTool.LoadTex(path, self.LoadTex, self)
    end
end

function M:UpdateTip()
    local type = self.data.type
    if type == FestivalActMgr.LJXF then
        self:SetTipGbj(true);
    else
        self:SetTipGbj(false);
    end
end

function M:SetTipGbj(active)
    if LuaTool.IsNull(self.Tip) == true then
        return;
    end
    self.Tip:SetActive(active);
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

function M:UpdateItemList()
    local data = self.data.itemList
    local len = #data
    local list = self.itemList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateItem(data[i])
        end
    end
    self.grid:Reposition()
end

function M:CreateItem(data)
    local go = Instantiate(self.prefab)
    TransTool.AddChild(self.grid.transform, go.transform)
    local item = ObjPool.Get(UIActItem)
    item:Init(go)
    item:SetActive(true)
    item:UpdateData(data)
    table.insert(self.itemList, item)
end


function M:UpdateItemRemainCount()
    local list = self.itemList
    for i=1,#list do
        list[i]:UpdateRemainCount()
    end
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
        else
            self.timer:Stop()
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

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Close()
    self:SetActive(false)
end

function M:Open(data)
    self:SetActive(true)
    self:UpdateData(data)
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
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    self:ClearTexList()
    TableTool.ClearDicToPool(self.itemList)
    TableTool.ClearUserData(self)
end

return M