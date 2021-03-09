--[[
道具获得
]]
GetPropMgr={Name="GetPropMgr"}
local My=GetPropMgr
local str = ObjPool.Get(StrBuffer)

function My.Init()
    PropMgr.eGetAdd:Add(My.OnGetAdd)
end

function My.OnGetAdd(action,getList)
    if action==10101 then return end --替换
    if action==0 then return end --整理、存放、提取、限时
    for i,kv in ipairs(getList) do
        My.ShowProp(kv.k,kv.v)
    end
end

function My.ShowProp(type_id,num)
    local tbb=ObjPool.Get(ChatTb)
    str:Dispose()
    local item = UIMisc.FindCreate(type_id)
    local qua = item.quality
    local numStr = UIMisc.ToString(tostring(num),false)
    str:Apd("获得了[url=道具_"):Apd(type_id):Apd("]"):Apd(UIMisc.LabColor(qua)):Apd("["):Apd(item.name):Apd("][-]*"):Apd(numStr)
    local msg=str:ToStr()
    local ismain = ChatMgr.quaDic[tostring(qua)]
    ChatMgr.SetSys(msg,1,ismain)
end

function My.Clear()
    -- body
end

return My