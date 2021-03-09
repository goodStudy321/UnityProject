--[[
货币条目
]]
AssetItem=Super:New{Name="AssetItem"}
local My = AssetItem
My.eClick=Event()

function My:Init(go)
    self.go=go
    local CG= ComTool.Get
    local U = UITool.SetBtnClick
    local trans = go.transform
    self.fg=CG(UITexture,trans,"fg",self.Name,false)
    self.lbl=CG(UILabel,trans,"lbl",self.Name,false)

    U(trans,"AddBtn",self.Name,self.AddBtn,self)
end

function My:UpData(type_id)
    local id = tostring(type_id)
    local item = ItemData[id]
    local icon = item.icon
    local jump = item.getwayList
    self.id=id

    AssetMgr:Load(icon,ObjHandler(self.LoadIcon,self))
    self:ShowLab(type_id)
end

function My:ShowLab(type_id)
    local text = RoleAssets.IdGetCostAsset(type_id)
    self.lbl.text=UIMisc.ToString(text,false)
end

function My:LoadIcon(obj)
    self.fg.mainTexture=obj
end

function My:AddBtn()
    local item = UIMisc.FindCreate(self.id)
    local getway = item.getwayList
    if not getway then return end
    local id = getway[1]
    local temp = GetWayData[tostring(id)]
    My.eClick(temp)
end

function My:Dispose()
    Destroy(self.go)
end