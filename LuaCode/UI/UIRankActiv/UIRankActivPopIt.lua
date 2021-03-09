--[[
 	authors 	:Liu
 	date    	:2018-5-2 10:27:40
 	descrition 	:排行榜项
--]]

UIRankActivPopIt = Super:New{Name = "UIRankActivPopIt"}

local My = UIRankActivPopIt

function My:Init(root)
    local CG = ComTool.Get

    self.rankLab = CG(UILabel, root, "rankLab")  --第几名
    self.valLab = CG(UILabel, root, "valLab")    --等级多少名 啥的 
    self.nameLab = CG(UILabel, root, "rankName") --玩家姓名
    self.tex = CG(UITexture, root, "icon")       --左边图标
    self.go = root.gameObject                   --rankItem
end

--设置排行榜项文本
function My:SetRankLab(rank, val, name, index)
    local str1, str2 = self:GetIndexText(index, val)
    local valStr = (StrTool.IsNullOrEmpty(str2)) and val or str2
    self.rankLab.text = string.format("第%s名", rank)
    self.valLab.text = string.format("%s：%s", str1, valStr)
    self.nameLab.text = name
    self:SetRankSpr(rank)
end

--初始化排行信息
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

--根据索引获取文本
function My:GetIndexText(index, val)
    local str = ""
    local valStr = ""
    if index == 1 then
        str = "等级"
    elseif index == 2 then
        str = "坐骑"
         valStr = RankActivMgr:GetMountsInfo(val)         
    elseif index == 3 then
        str = "套装战力"
         valStr = RankActivMgr:GetPetInfo(val)
    elseif index == 4 then
        str = "伙伴"
        valStr = RankActivMgr:GetPetInfo(val)             
    elseif index == 5 then
        str = "天机"
    elseif index == 6 then
        str = "战力"
    elseif index == 7 then
        str = "通关"
        valStr = RankActivMgr:GetFiveInfo(val)
    end
    return str, valStr
end

--获取坐骑信息
function My:GetMountsInfo(id)
	local cfg, index = BinTool.Find(MountStepCfg, id)
	if cfg == nil then return end
	return cfg.type.."阶"..cfg.st.."星"
end

--获取宠物信息
function My:GetPetInfo(id)
	local lv = math.floor((id-3030000) / 100)
	local cfg2, index2 = BinTool.Find(PetStepTemp, id)
	if cfg2 == nil then return end
	return lv.."阶"..cfg2.step.."星"
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