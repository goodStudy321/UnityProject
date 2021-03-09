--[[
 	authors 	:Liu
 	date    	:2019-3-20 12:00:00
 	descrition 	:限时活动界面1(排行弹窗项)
--]]

UIRankInfoPopIt = Super:New{Name="UIRankInfoPopIt"}

local My = UIRankInfoPopIt

function My:Init(root)
    local des = self.name
    local CG = ComTool.Get

    self.go = root.gameObject

    self.rankLab = CG(UILabel, root, "rankLab")
    self.valLab = CG(UILabel, root, "valLab")
    self.nameLab = CG(UILabel, root, "rankName")
    self.tex = CG(UITexture, root, "icon")
end

--设置排行榜项文本
function My:SetRankLab(rank, val, name)
    self.rankLab.text = string.format("第%s名", rank)
    self.valLab.text = string.format("战力：%s", val)
    self.nameLab.text = name
    self:SetRankSpr(rank)
end

--设置排行图片
function My:SetRankSpr(rank)
    self.texName = ""
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
    if self.tex then
        self.tex.mainTexture = tex
    end
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--清理缓存
function My:Clear()
    AssetMgr:Unload(self.texName,false)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My