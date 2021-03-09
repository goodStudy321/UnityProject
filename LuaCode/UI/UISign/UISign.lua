--[[
 	authors 	:Liu
 	date    	:2018-5-15 09:55:40
 	descrition 	:签到界面
--]]

UISign = Super:New{Name = "UISign"}

local My = UISign

require("UI/UISign/UISignItem")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local FindC = TransTool.FindChild
    local SetB = UITool.SetBtnClick
    local str1 = "module2/bg2/item1"
    local str2 = "module2/bg2/item2"

    self.itList = {}
    self.cellList = {}
    self.go = root.gameObject

    self.cell1 = CG(BoxCollider, root, str1)
    self.cell2 = CG(BoxCollider, root, str2)
    self.mask1 = FindC(root, str1.."/mask", des)
    self.mask2 = FindC(root, str2.."/mask", des)
    self.action1 = FindC(root, str1.."/Action", des)
    self.action2 = FindC(root, str2.."/Action", des)
    self.day = CG(UILabel, root, "module2/bg3/lab2")
    self.lab1 = CG(UILabel, root, "module2/bg2/lab1")
    self.lab2 = CG(UILabel, root, "module2/bg2/lab2")
    self.item = FindC(root, "module1/Scroll View/Grid/item")
    -- self.btnAction = FindC(root, "module2/btn/Action", des)
    self.eff = FindC(root, "module1/kuan", des)

    SetB(root, "module2/btn", des, self.OnSign, self)
    SetB(root, str1, des, self.OnSignAward1, self)
    SetB(root, str2, des, self.OnSignAward2, self)

    self:UpDays()
    self:InitItems()
    self:UpSignState()
    self:UpSignAward()
    self:UpMask()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    local mgr = SignMgr
    mgr.eSign[func](mgr.eSign, self.RespSign, self)
    mgr.eSignAward[func](mgr.eSignAward, self.RespSignAward, self)
end

--响应签到
function My:RespSign()
    self:UpSignState()
    self:UpDays()
    self:UpMask()
    self.eff:SetActive(false)
end

--响应累签奖励
function My:RespSignAward()
    self:UpSignAward()
    self:UpMask()
end

--点击签到奖励1
function My:OnSignAward1()
    local info = SignInfo
    local cfg = self.cfg1
    if cfg == nil then return end
    if info:IsGetAward(cfg.id) then return end
    if info.SignCount >= cfg.id then
        SignMgr:ReqGetSignAward(cfg.id)
    end
end

--点击签到奖励2
function My:OnSignAward2()
    local info = SignInfo
    local cfg = self.cfg2
    if cfg == nil then return end
    if info:IsGetAward(cfg.id) then return end
    if info.SignCount >= cfg.id then
        SignMgr:ReqGetSignAward(cfg.id)
    end
end

--初始化签到项
function My:InitItems()
    local Add = TransTool.AddChild
    local parent = self.item.transform.parent
    local index = self:GetIndex()
    local max = index * 30
    local min = max - 30
    for i,v in ipairs(SignCfg) do
        if i > min and i <= max then
            local go = Instantiate(self.item)
            local tran = go.transform
            Add(parent, tran)
            local it = ObjPool.Get(UISignItem)
            it:Init(tran, v)
            table.insert(self.itList, it)
        end
    end
    self.item:SetActive(false)
end

--获取当前第几轮
function My:GetIndex()
    local info = SignInfo
    local num = math.floor(info.SignCount/30)
    if (info.SignCount%30) == 0 and info.isSign then
        num = num
    else
        num = num + 1
    end
    return num
end

--更新签到状态
function My:UpSignState()
    local info = SignInfo
    local temp = info.SignCount % 30
    local num = (temp==0) and 30 or temp
    -- local isShow = false
    for i,v in ipairs(self.itList) do
        local index = (num == 30) and 1 or num + 1
        if info.isSign and i <= num then
            v:YetSign()
        elseif not info.isSign and i < index then
            v:YetSign()
        elseif not info.isSign and i == index then
            v:MaySign()
            -- isShow = true
            local tran = self.eff.transform
            TransTool.AddChild(v.root, tran)
            self.eff:SetActive(true)
            tran.localPosition = Vector3(1.5, -0.8, 0)
        else
            v:NoSign()
        end
    end
    -- self.btnAction:SetActive(isShow)
end

--更新天数
function My:UpDays()
    self.day.text = string.format("第%s天", SignInfo.SignCount)
end

--点击签到
function My:OnSign()
    if SignInfo.isSign then
        UITip.Log("今天已签到")
        return
    end
    SignMgr:ReqSign()
end

--更新签到奖励
function My:UpSignAward()
    -- TableTool.ClearListToPool(self.cellList)
    local cfg1, cfg2 = self:GetCountCfg()
    self.cfg1 = cfg1
    self.cfg2 = cfg2
    if cfg1 == nil then
        self.lab1.text = ""
    else
        self.lab1.text = string.format("累计签到%s天", cfg1.id)
        if #self.cellList < 1 then
            self:SetCell(self.cell1.transform)
        end
    end
    if cfg2 == nil then
        self.lab2.text = ""
    else
        self.lab2.text = string.format("累计签到%s天大奖", cfg2.id)
        if #self.cellList < 2 then
            self:SetCell(self.cell2.transform)
        end
    end
end

--设置道具
function My:SetCell(tran)
    local it = ObjPool.Get(UIItemCell)
    it:InitLoadPool(tran, 0.8)
    table.insert(self.cellList, it)
    if #self.cellList > 1 then
        it:UpData(self.cfg2.award[1], self.cfg2.award[2])
        self.mask2:SetActive(false)
        self.cell2.enabled = false
    end
end

--获取奖励次数限制
function My:GetCountCfg()
    local cfg1 = nil
    local cfg2 = nil
    local list = SignCountCfg
    local index = self:GetCountIndex()
    cfg1 = list[index]
    cfg2 = list[#list]
    return cfg1, cfg2
end

--获取签到次数索引
function My:GetCountIndex()
    local len = #SignInfo.SignAwardList
    for i,v in ipairs(SignCountCfg) do
        if i > len then
            return i
        end
    end
    return len
end

--更新遮罩
function My:UpMask()
    self:SetMask(self.cfg1, self.mask1, self.cell1, 1)
    -- self:SetMask(self.cfg2, self.mask2, self.cell2, 2)
end

--更新签到奖励遮罩
function My:SetMask(cfg, mask, box, index)
    if cfg == nil then return end
    local info = SignInfo
    local state = info:IsGetAward(cfg.id)
    mask:SetActive(state)
    local count = info:GetSignCount()
    if count >= cfg.id and not state then
        box.enabled = true
    else
        box.enabled = false
    end
    self.cellList[index]:UpData(cfg.award[1], cfg.award[2], box.enabled)
    local go = (index==1) and self.action1 or self.action2
    go:SetActive(box.enabled)
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
  end

--清理缓存
function My:Clear()
    self.cfg1 = nil
    self.cfg2 = nil
end

--释放资源
function My:Dispose()
    self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.itList)
    TableTool.ClearListToPool(self.cellList)
end

return My