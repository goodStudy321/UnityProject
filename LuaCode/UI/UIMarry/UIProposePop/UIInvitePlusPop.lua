--[[
 	authors 	:Liu
 	date    	:2018-12-15 15:05:00
 	descrition 	:宾客数增加弹窗
--]]

UIInvitePlusPop = Super:New{Name = "UIInvitePlusPop"}

local My = UIInvitePlusPop

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick

    self.lab1 = CG(UILabel, root, "lab1")
    self.lab2 = CG(UILabel, root, "lab2")
    self.countLab = CG(UILabel, root, "sliderBg/bg/spr/lab")
    self.slider = CG(UISlider, root, "sliderBg/bg")
    self.sprBox = CG(BoxCollider, root, "sliderBg/bg/spr")
    self.go = root.gameObject
    self.num = 0

    local ED = EventDelegate
    ED.Add(self.slider.onChange, ED.Callback(self.OnSliderChange, self))

    SetB(root, "sliderBg/plus", des, self.OnPlus, self)
    SetB(root, "sliderBg/lower", des, self.OnLower, self)
    SetB(root, "cancelBtn", des, self.OnCancel, self)
    SetB(root, "sureBtn", des, self.OnSure, self)
    SetB(root, "close", des, self.OnClose, self)
    self:UpLab()
    self:UpOfSteps()
end

--监听进度发生改变
function My:OnSliderChange()
    local mean = 1 / (self.slider.numberOfSteps - 1)
    local t1, t2 = math.modf(self.slider.value / mean)
    if t2 * 10 >= 5 then
        t1 = t1 + 1
    end
    self.num = t1
    self:UpCountLab(self.num)
end

--初始化进度条步数
function My:UpOfSteps()
    local temp1, temp2 = self:GetBuyInfo()
    if temp1 == nil then return end
    local maxBuy = temp1 - MarryInfo.feastData.guestNum
    self.slider.numberOfSteps = maxBuy + 1
    self.sprBox.enabled = (self.slider.numberOfSteps ~= 1)
end

--更新滑动条数值
function My:UpSliderVal(val)
    local temp1, temp2 = self:GetBuyInfo()
    if temp1 == nil then return end
    local maxBuy = temp1 - MarryInfo.feastData.guestNum
    if maxBuy == 0 then return end
    self.num = val
    self.slider.value = val / maxBuy
    self:UpCountLab(self.num)
end

--点击增加次数
function My:OnPlus()
    local temp1, temp2 = self:GetBuyInfo()
    if temp1 == nil then return end
    local maxBuy = temp1 - MarryInfo.feastData.guestNum
    if maxBuy == 0 then
        UITip.Log("购买数量已达到上限")
        return
    end
    if self.num >= maxBuy then return end
    self:UpSliderVal(self.num + 1)
end

--点击减少次数
function My:OnLower()
    if self.num < 1 then return end
    self:UpSliderVal(self.num - 1)
end

--获取购买宾客的信息
function My:GetBuyInfo()
    local cfg = GlobalTemp["61"]
    if cfg then
        return cfg.Value2[2], cfg.Value2[3]
    end
    return nil, nil
end

--更新已购买的宾客文本
function My:UpLab()
    local temp1, temp2 = self:GetBuyInfo()
    if temp1 == nil then return end
    local info = MarryInfo.feastData
    local str = string.format("[FFE9BDFF]已购买[88F8FFFF]%s/%s[-]个可邀请宾客名额", info.guestNum, temp1)
    self.lab1.text = str
end

--点击取消
function My:OnCancel()
    self:OnClose()
end

--点击确定
function My:OnSure()
    local num = self.num
    local temp1, temp2 = self:GetBuyInfo()
    if temp1 == nil then return end
    local max = num * temp2
    if max == 0 then
        self:OnClose()
        return
    end
    if MarryInfo:IsSucc(max) then
        MarryMgr:ReqAddGuest(num)
        UITip.Log("购买成功")
    else
        UIMgr.Open(UIMarryPop.Name, self.OpenPop, self)
    end
end

--打开弹窗
function My:OpenPop()
    local ui = UIMgr.Get(UIMarryPop.Name)
    if ui then
        ui:UpPanel("元宝不足，是否充值？")
    end
end

--重置进度条
function My:ResetSlider()
    self.slider.value = 0
    self:UpSliderVal(1)
end

--更新数量文本
function My:UpCountLab(num)
    self.countLab.text = num
    local max = num * 5
    local tipStr = string.format("[FFE9BDFF]是否花费[88F8FFFF]%s元宝/绑元[-]邀请[88F8FFFF]%s[-]个宾客(优先消耗绑元)", max, num)
    self.lab2.text = tipStr
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
    if state then
        self:ResetSlider()
    end
end

--点击关闭
function My:OnClose()
    self:UpShow(false)
end

--清理缓存
function My:Clear()
    self.num = 0
end

--释放资源
function My:Dispose()
    self:Clear()
    local ED = EventDelegate
	ED.Remove(self.slider.onChange, ED.Callback(self.OnSliderChange, self))
end

return My