--[[
 	authors 	:Liu
 	date    	:2019-2-13 16:00:00
 	descrition 	:亲密商店模块
--]]

UIActComViewSD = Super:New{Name = "UIActComViewSD"}

local My = UIActComViewSD

require("UI/UIFestivalAct/UIActSDItem")

function My:Init(go, index)
    local root = go.transform
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str = "Container/ScrollView/Grid"

    self.go = go
    self.index = index
    self.texList = {}
    self.itList = {}
    self.img = CG(UITexture, root, "Img")
    self.grid = CG(UIGrid, root, str)
    self.countDown = CG(UILabel, root, "Countdown")
    self.item = FindC(root, str.."/item")
    if index == 0 then
        self.explain = CG(UILabel, root, "spr/lab")
    elseif index == 1 then
        self.tex = CG(UITexture, root, "tex")
        self.lab = CG(UILabel, root, "tex/lab")
    end
end

--更新数据
function My:UpdateData(data)
    self.data = data
    self:InitExplainLab()
    self:UpdateImg()
    self:InitItems()
    self:UpActTime()
    self:UpBtnState()

    self:InitIcon()
    self:UpCellCount()
end

--初始化奖励项
function My:InitItems()
    if #self.itList > 0 then return end
    local itemData = self.data.itemList
    if itemData == nil then return end
    local Add = TransTool.AddChild
    for i,v in ipairs(itemData) do
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(self.grid.transform, tran)
        local it = ObjPool.Get(UIActSDItem)
        it:Init(tran, v, self.index)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self.grid:Reposition()
end

--更新按钮状态
function My:UpBtnState()
    for i,v in ipairs(self.itList) do
        v:UpBtnState()
    end
end

--更新奖励道具
function My:UpdateItemList()
    for i,v in ipairs(self.itList) do
        v:UpCellCount()
        v:UpIconCount()
        v:UpBtnState()
    end
    self:UpCellCount()
end

--更新贴图
function My:UpdateImg()
    local path = self.data.texPath
    if StrTool.IsNullOrEmpty(path) or path == "0" then
        iTrace.sLog("XGY", "图片路径为空！")
    else
        WWWTool.LoadTex(path, self.LoadTex, self)
    end
end

--加载贴图
function My:LoadTex(tex, err)
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

--初始化说明文本
function My:InitExplainLab()
    if self.index == 0 then
        self.explain.text = self.data.explain
    end
end

--更新道具数量
function My:UpCellCount()
    if self.index ~= 1 then return end
    local id = FestivalActInfo.itemId
    local count = ItemTool.GetNum(id)
    self.lab.text = count
end

--初始化兑换道具
function My:InitIcon()
    if self.index ~= 1 then return end
    local id = FestivalActInfo.itemId
    if id == 0 then return end
    local cfg = ItemData[tostring(id)]
    if cfg == nil then return end
    self.texName = cfg.icon
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--打开
function My:Open(data)
    self:SetActive(true)
    self:UpdateData(data)
end

--关闭
function My:Close()
    self:SetActive(false)
end

--设置状态
function My:SetActive(state)
    self.go:SetActive(state)
end

--更新活动时间
function My:UpActTime()
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

--间隔倒计时
function My:InvlCb()
    if self.countDown then
        self.countDown.text = string.format("活动结束倒计时：%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "活动结束"
end

--清空贴图
function My:ClearTexList()
    local list = self.texList
    local len = #list
    for i = len, 1, -1 do
        if list[i] then
            Destroy(list[i])
            list[i] = nil
        end
    end
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self:ClearTexList()
    self:ClearTimer()
end

-- 释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
    if self.texName then
        AssetMgr:Unload(self.texName,false)
    end
end

return My