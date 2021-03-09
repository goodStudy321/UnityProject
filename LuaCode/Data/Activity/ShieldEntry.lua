ShieldEntry = {Name = "ShieldEntry"}
local My = ShieldEntry;
--屏蔽列表
My.ShieldList = {}

function My:Init()
    self:AddLsnr();
  end
  
function My:AddLsnr()
    local PrtLsnr =  ProtoLsnr.AddByName;
    PrtLsnr("m_ban_function_list_toc",self.FuncList,self);
end

function My:FuncList(msg)
    local idList = msg.id_list;
    if idList == nil then
        return;
    end
    My:ClearList();
    My:SetList(idList);
end

--设置列表
function My:SetList(list)
    local len = #list;
    for i = 1,len do
        local id = list[i];
        My.ShieldList[id] = true;
    end
end

--清除列表
function My:ClearList()
    for k,v in pairs(My.ShieldList) do
        My.ShieldList[k] = nil;
    end    
end

--Id是否被屏蔽
function My.IsShield(id)
    if id == nil then
        return false;
    end
    local result = My.ShieldList[id];
    if result == nil then
        return false;
    end
    return true;
end

--屏蔽对象
function My.ShieldGbj(id,gbj)
    if id == nil then
        return;
    end
    if gbj == nil then
        return;
    end
    local shield = ShieldEntry.IsShield(id);
	if shield == true then
		gbj:SetActive(false);
	end
end

--清除数据
function My:Clear()
    self:ClearList();
end

return My;