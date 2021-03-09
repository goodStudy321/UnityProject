--[[
 	authors 	:Liu
 	date    	:2019-7-31 10:30:00
 	descrition 	:活跃礼包项
--]]

UIDiscountItem = Super:New{Name="UIDiscountItem"}

local My = UIDiscountItem

function My:Init(root, data)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick

    self.cellList = {}
    self.go = root.gameObject
    self.data = data

    self.grid = Find(root, "Scroll View/Grid", des)
    self.priceLab = CG(UILabel, root, "priceLab")
    self.countLab = CG(UILabel, root, "countLab")
    self.timeLab = CG(UILabel, root, "timeLab")
    self.btnLab = CG(UILabel, root, "btn/lab")
    self.desLab = CG(UILabel, root, "lab1")
    self.btnSpr = CG(UISprite, root, "btn")
    self.btnAction = FindC(root, "btnAction", des)
    self.eff = FindC(root, "fx_gm", des)
    self.timeLab.gameObject:SetActive(false)

    SetB(root, "btn", des, self.OnGet, self)

    self:InitCell()
    self:UpLab()
end

--点击领取
function My:OnGet()
    local data = self.data
    local liveness = data.liveness
    local isGet = (LivenessInfo.liveness >= liveness) and (data.isGet == false)
    if isGet == true then
        DiscountGiftMgr:ReqGetAward(data.id)
    else
        local str = string.format("当前活跃度不足%s,是否跳转到日常活跃界面？", liveness)
        MsgBox.ShowYesNo(str, self.OnYes, self)
    end
end

--点击确定
function My:OnYes()
    local isOpen = UITabMgr.IsOpen(ActivityMgr.HY)
    if isOpen then
        UIMgr.Open(UILiveness.Name)
    end
end

--初始化道具
function My:InitCell()
    for i,v in ipairs(self.data.goodsList) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid, 0.9)
        cell:UpData(v.id, v.val)
        table.insert(self.cellList, cell)
    end
end

--更新文本
function My:UpLab()
    local data = self.data
    local liveness = data.liveness
    self.priceLab.text = string.format("原价：%s元", data.oldPrice)
    self.countLab.text = string.format("活跃度满%s可领取(%s/%s)", liveness, LivenessInfo.liveness, liveness)
    self.desLab.text = data.packageName

    self:UpBtnState()
end

--更新按钮状态
function My:UpBtnState()
    local isGet = self.data.isGet
    local sprName = (isGet==false) and "btn_figure_non_avtivity" or "btn_figure_down_avtivity"
    local str = (isGet==true) and "[5d5451]已领取" or "[682222FF]领取"
    CustomInfo:SetEnabled(self.btnSpr.gameObject, isGet==false)
	self.btnSpr.spriteName = sprName
    self.btnLab.text = str
    self.eff:SetActive(isGet==false)

    self:UpAction()
end

--更新红点
function My:UpAction()
    local data = self.data
    local isGet = (LivenessInfo.liveness >= data.liveness) and (data.isGet == false)
    self.btnAction:SetActive(isGet)
end

--清理缓存
function My:Clear()

end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My