FashionMsg = {Name="FashionMsg"}
local My = FashionMsg;
--当前穿戴时装Id列表
My.CurIdList = {}
--拥有的时装Id列表
My.OwnerIdList = {}
My.eChgFashion = Event();

function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    ProtoLsnr.AddByName("m_fashion_change_toc",self.FashionChg,self)
    ProtoLsnr.AddByName("m_fashion_info_toc",self.FashionUpdate,self)
end

--请求改变时装 type：1 穿戴 2 脱下
function My.ReqFashionChg(type,curId)
    local msg = ProtoPool.Get("m_fashion_change_tos")
    msg.type = type;
    msg.cur_id = curId;
    ProtoMgr.Send(msg);
end

--时装更换
function My:FashionChg(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
        return;
    end
    self:SetCurIdList(msg.cur_id_list);
    My.eChgFashion();
end

--时装信息更新
function My:FashionUpdate(msg)
    My.PutonUpdate(msg.fashion_list,msg.op_type);
    self:SetCurIdList(msg.cur_id_list);
    self:SetOwnerIdList(msg.fashion_list);
end

--设置当前穿戴Id列表
function My:SetCurIdList(lst)
    if lst == nil then
        return;
    end
    My.CurIdList = {}
    local len = #lst;
    if len == 0 then
        return;
    end
    for i = 1,len do
        My.CurIdList[i] = lst[i];
    end
end

--设置拥有的时装Id列表
function My:SetOwnerIdList(lst)
    if lst == nil then
        return;
    end
    My.OwnerIdList = {}
    local len = #lst;
    if len == 0 then
        return;
    end
    for i = 1,len do
        My.OwnerIdList[i] = lst[i];
    end
end

--穿戴更新装备
function My.PutonUpdate(lst,type)
    if type ~= 1 then
        return;
    end
    local len = #lst;
    local len1 = #My.OwnerIdList;
    for i = 1,len do
        local id = nil;
        for j = 1, len1 do
            if lst[i] == My.OwnerIdList[j] then
                id = lst[i];
            end
        end
        if id == nil then
            My.ReqFashionChg(1,lst[i]);
        end
    end
end

function My:Clear()

end

function My:Dispose()

end

return My;