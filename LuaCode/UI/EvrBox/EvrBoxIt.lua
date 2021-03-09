EvrBoxIt = Super:New{Name = "EvrBoxIt"}
local My = EvrBoxIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.flagSp = CG(UISprite,trans,"flagSp",name)
    self.iconTex = CG(UITexture,trans,"tbg/tex",name)
    self.reTimesLab = CG(UILabel,trans,"lab",name)
    self.reDesLab = CG(UILabel,trans,"lab/lab1",name)
    self.btnSp = CG(UISprite,trans,"btn",name)
    self.btnLab = CG(UILabel,trans,"btn/lab",name)
    self.btnRed = TFC(trans,"btn/Action",name)
    self.btnRed:SetActive(false)
    self.reGrid = CG(UIGrid,trans,"grid",name)
    self.rewardTab = {}
    self.clickIndex = 0
    US(self.btnSp.gameObject,self.ClickBtn,self,name)
end

function My:ClickBtn()
    local index = self.clickIndex
    if index == nil or index == 0 then iTrace.eError("GS","点击为0") return end
    local dTab = EvrBoxMgr.dbTab.list
    local val = dTab[index].val
    if val == 1 then
        VIPMgr.OpenVIP(1)
    elseif val == 2 then
        EvrBoxMgr:ReqReward(index)
    elseif val == 3 then
        UITip.Error("该宝箱已领取")
    end
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
    --1)升级宝箱   2)日常宝箱   3)战力宝箱   4)金币宝箱
    local flagSpTab = {"meiri_text_shengji","meiri_text_richang","meiri_text_zhanli","meiri_text_jinbi"}
    local flag = data.type
    local spName = flagSpTab[flag]
    local iconPath = data.icon
    local reward = data.rewTab
    local times = data.times
    self.clickIndex = times
    local cRewTimes = EvrBoxMgr:GetCurRewTimes(times)
    local des1= ""
    des1 = string.format("充值%s次可领取",times)
    self:LoadTex(iconPath)
    self:RefreshReward(reward)
    self:RefreshDif(cRewTimes,times)
    self.flagSp.spriteName = spName
    self.reDesLab.text = des1
end

--cRewTimes:当前可领取次数
function My:RefreshDif(cRewTimes,desTimes)
    local des1 = ""
    des1 = string.format("(%s/%s)",cRewTimes,desTimes)
    self.reTimesLab.text = des1
    self:RefreshBtn(desTimes)
end

function My:RefreshBtn(desTimes)
    local spTab = {"btn_figure_non_avtivity2","btn_figure_non_avtivity","btn_figure_down_avtivity"}
    local dTab = EvrBoxMgr.dbTab
    local list = dTab.list
    local btnLabTab = {"前往充值","领取","已领取"}
    local val = list[desTimes].val
    local spName = spTab[val]
    local lab = btnLabTab[val]
    self.btnSp.spriteName = spName
    self.btnLab.text = lab
    self.btnRed:SetActive(val == 2)
end

function My:LoadTex(path)
    AssetMgr:Load(path,ObjHandler(self.SetIcon,self))
end

function My:SetIcon(tex)
    self.iconTex.mainTexture = tex
    self.texName = tex.name
end

function My:ClearIcon()
    if self.texName then
        AssetMgr:Unload(self.texName,false)
        self.texName = nil
    end
end


--I:道具id  B:数量   N:是否绑定
function My:RefreshReward(reward)
    local data = reward
    local len = #data
    local itemTab = self.rewardTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            local pId = data[i].id --道具ID
            local pNum = data[i].minLv --数量
            local pIsB = data[i].maxLv --是否绑定（1是0否）
            local pIsE = data[i].weight --特效(1有0没有）
            itemTab[i]:UpData(pId,pNum)
            itemTab[i]:UpBind(pIsB)
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
        else
            local pId = data[i].id --道具ID
            local pNum = data[i].minLv --数量
            local pIsB = data[i].maxLv --是否绑定（1是0否）
            local pIsE = data[i].weight --特效(1有0没有）
            local item = ObjPool.Get(UIItemCell)
            item:InitLoadPool(self.reGrid.transform)
            item:UpData(pId,pNum)
            item:UpBind(pIsB)
            table.insert(self.rewardTab,item)
        end
    end
    self.reGrid:Reposition()
end

function My:Dispose()
    self.clickIndex = 0
    self:ClearIcon()
    TableTool.ClearListToPool(self.rewardTab)
    TableTool.ClearUserData(self)
end