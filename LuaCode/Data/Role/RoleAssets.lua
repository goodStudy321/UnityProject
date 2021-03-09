RoleAssets = {Name = "RoleAssets"}
local My = RoleAssets;
--资源更新事件
My.eUpAsset = Event();

--银两
My.Silver = 0;

--元宝
My.Gold = 0;

--绑定元宝
My.BindGold = 0;

--荣誉
My.HonorVal = 0;

--帮派贡献
My.FamilyCon = 0;

--魅力值
My.Charm = 0;

--寻宝积分
My.HontInteg = 0;

--镇星石
My.Essence = 0;

--玄晶
My.AresCoin = 0

--活跃度货币
My.Liveness = 0

--威望
My.Prestige = 0

My.eEnd=Event()
My.eCharm = Event();
My.eBaseProperty=Event()


function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    local PA =  ProtoLsnr.AddByName;
    PA("m_role_asset_info_toc",self.SetAsset,self);
    PA("m_role_asset_change_toc",self.AssetChg,self);
    PA("m_role_charm_toc",self.reCharm,self);
    EventMgr.Add("OnUpdateProEnd",self.OnChangePro);
end

function My.OnChangePro(  )
    My.eBaseProperty()
end
--魅力值
function My:reCharm(msg)
    self.Charm=msg.charm;
    self.eCharm();
end

--上线推送资源
function My:SetAsset(msg)
    My.Silver = My.LongToNum(msg.silver);
    My.Gold = My.LongToNum(msg.gold);
    My.BindGold = My.LongToNum(msg.bind_gold);
    My.UpdateAssets(msg.score_list);
    My.eEnd()
end

--资源更新
function My:AssetChg(msg)
    My.UpdateAssets(msg.change_list);
end

--更新资源
function My.UpdateAssets(list)
    if list == nil then
        return;
    end
    local len = #list;
    for i = 1,len do
        local id = My.LongToNum(list[i].id);
        local val = My.LongToNum(list[i].val);
        if id == 1 then
            My.Silver = val; --银两
        elseif id == 2 then
            My.Gold = val;  --元宝
        elseif id == 3 then
            My.BindGold = val; --绑定元宝
        elseif id == 11 then
            My.HonorVal = val; --荣誉
        elseif id == 12 then
            My.HontInteg = val; --寻宝积分
        elseif id == 13 then
            My.Essence = val; --镇星石
        elseif id == 14 then
            My.AresCoin = val; --玄晶
        elseif id == 23 then
            My.Liveness = val;  --活跃度货币
        elseif id == 99 then
            My.FamilyCon = val; --帮派贡献
        elseif id == 26 then
            My.Prestige = val --威望
        end        
        My.eUpAsset(id);
    end
end

function My:GetTypeName(id)
    if id == 1 then
        return "银两"
    elseif id == 2 then
        return "元宝"
    elseif id == 3 then
        return "绑定元宝"
    elseif id == 4 then
        return "绑定元宝"
    elseif id == 11 then
        return "荣誉"
    elseif id == 12 then
        return "寻宝积分"
    elseif id == 13 then
        return "镇星石"
    elseif id == 99 then
        return "帮派贡献"
    elseif id==26 then
        return "威望"
    end        
    return "货币/积分"
end

function My:Clear()
    My.Silver = 0;
    My.Gold = 0;
    My.BindGold = 0;
    My.HonorVal = 0;
    My.FamilyCon = 0;
    My.HontInteg = 0;
    My.Essence = 0;
    My.AresCoin = 0
    My.Liveness = 0
    My.Prestige=0
end

function My:Dispose()
    self:Clear();
end

--获取消耗类型资源
function My.GetCostAsset(id)
    if id == 1 then
        return My.Silver; --消耗银两
    elseif id == 2 then
        return My.Gold;  --消耗元宝
    elseif id == 3 then
        return My.BindGold + My.Gold; --优先消耗绑定元宝
    elseif id == 4 then
        return My.BindGold --绑定元宝
    elseif id == 11 then
        return My.HonorVal; --消耗荣誉
    elseif id == 12 then
        return My.HontInteg; --消耗寻宝积分
    elseif id == 13 then
        return My.Essence; --消耗镇星石
    elseif id == 14 then
        return My.AresCoin  -- 玄晶
    elseif id == 23 then
        return My.Liveness  --活跃度货币
    elseif id == 99 then
        return My.FamilyCon; --消耗帮派贡献
    elseif id == 26 then
        return My.Prestige  --威望
    end
    return 0;
end

--获取消耗类型资源
function My.IdGetCostAsset(id)
    if id == 1 then
        return My.Silver; --消耗银两
    elseif id == 2 then
        return My.Gold;  --消耗元宝
    elseif id == 3 then
        return My.BindGold; --优先消耗绑定元宝
    elseif id == 4 then
        return My.BindGold --绑定元宝
    elseif id == 11 then
        return My.HonorVal; --消耗荣誉
    elseif id == 12 then
        return My.HontInteg; --消耗寻宝积分
    elseif id == 13 then
        return My.Essence; --消耗镇星石
    elseif id == 14 then
        return My.AresCoin  -- 玄晶
    elseif id == 23 then
        return My.Liveness  --活跃度货币
    elseif id == 99 then
        return My.FamilyCon; --消耗帮派贡献
    elseif id == 26 then
        return My.Prestige --威望
    end
    return 0;
end

--判断资源是否足够
function My.IsEnoughAsset(id,costNum)
    local curNum = My.GetCostAsset(id);
    if curNum >= costNum then
        return true;
    end
    return false;
end

--64位转数字
function My.LongToNum(value)
    if value == nil then
        return 0;
    end
    local val = tostring(value);
    val = tonumber(val);
    return val;
end


return My;