--[[
 	authors 	:Liu
 	date    	:2019-6-25 20:20:00
 	descrition 	:限定活动
--]]

UILimitActiv = UIBase:New{Name = "UILimitActiv"}

local My = UILimitActiv

local strs = "UI/UILimitActiv/"
require(strs.."UIActivXTZL")
require(strs.."UIActivDL")
require(strs.."UIActivSD")

function My:InitCustom()
    local des = self.Name
    local root = self.root
    local Find = TransTool.Find
    local SetB = UITool.SetBtnClick
    local FindC = TransTool.FindChild

    self.strDic = {}
    self.actionDic = {}
    self.togDic = {}
    self.modDic = {}
    self.modInfoDic = {}
    self.curIndex = 0

    self.item = FindC(root, "BtnGrid/item", des)
    self.XTZLTran = Find(root, "XTZL", des)
    self.DLTran = Find(root, "DL", des)
    self.SDTran = Find(root, "SD", des)
    self.item:SetActive(false)

    SetB(root, "CloseBtn", des, self.OnClose, self)

    self:InitMod()
    self:InitTog()
    self:UpAction()
    self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
    PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
    LimitActivMgr.eBuy[func](LimitActivMgr.eBuy, self.RespBuy, self)
    LimitActivMgr.eUpAction[func](LimitActivMgr.eUpAction, self.UpAction, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10377 or action==10405 then
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

--响应仙途商店兑换
function My:RespBuy(id)
    local it = self.modDic["3"]
    if it then
        it:UpItemData()
    end
end

--初始化模块
function My:InitMod()
    if LivenessInfo:IsOpen(1029) then
        self.strDic["1"] = "仙途之路"
        self.modInfoDic["1"] = CustomMod:GetModInfo(self.XTZLTran, UIActivXTZL)
    end

    if LivenessInfo:IsOpen(1034) then
        self.strDic["2"] = "材料掉落"
        self.modInfoDic["2"] = CustomMod:GetModInfo(self.DLTran, UIActivDL)
    end

    if LivenessInfo:IsOpen(1035) then
        self.strDic["3"] = "仙途商店"
        self.modInfoDic["3"] = CustomMod:GetModInfo(self.SDTran, UIActivSD)
    end
end

--初始化Tog
function My:InitTog()
    CustomMod:SetTog(self.item, self.strDic, self.actionDic, self.togDic)
    CustomMod:SetTogFunc(self.togDic, "OnTog", self)
    CustomMod:InitTogState(self.index, self.togDic, self.modInfoDic)

    local index = CustomMod:GetOpenIndex(self.index, self.togDic)
    local tabId = CustomMod:GetModIndex(self.modInfoDic)
    if index == -1 then index = tabId end
    self:SwitchMenu(index)
end

--点击Tog
function My:OnTog(go)
    self:SwitchMenu(go.name)
end

--设置界面
function My:SwitchMenu(key)
    if self.curIndex == key then return end
    CustomMod:InitModInfo(key, self.modDic, self.modInfoDic)
    CustomMod:UpShowMod(key, self.modDic)
    self.curIndex = key
end

--更新红点
function My:UpAction()
    local dic = self.actionDic
    for k,v in pairs(LimitActivMgr.actionDic) do
        local go = dic[k]
        if go then
            go:SetActive(v)
        end
	end
end

--仙途之路
--材料掉落
--仙途商店
function My:OpenTab(index)
    local isOpen = UITabMgr.Pattern3(ActivityMgr.XTZL)
    if isOpen == false then return end
    if index == nil then UITip.Log("参数错误") return end
    self.index = tostring(index)
    UIMgr.Open(UILimitActiv.Name)
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)
    self.index = tostring(t1)
end

--点击关闭
function My:OnClose()
    self:Close()
    JumpMgr.eOpenJump()
end

--清理缓存
function My:Clear()
    self.curIndex = 0
    self.dic = nil
end

--释放资源
function My:DisposeCustom()
    self:Clear()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.modDic)
    TableTool.ClearDic(self.modInfoDic)
end

return My