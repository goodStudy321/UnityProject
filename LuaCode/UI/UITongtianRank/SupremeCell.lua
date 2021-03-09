--[[

]]
SupremeCell=Super:New{Name="SupremeCell"}
local My = SupremeCell

function My:Init( go )
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local U = UITool.SetBtnClick
    local trans = go.transform
    
    self.nameLab=CG(UILabel,trans,"nameLab",self.Name,false)
    self.None=TF(trans,"None")
    self.Model=TF(trans,"Model").transform
    self.numLab=CG(UILabel,trans,"worshipBtn/num",self.Name,false)
    self.red=TF(trans,"worshipBtn/red")
    U(trans,"worshipBtn",self.Name,self.OnWorship,self)
    self.roleSkin=ObjPool.Get(RoleSkin)

    UITool.SetLsnrClick(trans,"mask",self.Name,self.OnReqInfo,self,false)
end

function My:OnReqInfo()
    local isCross = false
	if self.data.server_name~=tostring(FamilyBossInfo.server_name) then isCross=true end
    UserMgr:ReqRoleObserve(tonumber(self.data.role_id),isCross) 
end

function My:UpData(data)
    self.data=data
    if data then
        self.None:SetActive(false)
        self.nameLab.text=string.format("【%s】%s",data.server_name,data.role_name)
        local typeId = (data.category*10+data.sex)*1000+data.lv
        self.roleSkin:Create(self.Model,typeId,data.skin_list,data.sex)

        local num = CopyMgr:GetTxIndex(data.copy_id)
        self.numLab.text="通关层数: "..num

        self:OnAdmire()
    end
end

--膜拜
function My:OnWorship()
    if self.data.role_id==User.instance.MapData.UIDStr then UITip.Log("不可以膜拜自己哦！") return end
    local temp =GlobalTemp["177"]
    local time = temp.Value3
    if TongtianRankMgr.admire_times<time then
        TongtianRankMgr.network.ReqAdmire()
    else
        local text = string.format( "每天只可膜拜%s次，膜拜次数不足",time)
        UITip.Log(text)
    end
end

function My:OnAdmire()
    if self.data.role_id==User.instance.MapData.UIDStr then self.red:SetActive(false) return end
    self.red:SetActive(TongtianRankMgr.isRed)
end

function My:Dispose()
    if self.roleSkin then ObjPool.Add(self.roleSkin) self.roleSkin=nil end
end