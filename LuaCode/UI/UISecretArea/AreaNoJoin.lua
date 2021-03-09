--[[
未加入区域
]]
AreaNoJoin=Super:New{Name="AreaNoJoin"}
local My = AreaNoJoin

function My:Init(go)
    if not self.propDic then self.propDic={} end
    if not self.cellList then self.cellList={} end
    if not self.propIdList then self.propIdList={} end
    self.go=go
    local trans = go.transform
    local UB = UITool.SetBtnClick
    local CG = ComTool.Get
    local TF = TransTool.FindChild

    self.EnterBtn=TF(trans,"EnterBtn")
    UB(trans,"EnterBtn",self.Name,self.OnEnterBtn,self,false)
    self.grid=CG(UIGrid,trans,"rightReward/Grid",self.Name,false)
    self.tipLab=CG(UILabel,trans,"tipLab",self.Name,false)

    self:SetEvent("Add")
    self:UpData()
end

function My:SetEvent(fn)
    SecretAreaMgr.eTime[fn](SecretAreaMgr.eTime,self.OnTime,self)
end

function My:OnTime(remain)
    self:TipLab(false,remain)
end

function My:UpData()
    for k,v in pairs(SecretData) do
        local propList= v.propList
        local id = tostring(propList[1])
        local num = propList[2]
        local prop = self.propDic[id]
        if not prop then 
            prop=0
            local kv = ObjPool.Get(KV)
            kv:Init(id,k)
            table.insert( self.propIdList, kv )
        end
        self.propDic[id]=prop+num
    end

    if #self.propIdList>1 then table.sort(self.propIdList, self.SortPropId ) end
    for i,v in ipairs(self.propIdList) do
        local id = v.k
        local num = self.propDic[id]
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform,0.8)
        cell:UpData(id,num)
        table.insert( self.cellList, cell )
    end

    local isOpen = SecretAreaMgr.isOpen
    if isOpen==true then
        self:TipLab(true)
    else
        self:TipLab(false,SecretAreaMgr.timer.remain)
    end
end

function My.SortPropId(a,b)
    return a.v<b.v
end

--是否开启
function My:TipLab(state,time)
    local text = "距离秘境探索正在进行\n报名秘境后，将出生在秘境版图内随机位置"
    if state==false then
        UITool.SetGray(self.EnterBtn,false)
        text="距离秘境探索开启还有："..time.."\n报名秘境后，秘境开启时会自动采集出生点资源"
    else
        UITool.SetNormal(self.EnterBtn)
    end
    self.tipLab.text=text
end

function My:OnEnterBtn()
    -- body
end

function My:Open()
    self.go:SetActive(true)
end

function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    self:SetEvent("Remove")
    TableTool.ClearDic(self.propDic)
    for i,v in ipairs(self.cellList) do
        v:DestroyGo()
    end
    ListTool.ClearToPool(self.cellList)
    ListTool.ClearToPool(self.propIdList)
end