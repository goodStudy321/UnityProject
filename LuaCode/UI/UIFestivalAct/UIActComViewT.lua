UIActComViewT = Super:New{Name = "UIActComViewT"}

local M = UIActComViewT

function M:Ctor()
    self.texList = {}
    self.cellList = {}
end

function M:Init(go)
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local trans = go.transform
    local SetB = UITool.SetBtnClick

    self.go = go

    self.img = G(UITexture, trans, "Img")
    self.des1 = G(UILabel, trans, "Des1")
    self.des2 = G(UILabel, trans, "Des2")
    self.grid = G(UIGrid, self.des2.transform, "ItemRoot/Grid")
    self.countDown = G(UILabel, trans, "Countdown")
    self.btn = FC(trans, "Des2/Btn", self.Name)

    self.des1.spacingY = 10
    self.des2.spacingY = 10

    SetB(trans, "Des2/Btn", self.Name, self.OnBtn, self)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateImg()
    self:UpdateDes()
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

function M:OnBtn()
    VIPMgr.OpenVIP(1)
end

function M:SetBtn(state)
    self.grid.gameObject:SetActive(state)
    self.btn:SetActive(not state)
end

function M:UpdateDes()
    local data = self.data
    local DateTime = System.DateTime
    local sTime = DateTime.Parse(tostring(DateTool.GetDate(data.sDate))):ToString("yyyy年MM月dd日")
    local eTime = DateTime.Parse(tostring(DateTool.GetDate(data.eDate))):ToString("yyyy年MM月dd日")
    local type = data.type
    if type == FestivalActMgr.ExpDB then
        self:SetDes(self.des1, sTime, eTime, data.explain, true)
    elseif type == FestivalActMgr.BossDrop then
        self:SetDes(self.des2, sTime, eTime, data.explain, false)
        self:UpdateDropList()
        self:SetBtn(true)
    elseif type == FestivalActMgr.CZSB then
        self:SetDes(self.des2, sTime, eTime, data.explain, false)
        self:SetBtn(false)
    end
end

function M:SetDes(des, sTime, eTime, explain, bool)
    self.des1.gameObject:SetActive(bool)
    self.des2.gameObject:SetActive(not bool)
    des.text = string.format("[581f2a]活动时间：%s - %s\n%s", sTime, eTime, explain)
end

function M:UpdateDropList()
    local data = self.data.dropList
    if data then
        local len = #data
        local list = self.cellList
        local count = #list
        local max = count >= len and count or len
        local min = count + len - max

        for i=1, max do
            if i <= min then
                list[i]:SetActive(true)
                list[i]:UpData(data[i])
            elseif i <= count then
                list[i]:SetActive(false)
            else
                local cell = ObjPool.Get(UIItemCell)
                cell:InitLoadPool(self.grid.transform)
                cell:UpData(data[i])
                table.insert(list, cell)
            end
        end
        self.grid:Reposition()
    end
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
    self:ClearTexList()
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M