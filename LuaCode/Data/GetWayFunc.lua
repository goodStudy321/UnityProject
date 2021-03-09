--[[
获取途径
]]

GetWayFunc={Name="GetWayFunc"}
local My = GetWayFunc
local wayPos = nil
local wayTitle = nil
local wayList = {}
My.eClick=Event() --事件添加为了跳转回去用的
local jumpName = nil
local jumpBType = nil
local jumpSType = nil
local jumpPropId = nil

function My.Init()
    QuickUseMgr.eJump:Add(My.OnJump)
end

--记录当前页（跳转回来用）
function My.SetJump(uiName,bType,sType,propId)
    jumpName = uiName
    jumpBType = bType
    jumpSType = sType
    jumpPropId = propId
    -- JumpMgr:InitJump(uiName,bType,sType)
end

--KV结构 k:获取途径表id  v:要跳转界面选中的id(eg:道具id)
function My.GetWay(kv,pos)
    ListTool.ClearToPool(wayList)
    wayPos=pos
    table.insert( wayList, kv )
    UIMgr.Open(UIGetWay.Name,My.GetWayCb)
end

function My.GetWayKVList(kvList,pos)
    ListTool.ClearToPool(wayList)
    wayPos=pos
    for i,v in ipairs(kvList) do
        local kv = ObjPool.Get(KV)
        kv:Init(v.k,v.v)
        table.insert( wayList, kv )
    end
    UIMgr.Open(UIGetWay.Name,My.GetWayCb)
end

function My.OpenGetWay(type_id, pos)
    local item = UIMisc.FindCreate(type_id)
    local getway = item.getwayList
    if not getway then return end
    My.GetWayIdList(getway,pos,type_id)
end

function My.GetWayIdList(idList,pos,type_id)
    ListTool.ClearToPool(wayList)
    wayPos=pos
    for i,v in ipairs(idList) do
        local kv = ObjPool.Get(KV)
        kv:Init(v,type_id)
        table.insert( wayList, kv )
    end
    UIMgr.Open(UIGetWay.Name,My.GetWayCb)
end

--渡劫任务跳转
function My.RoMGetWay(jumpTab,pos,title)
    ListTool.ClearToPool(wayList)
    JumpMgr:Clear()
    wayPos = pos
    wayTitle = title
    JumpMgr:InitJump(UIRobbery.Name,1)
    for i = 1,#jumpTab do
        local kv = ObjPool.Get(KV)
        kv:Init(jumpTab[i],0)
        table.insert(wayList,kv)
    end
    UIMgr.Open(UIGetWay.Name,My.GetWayCb)
end

--养成相关跳转
--uiName:当前界面
--flag:当前页签
--propId:道具id
--isSkinPage:是否是养成皮肤二级界面
--transSelectId:伙伴，坐骑 皮肤选中id
function My.AdvGetWay(uiName,flag,propId,isSkinPage,transSelectId)
    if uiName == nil or flag == nil or propId == nil then
        return
    end
    local skinIndex = 0
    if isSkinPage == nil or isSkinPage == false then
        skinIndex = 0
    elseif isSkinPage == true then
        skinIndex = 2
    end
    local proId = tostring(propId)
    local cfg = ItemData[proId]
    local jumpTab = cfg.getwayList
    if jumpTab == nil then
        return
    end
    -- JumpMgr:Clear()
    local pos = Vector3.New()
    pos = pos(104,-160,0)
    if uiName == "UIAdv" then
        --2:打开皮肤界面(无红点)  0：不打开皮肤界面
        My.SetJump(uiName,flag,skinIndex,propId)
        -- JumpMgr:InitJump(uiName,flag,skinIndex,propId)
    elseif uiName == "UITransApp" then
        My.SetJump(uiName,flag,skinIndex,transSelectId)
        -- JumpMgr:InitJump(uiName,flag,skinIndex,transSelectId)
    elseif uiName == "UIThroneApp" then
        My.SetJump(uiName)
        -- JumpMgr:InitJump(uiName)
    end
    ListTool.ClearToPool(wayList)
    wayPos = pos
    wayTitle = title
    for i = 1,#jumpTab do
        local kv = ObjPool.Get(KV)
        kv:Init(jumpTab[i],propId)
        table.insert(wayList,kv)
    end
    UIMgr.Open(UIGetWay.Name,My.GetWayCb)
end

--通过道具获取途径（记得调用  SetJump）
function My.ItemGetWay(type_id,pos)
    local item = UIMisc.FindCreate(type_id)
    local getway = item.getwayList
    if not getway then return end
    local  name=nil
    if not pos then pos= Vector3.zero end
    if item.uFx==1 then 
        local ui = UIMgr.Get(EquipTip.Name )
        if ui then pos=ui.grid.transform.localPosition+Vector3.New(273,-155.4,0) end
    elseif item.uFx==28 then
        local ui = UIMgr.Get(GuardTip.Name )
        if ui then pos=ui.root.localPosition+Vector3.New(344,-153,0) end
    elseif item.uFx==55 then
        name=KnotTip.Name 
    elseif item.id == 117 then --渡劫丹 
        pos = Vector3.New(30,-50,0)
    else
        local ui = UIMgr.Get(PropTip.Name )
        if ui then 
            local uuii=ui.list[#ui.list]
            pos=uuii.bg.transform.localPosition+Vector3.New(42,-154,0) 
        end
    end
    My.GetWayIdList(getway,pos,type_id)
end


function My.GetWayCb(name)
    local ui = UIMgr.Get(name)
	if ui then 
        if wayPos then ui:SetPos(wayPos) end
        if wayTitle then 
            ui:SetTitle(wayTitle) 
            wayTitle = nil
        end
        for i,kv in ipairs(wayList) do
            local id = tostring(kv.k) --跳转表的id
            local jId = kv.v --要跳转界面选中的id(eg:道具id)
            local way = GetWayData[id]
            if not way then iTrace.eError("xiaoyu","获取途径表为空 id: "..tostring(id))
            else
                local uiName = way.uiName
                local b = way.b
                local s = way.s
                ui:CreateCell(way.des,function() My.JumCb(uiName,b,s,jId) end)
            end          
        end
	end
end

function My.JumCb(mname,mb,ms,mid)
    if StrTool.IsNullOrEmpty(mname) then UITip.Log("活动未开启")return end
    -- local isEvent = false
    -- if jumpName then
    --     if jumpName == "UIAdv" or jumpName == "UITransApp" or jumpName == "UIThroneApp" then
    --         isEvent = true
    --     end
    -- end
    local isjump=QuickUseMgr.Jump(mname,mb,ms,mid,true)
end

function My.OnJump()
    if StrTool.IsNullOrEmpty(jumpName)then return end
    JumpMgr:ClearJumpDic()
    JumpMgr:InitJump(jumpName,jumpBType,jumpSType,jumpPropId)
end

function My.Clear( ... )
    -- body
end

return My