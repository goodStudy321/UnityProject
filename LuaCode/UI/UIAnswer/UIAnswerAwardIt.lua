--[[
 	authors 	:Liu
 	date    	:2018-5-1 14:59:40
 	descrition 	:答题奖励项
--]]

UIAnswerAwardIt = Super:New{Name = "UIAnswerAwardIt"}

local My = UIAnswerAwardIt

function My:Init(root, cfg)
    local CG, des = ComTool.Get, self.Name
    local rankLab = CG(UILabel, root, "rankLab")
    local awardTab = TransTool.Find(root, "awardTab", des)
    self.tex = CG(UITexture, root, "icon")
    self.cellList = {}
    self:InitRank(cfg, rankLab)
    self:InitTab(cfg, awardTab)
end

--初始化排行信息
function My:InitRank(cfg, rankLab)
    local temp1, temp2 = cfg.rank[1], cfg.rank[2]
    local temp3 = (temp1==temp2) and temp1 or nil
    local rank = (temp3~=nil) and temp3 or temp1.."-"..temp2
    rankLab.text = "第"..rank.."名"
    self.texName = ""
    if temp3 == 1 then
        self.texName = "duanwei3.png"
    elseif temp3 == 2 then
        self.texName = "duanwei4.png"
    elseif temp3 == 3 then
        self.texName = "duanwei5.png"
    else
        self.texName = "duanwei1.png"
    end
    if StrTool.IsNullOrEmpty(self.texName) then return end
    AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    self.tex.mainTexture = tex
end

--初始化奖励
function My:InitTab(cfg, awardTab)
    local key = tostring(User.MapData.Level)
    local expCfg = LvCfg[key]
    if expCfg == nil then return end
    local exp = expCfg.exp * (cfg.expRate * 0.0001)
    local dic = {k = 100, v = exp}
    local list = {}
    table.insert(list, dic)
    for i,v in pairs(cfg.award) do
        table.insert(list, v)
    end
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(awardTab, 0.7)
        cell:UpData(v.k, v.v)
        cell.Lab.text = "[00FF00FF]"..cell.Lab.text
        table.insert(self.cellList, cell)
    end
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName,false)
end

--释放资源
function My:Dispose()
    self:Clear()
    TableTool.ClearListToPool(self.cellList)
end

return My