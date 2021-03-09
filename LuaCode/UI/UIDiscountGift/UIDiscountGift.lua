--[[
 	authors 	:Liu
 	date    	:2019-6-10 14:23:00
 	descrition 	:特惠充值礼包
--]]

UIDiscountGift = UIBase:New{Name = "UIDiscountGift"}

local My = UIDiscountGift

require("UI/UIDiscountGift/UIDiscountGiftItem")
require("UI/UIDiscountGift/UIDiscountItem")

My.OpenGiftId = nil

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild
    local str = "Scroll View/Grid"

    self.itList = {}
    self.grid = CG(UIGrid, root, str)
    self.item = FindC(root, str.."/item")
    self.item:SetActive(false)

    SetB(root, "close", des, self.OnClose, self)

    self:InitItem()
    self:InitGiftItem()
    DiscountGiftMgr:HideAction()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    RechargeMgr.eRecharge[func](RechargeMgr.eRecharge, self.RespRecharge, self)
    DiscountGiftMgr.eUpData[func](DiscountGiftMgr.eUpData, self.RespUpData, self)
    DiscountGiftMgr.eGetAward[func](DiscountGiftMgr.eGetAward, self.RespGetAward, self)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10412 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应获取奖励
function My:RespGetAward(id)
    for i,v in ipairs(self.itList) do
        if v.data.id == id then
            v:UpBtnState()
        end
    end
end

--响应充值
function My:RespRecharge(orderId, url, proID,msg)
    RechargeMgr:StartRecharge(orderId, url, proID, msg)
end

--响应更新数据
function My:RespUpData()
    for i,v in ipairs(self.itList) do
        Destroy(v.go)
    end
    ListTool.ClearToPool(self.itList)
    self:InitItem()
end

--初始化充值礼包项
function My:InitItem()
    local list = DiscountGiftMgr.dataList
    self:SetItem(list, UIDiscountGiftItem, 1)
end

--初始化活跃礼包项
function My:InitGiftItem()
    local list = DiscountGiftMgr.giftList
    self:SetItem(list, UIDiscountItem, 2)
end

--设置礼包项
function My:SetItem(list, class, index)
    local AddC = TransTool.AddChild
    local giftId = self.OpenGiftId
    local giftItem = nil
    for i,v in ipairs(list) do
        local go = Instantiate(self.item)
        local tran = go.transform
        local num = (index==1) and 500000 or 100000
        go.name = v.id + num
        go:SetActive(true)
        AddC(self.grid.transform, tran)
        local it = ObjPool.Get(class)
        it:Init(tran, v)
        if giftId and giftId == v.id then
            giftItem = it
        end
        table.insert(self.itList, it)
    end
    if giftItem then
        giftItem.go.name = 100000
    end
    self:ItemSort()
end

--礼包排序
function My:ItemSort()
    self.grid:Reposition()
end

--关闭
function My:OnClose()
    self:Close()
end

--清理缓存
function My:Clear()
    self.dic = nil
    self.OpenGiftId = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    ListTool.ClearToPool(self.itList)
end

return My