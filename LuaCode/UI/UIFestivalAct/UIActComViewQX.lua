--[[
 	authors 	:Liu
 	date    	:2019-08-01 20:40:00
 	descrition 	:七夕活动模块
--]]

UIActComViewQX = Super:New{Name = "UIActComViewQX"}

local My = UIActComViewQX

function My:Init(go)
	local root = go.transform
    local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick

	self.go = go
	self.cellList = {}
	self.texList = {}

	self.price = CG(UILabel, root, "buyDesLab/lab")
	self.grid = CG(UIGrid, root, "Scroll View/Grid")
	self.countDown = CG(UILabel, root, "Countdown")
	self.img = CG(UITexture, root, "Img")
	self.cellTran = Find(root, "CellBg/cell", des)
    
    self.desPriceLab = CG(UILabel, root, "buyDesLab")
    
	SetB(root, "btn1", self.Name, self.OnBtn1, self)
    SetB(root, "btn2", self.Name, self.OnBtn2, self)
    self:SetLocalize()
end

function My:SetLocalize()
    self.desPriceLab.text = "买1万铜钱送礼盒"
end

function My:UpdateData(data)
	self.data = data
	self:UpActTime()
	self:UpdateImg()
	self:UpPrice()
	if #self.cellList < 1 then
		self:UpCell()
		self:UpCellList()
	end
end

--响应购买
function My:UpdateItemList()
	
end

--点击按钮1
function My:OnBtn1()
	VIPMgr.OpenVIP(1)
end

--点击按钮2
function My:OnBtn2()
	local data = self:GetData()
	if CustomInfo:IsSucc(data.price) == false then
		StoreMgr.JumpRechange()
		return
	end
	FestivalActMgr:ReqBgActReward(self.data.type, 1)
end

--更新道具
function My:UpCell()
	local data = self:GetData()
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(self.cellTran, 0.9)
	cell:UpData(data.itemId)
	table.insert(self.cellList, cell)
end

--更新道具列表
function My:UpCellList()
	local data = self:GetData()
	for i,v in ipairs(data.itemList) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform, 0.9)
        cell:UpData(v.id, v.num, v.effNum==1)
        table.insert(self.cellList, cell)
    end
    self.grid:Reposition()
end

--更新价格
function My:UpPrice()
	local data = self:GetData()
	self.price.text = data.price
end

--获取数据
function My:GetData()
    return FestivalActInfo.yjqxData
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

--更新贴图
function My:UpdateImg()
    local path = self.data.texPath
    if StrTool.IsNullOrEmpty(path) or path == "0" then
		iTrace.Error("SJ", "图片路径为空！")
    else
		WWWTool.LoadTex(path, self.LoadTex, self)
    end
end

--加载贴图
function My:LoadTex(tex, err)
    if err then
        iTrace.Error("SJ", "图片加载失败")
    else
        if self.img then
            self.img.mainTexture = tex
            table.insert(self.texList, tex)
        else
            Destroy(tex)
        end
    end
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
        self.countDown.text = string.format("[E5B45FFF]活动结束倒计时：[00FF00FF]%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "[E5B45FFF]活动结束"
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
	self:ClearTimer()
	self:ClearTexList()
end

-- 释放资源
function My:Dispose()
	self:Clear()
	TableTool.ClearListToPool(self.cellList)
end

return My