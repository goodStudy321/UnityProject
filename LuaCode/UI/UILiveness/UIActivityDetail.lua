--[[
 	authors 	:Liu
 	date    	:2018-4-19 09:29:25
 	descrition 	:活动项详情
--]]

UIActivityDetail = Super:New{Name = "UIActivityDetail"}

local My = UIActivityDetail

function My:Init(root)
    local CG = ComTool.Get
    local des = self.Name
    local str, str2 = "ActivityDetails/", "/Grid/"
    local str1 = "ActivityDetails/AwardLabel/Scroll View"
    self.cellList = {}
    self.root = root
    self.DesName = CG(UILabel, root, "ActivityNameBg/Label")
    self.Lv = CG(UILabel, root, str.."LV/Label")
    self.Date = CG(UILabel, root, str.."Time/Label")
    self.oTime = CG(UILabel, root, str.."oTime/Label")
    self.Des = CG(UILabel, root, str.."Des")
    self.Grid = CG(UIGrid, root, str1..str2)
    self.panel = CG(UIPanel, root, str1)
    self.GridTran = TransTool.Find(root, str1..str2, des)
    self.AwardItem = TransTool.FindChild(root, str1..str2.."AwardItem", des)
    self.AwardItem:SetActive(false)
    UITool.SetLsnrClick(root, "lock",tip, self.setFalse, self)
end
--关闭界面
function My:setFalse()
    self.root.gameObject:SetActive(false)
end
--更新显示 
function My:UpShow(cfg, count)
    local val = (count==nil) and 0 or count
    self:UpLabel(cfg, val)
    self:UpItem(cfg)
end

--更新文本
function My:UpLabel(cfg, count)
    if cfg == nil then return end
    self:SetLabState(cfg)
    self.DesName.text = cfg.name
    self.Lv.text = cfg.lv
	local key = tostring(cfg.activId)
    local info = ActiveInfo[key]
    local str = (info == nil) and cfg.time or info.begDay
    local timeStr = self:GetActTimeLab(cfg)
    self.Date.text = SignInfo:GetActivTime(str)
    self.oTime.text = timeStr
    self.Des.text = "[99886BFF]活动描述：[F4DDBDFF]"..cfg.des
end

--获取活动时间文本
function My:GetActTimeLab(cfg)
    local timeStr = ""
    local oTime, lTime = self:GetActTime(cfg)
    if oTime == nil then return end
    timeStr = CustomInfo:GetTimeLab(oTime, lTime)
    if cfg.id == 19 then
        local oTime1, lTime1 = self:GetActTime(cfg, 2)
        local tempStr = CustomInfo:GetTimeLab(oTime1, lTime1)
        timeStr = timeStr.."\n"..tempStr
    end
    return timeStr
end

--获取活动时间
function My:GetActTime(cfg, index)
    local key = tostring(cfg.activId)
    local info = ActiveInfo[key]
    if info == nil and cfg.id ~= 19 then
        return nil, nil
    end
    local oList = {}
    local oTime = (info == nil) and cfg.openTime or info.begTime
    local lTime = (info == nil) and cfg.existTime or info.lastTime
    if index then
        table.insert(oList, oTime[index])
    else
        table.insert(oList, oTime[1])
    end
    return oList, lTime
end

--设置文本状态
function My:SetLabState(cfg)
    if cfg.type == 1 then
        self:SetLabPos(false, false)
    else
        if cfg.id == 19 then
            self:SetLabPos(true, true)
        else
            self:SetLabPos(true, false)
        end
    end
end

--设置文本位置
function My:SetLabPos(state, isTwo)
    local go = self.oTime.transform.parent.gameObject
    local tran = self.Des.transform
    go:SetActive(state)
    if go.activeSelf and isTwo then
        tran.localPosition = Vector3.New(tran.localPosition.x, 50, 0)
    elseif go.activeSelf then
        tran.localPosition = Vector3.New(tran.localPosition.x, 66, 0)
    else
        tran.localPosition = Vector3.New(tran.localPosition.x, 89, 0)
    end
end

--更新奖励物品
function My:UpItem(cfg)
    if cfg == nil then return end
    local cellList = self.cellList
    local Add = TransTool.AddChild
    local count = #cfg.awardItems
    local awardIts = cfg.awardItems
    if #cellList < count then
        local num = count - #cellList
        for i=1, num do
            local item = Instantiate(self.AwardItem)
            item:SetActive(true)
            local tran = item.transform
            Add(self.GridTran, tran)
            local cell=ObjPool.Get(UIItemCell)
            cellList[#cellList+1] = cell
            cell:InitLoadPool(tran, 0.77)
        end
        for i,v in ipairs(cellList) do
            local id = tostring(awardIts[i])
            v:UpData(id)
            local go = v.trans.gameObject
            go:SetActive(true)
        end
    else 
        for i,v in ipairs(cellList) do
            local go = v.trans.parent.gameObject
            if i > count then
                go:SetActive(false)
            else
                go:SetActive(true)
                local id = tostring(awardIts[i])
                v:UpData(id)
            end
        end
    end
    self.Grid:Reposition()
    self:ResetPanel()
end

--重置Scroll View偏移
function My:ResetPanel()
    local panel = self.panel
    local y = panel.transform.localPosition.y
    panel.transform.localPosition = Vector3.New(0, y, 0)
    panel.clipOffset = Vector2.zero
end

--设置界面状态
function My:SetMenuState(state)
    self.root.gameObject:SetActive(state)
end

--清理缓存
function My:Clear()
    
end

-- 释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My