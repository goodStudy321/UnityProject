--[[
    开服累充
--]]

UIAccuPay = Super:New{Name = "UIAccuPay"}
local My = UIAccuPay

local ADItem =  require("UI/UIOpenService/UIAwardItem")
local trans = nil

function My:Init(go)
    trans=go.transform
    local des = self.Name
    local TF = TransTool.FindChild

    self.AccuDic = {}
    self.grid = ComTool.Get(UIGrid, trans, "Scroll View/Grid", des, false)
    self.Grid = TransTool.Find(trans, "Scroll View/Grid", des)
    self.UIAwardItem = TF(trans, "Scroll View/UIAwardItem", des)
    self.countDown = ComTool.Get(UILabel, trans, "CountDown",des,false)
    self:InitSelf()

    self:CreateTimer()
end

--设置监听
function My:SetLnsr(func)
    AccuPayMgr.eAwardInfo[func](AccuPayMgr.eAwardInfo, self.RespAwardInfo, self)
    AccuPayMgr.eAward[func](AccuPayMgr.eAward, self.RespAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:CreateTimer()
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
        self.timer.invlCb:Add(self.InvlCb, self)
    end
end

function My:InvlCb()
    if self.countDown and self.timer then
        self.countDown.text = string.format("[69221f]剩余时间：[-][F21919FF]%s[-]", self.timer.remain)
    end
end

function My:UpdateTImer(info)
    if not info then 
        self:StopTimer()
    else
        local second = info.eTime - TimeTool.GetServerTimeNow()*0.001
        if second <=0 then 
            self:StopTimer()
        else
            self.timer.seconds = second
            self:StartTimer()
        end
    end
end

function My:StopTimer()
    self.timer:Stop()
    self.countDown.gameObject:SetActive(false)
end

function My:StartTimer()
    self.timer:Start()
    self:InvlCb()
    self.countDown.gameObject:SetActive(true)
end

--道具添加
function My:OnAdd(action, dic)
    if action==10307 then
        self.dic = dic
        UIMgr.Open(UIGetRewardPanel.Name, self.RewardCb, self)
    end
end

--显示奖励回调的方法
function My:RewardCb(name)
    local ui = UIMgr.Get(name)
    if(ui) then
        ui:UpdateData( self.dic)
    end
end

--更新累充奖励信息
function My:RespAwardInfo(reward)
    -- AccuPayMgr.UpdateRedPoint()
    local Dic = self.AccuDic
    for i,j in pairs(Dic) do
        local cfg = j.cfg
        j:InitWordAward(cfg)
        j:InitBtnState(cfg)
    end
    self.grid:Reposition()
end

--响应获取累充奖励
function My:RespAward(reward)
    local key = tostring(reward)
    self.AccuDic[key]:HadAd()
    AccuPayInfo.RewardDic[reward] = 3
    -- AccuPayMgr.UpdateRedPoint()
    self.grid:Reposition()
end

--初始化自身
function My:InitSelf()
    self.UIAwardItem:SetActive(false)
    if TransTool.Find(trans, "Scroll View/Grid", self.Name).childCount==0 then
        self:InitItem()
    end
    self:SetLnsr("Add")
end

--初始化累充奖励模块
function My:InitItem()
    local Add = TransTool.AddChild
    for i,v in ipairs(AccuPayCfg) do
        local item = Instantiate(self.UIAwardItem)
        item:SetActive(true)
        local num = 100 + i
        item.name = num
        local tran = item.transform
        Add(self.Grid, tran)
        local temp = ObjPool.Get(ADItem)
        temp:Init(tran, v, i)
        local key = tostring(v.id)
        self.AccuDic[key] = temp
    end
    self.grid:Reposition()
end

function My:Open()
    trans.gameObject:SetActive(true)
    local data = XsActiveCfg["1003"]
    local info = LivenessInfo:GetActInfoById(data.id)
    self:UpdateTImer(info)
end

function My:Close()
	trans.gameObject:SetActive(false)
end

--清理缓存
function My:Clean()
    self.Grid = nil
    self.grid = nil
    self.UIAwardItem = nil
end

--释放资源
function My:Dispose()
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    self.dic = nil
    self:Clean()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.AccuDic)
end

return My