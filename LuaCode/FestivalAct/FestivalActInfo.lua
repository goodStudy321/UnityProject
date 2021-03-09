--[[
 	authors 	:Liu
 	date    	:2019-1-18 9:40:00
 	descrition 	:节日活动信息类
--]]

FestivalActInfo = {Name = "FestivalActInfo"}

local My = FestivalActInfo

function My:Init()
    self:InitRechargeData()
    self:InitWishData()
    self:InitBlastData()
    self:InitHYLPData()
    self:InitLCLPData()
    self:InitYJQXData()

    self.itemId = 0--换道具（亲密商店）

    self.money = 0--货币（你侬我侬）
    self.keyword = ""--关键字
    self.condList = {}--条件列表
end

--初始化充值有礼数据
function My:InitRechargeData()
    self.rechargeData = {}
    local data = self.rechargeData
    data.modelId = 0
    data.fight = 0
    data.sighTitle = ""
    data.modelImg = ""
end

--初始化许愿池数据
function My:InitWishData()
    self.wishData = {}
    local data = self.wishData
    data.awardList1 = {}
    data.awardList2 = {}
    data.itemId = 0
    data.unitPrice = 0
    data.fullPrice = 0
    data.integral = 0
    data.luckVal = 0
    data.updateList = {}
    data.preciousExist = true
    data.notice = true
end

-- 初始化炼丹炉数据
function My:InitBlastData()
    self.blastData = {}
    local data = self.blastData
    data.price = 0
    data.money = 0
    data.lucky = 0
    data.tollucky = 0
    data.des = 0
    data.picDes = 0
    data.award1 = {}
    data.award2 = {}
end

--初始化一见倾心数据
function My:InitYJQXData()
    self.yjqxData = {}
    local data = self.yjqxData
    data.price = 0
    data.itemId = 0
    data.itemList = {}
end

--初始化活跃轮盘数据
function My:InitHYLPData()
    self.hylpData = {}
    local data = self.hylpData
    data.award = {}
    data.count = 0
    data.idDic = {}--已抽取的道具id
end

--初始化累充轮盘数据
function My:InitLCLPData()
    self.lclpData = {}
    local data = self.lclpData
    data.goldList = {}
    data.rateList = {}
    data.recharge = 0
    data.count = 0
end

--获取累充轮盘索引
function My:GetLCLPIndex(index, val)
    local data = self.lclpData
    local list = (index==1) and data.goldList or data.rateList
    for i,v in ipairs(list) do
        if val == v then
            return i
        end
    end
    return nil
end

--获取活跃轮盘索引
function My:GetHYLPIndex(id, num)
    for i,v in ipairs(self.hylpData.award) do
        if v.id == id and v.num == num then
            return i
        end
    end
    return nil
end

--设置活跃轮盘id列表
function My:SetLPList(id)
    local key = tostring(id)
    self.hylpData.idDic[key] = true
end

--增加轮盘次数
function My:PlusCount(index, num)
    local data = (index==1) and self.lclpData or self.hylpData
    data.count = num
end

--减少轮盘次数
function My:LowCount(index)
    local data = (index==1) and self.lclpData or self.hylpData
    data.count = data.count - 1
    if data.count < 0 then data.count = 0 end
    local mgr = FestivalActMgr
    local id = (index==1) and mgr.LCLP or mgr.HYLP
    mgr:UpdateRedPoint(id)
end

--设置奖励列表
function My:SetAwardList(list, id, num, bind, effNum)
    local data = {}
    data.id = id
    data.num = num
    data.bind = bind
    data.effNum = effNum
    table.insert(list, data)
end

--设置奖励更新列表
function My:SetUpdataList(list, id, val, type)
    local data = {}
    data.id = id
    data.state = val
    data.type = type
    table.insert(list, data)
end

--清理缓存
function My:Clear()
    self:Init()
end

--释放资源
function My:Dispose()

end

return My