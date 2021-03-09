UIDroiyanTip = {Name = "UIDroiyanTip"}
local My = UIDroiyanTip

function My:New(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function My:Init(go)
    local root  = go.transform
    local name = root.name
    self.root = root
    local CG = ComTool.Get
    local TF = Transform.Find
    local USBC = UITool.SetBtnClick
    local ED = EventDelegate
    local EC,ES = ED.Callback,ED.Set
    self.MaxNum = 5
    local US = UISlider
    self.slider = CG(US,root,"slider",name)
    self.sliderBox = CG(BoxCollider,root,"slider",name)
    self.sliderBox.enabled = false
    -- self.slider.steps = self.MaxNum
    self.thunderLab = CG(UILabel,root,"slider/thump/lbl",name)
    self.MsgStr = CG(UILabel,root,"msg",name)
    ES(self.slider.onChange,EC(self.SliderCtrlNum,self))
    USBC(root,"CloseBtn",name,self.CloseCtrl,self)
    USBC(root,"add",name,self.AddNum,self)
    USBC(root,"redc",name,self.ReduceNum,self)
    USBC(root,"bg/yesBtn",name,self.YesBtn,self)
    USBC(root,"bg/noBtn",name,self.NoBtn,self)
    if Droiyan.LeftBuyTime == nil then
        Droiyan.LeftBuyTime = 0
    end
    self.alreadyBuyTime = Droiyan.LeftBuyTime
    self.needCostGold = 0
    self.recordCostGold = 0
    -- self.curNum = Droiyan.LeftBuyTime
    self.curNum = 1
    self:SliderBtnCtr(self.curNum)
end

function My:YesBtn()
    -- local coinNum = 10 * self.curNum;
    local coinNum = self.needCostGold
    if RoleAssets.IsEnoughAsset(3,coinNum) == true then
        Droiyan.ReqBuyChallenge(self.curNum); 
    else
        local msg = "元宝不足!";
        UITip.Log(msg);
    end
    self:CloseCtrl()
end

function My:NoBtn()
    self:CloseCtrl()
end

function My:OpenC()
    if Droiyan.LeftBuyTime == nil then
        Droiyan.LeftBuyTime = 0
    end
    self.alreadyBuyTime = Droiyan.LeftBuyTime
    self.needCostGold = 0
    self.recordCostGold = 0

    -- self.curNum = Droiyan.LeftBuyTime
    self.curNum = 1
    self:SliderBtnCtr(self.curNum)
    self.root.gameObject:SetActive(true)
end

function My:CloseCtrl()
    self.root.gameObject:SetActive(false)
end

function My:AddNum()
    if self.curNum >= self.MaxNum then
        return
    end
    local num = self.curNum + 1
    self:SliderBtnCtr(num)
end

function My:ReduceNum()
    if self.curNum <= 1 then
        return
    end
    local num = self.curNum - 1
    self:SliderBtnCtr(num,true)
end

function My:SliderBtnCtr(num,isReduce)
    local globalInfo = GlobalTemp["25"]
    local firstPer = globalInfo.Value1[1].id
    local addPer = globalInfo.Value1[2].id
    local maxPer = globalInfo.Value1[3].id
    local maxPerTime = maxPer / addPer

    local haveBuyTime = self.alreadyBuyTime
    local factTime = num + haveBuyTime
    local reduceFactTime = self.curNum + haveBuyTime
    if reduceFactTime >= maxPerTime then
        reduceFactTime = maxPerTime
    end
    local reducePerGold = reduceFactTime * addPer

    local perGold = 0
    local cost = 0
    local recordCost = 0

    if haveBuyTime <= 0 then
        if num <= 1 then
            cost = num * firstPer
            perGold = firstPer
        else
            perGold = factTime * addPer
            if isReduce then
                cost = self.needCostGold - reducePerGold
            else
                cost = perGold + self.needCostGold
            end
        end
    elseif haveBuyTime > 0 and haveBuyTime < maxPerTime then
        if factTime >= maxPerTime then
            perGold = maxPer
        else
            perGold = factTime * addPer
        end
        if isReduce then
            cost = self.needCostGold - reducePerGold
        else
            cost = perGold + self.needCostGold
        end
    elseif haveBuyTime >= maxPerTime then
        perGold = maxPer
        cost = num * maxPer
    end
    local value = num / self.MaxNum
    self.needCostGold = cost
    self.slider.value = value
    self.thunderLab.text = num
    self.curNum = num
    
    local str = string.format("是否花费%s绑元(绑元不足消耗元宝)购买%s次挑战次数?%s元宝/次",cost,num,perGold)
    self.MsgStr.text = str
end

function My:SliderCtrlNum()
    local slidVal = self.slider.value
    if slidVal < 0.2 then
        return
    end
    local num = math.modf(slidVal * self.MaxNum)
    self.thunderLab.text = num
    self.curNum = num
end