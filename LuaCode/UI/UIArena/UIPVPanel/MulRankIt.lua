MulRankIt = Super:New{Name = "MulRankIt"}
local My = MulRankIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.itemBg = CG(UISprite,trans,"itemBg",name)
    self.rankLab = CG(UILabel,trans,"rankLab",name)
    self.rankSp = CG(UISprite,trans,"rankLab/rankIcon",name)
    self.rankBg = CG(UISprite,trans,"rankLab/rankBg",name)
    self.nameLab = CG(UILabel,trans,"nameLab",name)
    self.occLab = CG(UILabel,trans,"occLab",name)
    self.warLab = CG(UILabel,trans,"warLab",name)
    self.scoreLab = CG(UILabel,trans,"scoreLab",name)
    self.serverLab = CG(UILabel,trans,"serLab",name)
    US(self.itemBg.gameObject,self.ClickRank,self,"MulRankIt",false)
end

function My:ClickRank(obj)
    local roleId = tonumber(obj.transform.parent.name)
    -- iTrace.eError("GS","MulRankIt  roleId===",roleId)
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data,index)
    local rank = data.rank
    local roleId = data.role_id
    local roleName = data.role_name
    local roleOcc = data.category
    local roleWar = data.power
    local roleScore = data.score
    local roleServer = data.server_name
    roleWar = math.NumToStrCtr(roleWar)
    roleOcc = UIMisc.GetWork(roleOcc)
    self.Gbj.gameObject.name = roleId
    self.rankLab.text = rank
    self.nameLab.text = roleName
    self.occLab.text = roleOcc
    self.warLab.text = roleWar
    self.scoreLab.text = roleScore
    self.serverLab.text = roleServer
    if index <= 3 then
        self.rankSp.enabled = true
        self.rankBg.enabled = true
        self:SetRankSp(index)
    end
    if index % 2 == 1  and index > 3 then
        self.itemBg.color = Color.New(1,1,1,0.1)
    end
    if index > 3 then
        self.rankSp.enabled = false
        self.rankBg.enabled = false
    end
end

function My:SetRankSp(index)
    local tab = {"rank_icon_1","rank_icon_2","rank_icon_3"}
    local bgTab = {"rank_info_g","rank_info_z","rank_info_b"}
    self.rankSp.spriteName = tab[index]
    self.rankBg.spriteName = bgTab[index]
end

function My:Dispose()
    TableTool.ClearUserData(self)
end