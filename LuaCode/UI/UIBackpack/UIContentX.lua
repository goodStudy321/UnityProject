--[[
背包循环利用的格子横向
]]
local AssetMgr=Loong.Game.AssetMgr
UIContentX=Super:New{Name="UIContentX"}
local My = UIContentX

function My:Ctor()
    self.dic={}
end

function My:Init(go)
    local CG = ComTool.Get
    local trans = go.transform
    self.go=go

   self.grid=trans:GetComponent(typeof(UIGrid))
end

function My:Create(num,tp,isBag)
    for i=1,num do
        local cell=ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform)
        cell.trans.name=tostring(i)
        cell.tp=tp
        cell.isBag=isBag
        self.dic[tostring(i-1)]=cell
    end
end

function My:UpData()
    -- body
end

function My:Dispose()
    for k,cell in pairs(self.dic) do
        cell:DestroyGo()
        cell.tp=nil
        cell.isBag=nil
        cell.islock=nil
        ObjPool.Add(cell)
        self.dic[k]=nil
    end
    local name = self.go.name..".prefab"
    Destroy(self.go)
    AssetMgr.Instance:Unload(name,false)
end

---/// LY add begin

function My:Update()
    if self.dic ~= nil then
        for k,cell in pairs(self.dic) do
            cell:FrameUpdate();
        end
    end
end

---/// LY add end