--[[
 	authors 	:Liu
 	date    	:2018-11-29 11:00:00
 	descrition 	:青云之巅排行奖励项
--]]

UITopFightAwardIt = Super:New{Name = "UITopFightAwardIt"}

local My = UITopFightAwardIt

function My:Init(root, cfg)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find

    local rankLab = CG(UILabel, root, "rankLab")
    local awardTab = Find(root, "awardTab", des)
    self.tex = CG(UITexture, root, "icon")
    self.cellList = {}
    self:InitRank(cfg, rankLab)
    self:InitTab(cfg, awardTab)
end

--初始化排行信息
function My:InitRank(cfg, rankLab)
    local rank = cfg.id
    self.texName = ""
    rankLab.text = "第"..rank.."名"
    if rank == 1 then
        self.texName = "duanwei3.png"
    elseif rank == 2 then
        self.texName = "duanwei4.png"
    elseif rank == 3 then
        self.texName = "duanwei5.png"
    elseif rank == 4 then
        self.texName = "duanwei2.png"
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
    for i,v in ipairs(cfg.award) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(awardTab, 0.7)
        cell:UpData(v.k, v.v)
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