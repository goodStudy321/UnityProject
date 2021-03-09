--[[
秘境区域格子
]]
AreaCell=Super:New{Name="AreaCell"}
local My=AreaCell


function My:Init(go)
    if LuaTool.IsNull(go) then return end
    self.Root=go

    local TF = TransTool.FindChild
    local CG = ComTool.Get
    local trans=go.transform
    self.qua=trans:GetComponent(typeof(UISprite))
    self.select=TF(trans,"select")
    self.icon=CG(UISprite,trans,"icon",self.Name,false)
    self.iconBg=CG(UISprite,trans,"icon/iconBg",self.Name,false)
    self.prop=CG(UITexture,trans,"prop",self.Name,false)
    self.cao=CG(UITexture,trans,"cao",self.Name,false)
    self.hasMisty=TF(trans,"hasMisty")
end

--更新数据
function My:UpData(key)
    self.Key = key
    local mgr = SecretAreaMgr
    local cInfo = mgr.LatticeDic[key]
    local nrInfo = mgr.NightRoundDic[key]
    self:ShowIcon(nrInfo)
    self:HasMoved(cInfo, nrInfo)
    self:ShowProp(cInfo)
    self:ShowCao(cInfo)
    if key~=AreaJoin.SelectKey then self:Select(false)end
    --self:CanMove(nrInfo)
end

--头像
function My:ShowIcon(info)

    --有玩家显示头像信息
    local activie = false
    local path,iconBg = "",""
    if info and info.role then  
        local role = info.role
        path = string.format("TX_0%s",role.cate)
        activie = true
        iconBg=info.role.role_id==User.MapData.UIDStr and "mijing_touxiang_wofang" or "mijing_touxiang_difang"
    end
    self.icon.gameObject:SetActive(activie)
    self.icon.spriteName = path
    self.iconBg.spriteName=iconBg
end

-- --九宫格是否可移动
-- function My:CanMove(info)
--     local active = false
--     if info ~= nil then
--         active = SecretAreaMgr.IsMoveArea(info.x,info.y)
--     end
--     if SecretAreaMgr.MoveNum==0 then active=false end
--     self.isNight = active
-- end

--玩家探索过且不在可视范围的单元格，只能看到是什么资源
function My:HasMoved(info, nInfo)
    local active = true
    if info ~= nil and nInfo ~= nil then
        active = false
    end
    self.hasMisty.gameObject:SetActive(active)
end

--资源
function My:ShowProp(info)
    if info and info.num>0 then 
        local data = SecretData[tostring(info.type_id)]
        if data then
            local path = data.icon
            AssetMgr:Load(path,ObjHandler(self.LoadProp,self))
            return
        end
    end
    self:LoadProp(nil)
end

function My:ShowCao(info)
    local path="mijing_cao_01.png"
    if info then 
        local data = SecretData[tostring(info.type_id)]
        if data then
            path= data.cao
        end
    end
    AssetMgr:Load(path,ObjHandler(self.LoadCao,self))
end


function My:Select(active)
    self.select:SetActive(active)
end

function My:LoadProp(obj)
    self.prop.mainTexture=obj
    self.prop.gameObject:SetActive(false)
    self.prop.gameObject:SetActive(true)
end

function My:LoadCao(obj)
    self.cao.mainTexture=obj
end

--玩家未探索过的单元格
function My:NoMoved()
    self:ShowIcon()
    --self:CanMove()
    self:HasMoved()
    self:Select(false)
    self:ShowProp()
end

function My:Dispose()
    self.isNight=nil
    if LuaTool.IsNull(self.Root)~=true then
        Destroy(self.Root)
        -- GbjPool:Add(self.Root)
        -- AssetMgr:Unload(self.Name..".prefab",false)
    end
end