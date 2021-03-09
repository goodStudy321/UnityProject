--[[
同心结管理类（为了做红点功能）
--]]
KnotMgr={Name="KnotMgr"}
local My = KnotMgr
My.eKnot=Event()
My.isRed=false
My.KnotNum=0
My.eRed=Event()
My.KnotId=31038

function My.Init()
    My.AddLnsr()
end

--添加事件
function My.AddLnsr()
    local Add = ProtoLsnr.Add
    Add(23636, My.RespKnot)

    PropMgr.eAdd:Add(My.OnAdd)
    PropMgr.eUpNum:Add(My.OnUp)
    PropMgr.eRemove:Add(My.onRemove)
end

--同心结
function My.RespKnot(msg)
    local id=msg.knot_id
    local exp=msg.knot_exp
    MarryInfo.data.knotid=id
    MarryInfo.data.knotExp=exp
    My.eKnot()
end

function My.OnAdd(tb,action,tp)
    if tb.type_id~=My.KnotId or tp~=1 then return end
    My.UpRed()
end

function My.OnUp(tb,tp)
    if tb.type_id~=My.KnotId or tp~=1 then return end
    My.UpRed()
end

function My.onRemove(id,tp,type_id)
    if type_id~=My.KnotId or tp~=1 then return end
    My.UpRed()
end

function My.UpRed()
    local isred = false
    local num=PropMgr.TypeIdByNum(My.KnotId)
    local max=KnotData[#KnotData]
    if num>0 and MarryInfo.data.knotid~=max.id then isred=true end
    if isred~=My.isRed then 
        MarryMgr:SetActionDic("3",isred)
    end
    My.isRed=isred
    My.KnotNum=num
    My.eRed(isred,num)
end

function My.Clear()
    My.isRed=false
    MarryInfo.data.knotid=0
    MarryInfo.data.knotExp=0
end

return My