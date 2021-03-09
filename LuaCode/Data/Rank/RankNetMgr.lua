RankNetMgr = {Name = "RankNetMgr"}
local My = RankNetMgr

function My:Init()
    self.EXP = nil
    self:Clear()
    self.eRankInfo = Event()
    self.eRankParams = Event()
    self.eRankEnd = Event()
    self.eRoleExp = Event()    
    self:AddProto()
end

function My:AddProto()
    self:ProtoHandler(ProtoLsnr.Add)
end

function My:RemoveProto()
    self:ProtoHandler(ProtoLsnr.Remove)
end

function My:ProtoHandler(Lsnr)
    Lsnr(22402, self.RespRankInfo, self)
    Lsnr(21084, self.RespRoleExpEff, self)    
end

function My:ReqRankInfo(key)
    local msg = ProtoPool.GetByID(22401)
    msg.rank_id = key
    ProtoMgr.Send(msg)
end

function My:RespRankInfo(msg)
    local key = msg.rank_id
    local list = msg.ranks
    for i,j in ipairs(list) do
        self.eRankInfo(key, j.rank, j.role_id, j.role_name, j.role_level, j.vip_level, j.category, j.confine)
        for k,v in ipairs(j.kv_list) do
            self.eRankParams(key, j.rank, v.id, v.val)
        end
        for g,h in ipairs(j.ks_list) do
            self.eRankParams(key, j.rank, h.id, h.str)
        end
    end
    self.eRankEnd()
end

function My:RespRoleExpEff(msg)
    local exp = msg.exp_efficiency
    self.EXP = exp
	self.eRoleExp(exp)
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self:RemoveProto()
    TableTool.ClearFieldsByName(self,"Event")
end

return My
