
GoodByeSingleMgr = Super:New{Name = "GoodbyeSingleMgr"}

local My = GoodByeSingleMgr

My.eRed = Event()
My.eUpTopBtn = Event()
My.eUpCellBtn = Event()

function My:Init()
    self:AddLsnr()
    self.sysID = 2012
    self.actInfo = self:GetActivInfo(self.sysID)
end

function My:GetActivInfo(activId)
    local id = activId
    if not NewActivInfo.ActivInfo[id] then
        return false
    end
    return NewActivInfo.ActivInfo[id]
end

--添加监听
function My:AddLsnr()

    local Add = ProtoLsnr.Add
    Add(25002, self.RespInfo, self)
    Add(25020, self.RespInfo, self)
    Add(25022, self.RespGet, self)
end

--获取活动开始时间，结束时间
function My:GetTimeStr()
    local data = self.actInfo
    local startTm = data.startTime
    local endTm = data.endTime

    local strStart = DateTool.GetDate(startTm):ToString("MM月dd日HH:mm")
    local strEnd = DateTool.GetDate(endTm):ToString("MM月dd日HH:mm")
    local str = string.format("【活动时间】 %s-%s",strStart,strEnd)
    return str
end

--获取告别单身奖励配置表数据
function My:GetCellData()
    local dataList = {}
    local data = GoodbByeSingleCfg
    local configNum = self.configNum
    for i, v in ipairs(GoodbByeSingleCfg) do
        if v.configNum == configNum then
            table.insert(dataList, v)
        end
    end
    return dataList
end


function My:UpRedPoint()
    local data = self.netData
    local len = #data
    local n = 0
    if len > 0 then
        for i = 1, len do
            if data[i].val == 1 then
                return true
            end
            if data[i].val == 2 then
                n = n + 1
            end
        end
    elseif n == 4 then
        return false
    else
        return false
    end

end

--获取称号在称号配置表中的id(并根据此表的内容获取战力)
function My:GetTexIdList()
    local idList = {}
    local cate = User.instance.MapData.Category
    local len = #GoodbByeSingleCfg
    local rewardIdData = GoodbByeSingleCfg[len].giftList[1].n1
    local w1 = ItemCreate[tostring(rewardIdData)].w1
    local w2 = ItemCreate[tostring(rewardIdData)].w2
    local name1 = ItemData[w2].name
    local name2 = ItemData[w1].name

    for i, v in pairs(TitleCfg) do
        if v.name == name1 then
            idList[1] = v.id
            if cate == 2 then
                local title = v
                self.fightVal = PropTool.GetFight(title)
            end
        end
        if v.name == name2 then
            idList[2] = v.id
            if cate == 1 then
                local title = v
                self.fightVal = PropTool.GetFight(title)
            end
        end
    end
    return idList
end

--存入活动信息
function My:SaveActivInfo(activInfo)
    self.actInfo = activInfo;
    local info = self.actInfo
    self.configNum = info.configNum
end

--响应协议
function My:RespInfo(msg)
    self.netData = msg.propose_status_list
end

function My:RespGet(msg)

    local len = #self.netData
    local dataList = self.netData
    if len > 0 then
        for i = 1, len do
            if dataList[i].id == msg.propose_status.id then
                self.netData[i] = msg.propose_status
            end
        end
    end

    local data = msg.propose_status
    if data.id == 4 then
        self.eUpTopBtn()
    elseif data.id == 1 or data.id == 2 or data.id == 3 then
        self.eUpCellBtn(data.id)
    end
end

--通过id来获取协议中此按钮的所在的档位的数据(id : 1 代表第一档结婚)
function My:UpBtnType(id)
    local dataList = self.netData
    local len = #dataList
    local btnType = nil
    if dataList.id then
        if dataList.id == id then
            btnType = dataList
            return btnType
        end
    end
    for i = 1, len do
        if dataList[i].id == id then
            btnType = dataList[i]
        end
    end
    return btnType
end

--获取得到称号战力
function My:GetFightVal()
    -- 战力
    local fightVal = self.fightVal
    local fight = math.floor(fightVal)
    if not fight then fight = 0 end
    return fight
end

--请求领取
function My:ResqGet(id)
    local msg = ProtoPool.GetByID(25021)
    msg.id = id
    ProtoMgr.Send(msg)
end


function My:Reset()
    self.fightVal = nil
    self.configNum = 0
    self.netData = nil
end

function My:Clear()
    self:Reset()
end

return My