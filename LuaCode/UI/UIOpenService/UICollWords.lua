--[[
    集字有礼
]]--

UICollWords = Super:New{Name = "UICollWords"}
local My = UICollWords

local COItem = require("UI/UIOpenService/UICollItem")
local trans = nil

function My:Init(go, data)
    if not data then return end
    trans = go.transform
    local des = self.Name
    local TF = TransTool.FindChild

    self.transObj = trans

    self.CollDic = {}
    self.grid = ComTool.Get(UIGrid, trans, "CollGrid", self.Name, false)
    self.CollGrid = TransTool.Find(trans, "CollGrid", des)
    self.UICollItem = TF(trans, "UICollItem", des)
    self.desLab = ComTool.Get(UILabel, trans, "des", des)

    self:InitSelf()
    self:SetDes(data)
end

function My:SetDes(info)
    local DateTime = System.DateTime
    local sTime = DateTime.Parse(tostring(DateTool.GetDate(info.sTime))):ToString("yyyy年MM月dd日 hh:mm")
    local eTime = ""
    if info.eTime > 0 then
        eTime = DateTime.Parse(tostring(DateTool.GetDate(info.eTime))):ToString("yyyy年MM月dd日 hh:mm")
    else
        eTime = "永久"
    end
    local detail = XsActiveCfg[tostring(info.id)].detail
    self.desLab.text = string.format( "【活动时间】  %s - %s\n【活动说明】  %s", sTime, eTime, detail)    
end

--设置监听
function My:SetLnsr(func)
    CollWordsMgr.eCollMsg[func](CollWordsMgr.eCollMsg, self.RespAwardMsg, self)
    CollWordsMgr.eGetAward[func](CollWordsMgr.eGetAward, self.RespGetAward, self)
    -- PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action, dic)
    if action==10309 then
        self.dic = dic
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
function My:RespGetAward()
    local Dic = self.CollDic
    for i,j in pairs(Dic) do
        local cfg = j.cfg
        -- j:InitBtnState()
        j:UpCountState()
    end
end

--响应领取奖励数量限制
function My:RespAwardMsg(msg)
    if msg.reward == nil then return end
    local Dic = self.CollDic
    for i,j in pairs(Dic) do
        local cfg = j.cfg
        for m,n in ipairs(msg.reward) do
            if cfg.id==n.id then
                local count = n.val
                j:InitBtnState()
                j:UpCountLab(count)
            end
        end
    end
end

--初始化自身
function My:InitSelf()
    self.UICollItem:SetActive(false)
    self:InitItem()
    self:SetLnsr("Add")
end

--初始化集字模块
function My:InitItem()
    local Add = TransTool.AddChild
    for i,v in ipairs(CollWordsCfg) do
        local item = Instantiate(self.UICollItem)
        item:SetActive(true)
        item.name = "Coll"..tostring(i)
        local tran = item.transform
        Add(self.CollGrid, tran)
        local temp = ObjPool.Get(COItem)
        temp:Init(tran, v, i)
        local key = tostring(v.id)
        self.CollDic[key] = temp
    end
    self.grid:Reposition()
end

function My:Open()
    if LuaTool.IsNull(self.transObj) then
        return
    end
	self.transObj.gameObject:SetActive(true)
end

function My:Close()
    if LuaTool.IsNull(self.transObj) then
        return
    end
	self.transObj.gameObject:SetActive(false)
end

--清理缓存
function My:Clean()
    self.CollGrid = nil
    self.grid = nil
    self.UICollItem = nil
end

--释放资源
function My:Dispose()
    self.dic = nil
    self:Clean()
    self:SetLnsr("Remove")
    TableTool.ClearDicToPool(self.CollDic)
end

return My