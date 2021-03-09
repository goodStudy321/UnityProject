--[[
选角界面
--]]
UISelect=Super:New{Name="UISelect"}
local My=UISelect

local lsMgr = LoginSceneMgr;

function My:Ctor()
    self.list={}
end

function My:Init(go)
    local T = TransTool.FindChild
    self.trans=go.transform

    UITool.SetBtnClick(self.trans,"EnterBtn",self.Name,self.OnEnter,self)
    local U = UITool.SetLsnrSelf
    for i=1,3 do
        local gg = T(self.trans,"Grid/M".. i)
        U(gg,self.OnM,self,self.Name, false)
        local tb = ObjPool.Get(RoleCell)
        tb:Init(gg)
        self.list[i]=tb
    end
    UITool.SetLiuHaiAnchor(self.trans,"Grid",self.Name,true)

    self.eAdd=Event()

    self.model=ObjPool.Get(RoleSkin)
    self.parent=T(self.trans,"Model")
    self.model.eLoadModelCB:Add(self.SetPos,self)
end

function My:SetPos(go)
    -- local role=AccMgr.RoleList[AccMgr.curIndex]
    -- local pos = Vector3.New(36,-281,-186)
    -- local scale = Vector3.one*375
    -- local rat = Vector3.New(0,180,0)
    -- if role.sex==1 then --男
    --     pos = Vector3.New(36,-281,-150)
    -- end
    -- go.transform.localPosition=pos
    -- go.transform.localScale=scale
    -- go.transform.localEulerAngles=rat

    local role=AccMgr.RoleList[AccMgr.curIndex]

    --// 女
    local scenePos = lsMgr:GetStandPos(0);
    local scale = Vector3.one*375
    local rat = Vector3.New(0,0,0);
    --// 男
    if role.sex == 1 then 
        scenePos = lsMgr:GetStandPos(1);
    end
    go.transform.position = scenePos;
    go.transform.localScale = scale;
    go.transform.eulerAngles = rat;

    LayerTool.Set(go.transform, 12);
    --MapHelper.instance:SetShadowTarget(go);
end

function My:ShowRoleList()
    local list = AccMgr.RoleList
    if #list==0 then return end
    for i,v in ipairs(list) do
        self:RoleInfo(v,i)
    end
end

--点击进入游戏
function My:OnEnter()
    Mgr.ReqSelect(self.roleId,self.lv)
    AccMgr.eLoginCreate(false)
end

function My:OnM(go)
    local index = tonumber(string.sub(go.name,2))
    AccMgr.curIndex=index
    local role = AccMgr.RoleList[index]
    if role==nil then  --添加
        self.eAdd()
    else --显示当前角色信息(模型)
        if self.model then self.model:Dispose() end
        self.roleId=tostring(role.roleId)
        self.lv=role.lv
        local typeId=(role.cate * 10 + role.sex) * 1000 + role.lv       
        self.model:Create(self.parent,typeId,role.skinList,role.sex)
	    --self.model:CreateSelf()
    end
end

function My:RoleInfo(role,index)
    if not AccMgr.curIndex then AccMgr.curIndex=1 end
    if index==1 then self.roleId=tostring(role.roleId) self.lv=role.lv end
    local tb = self.list[index]
    tb:ShowData(role) 
    if index==AccMgr.curIndex then
        if self.model then self.model:Dispose() end
        local typeId=(role.cate * 10 + role.sex) * 1000 + role.lv
        self.model:Create(self.parent,typeId,role.skinList,role.sex)
    end
end

function My:SetTrans()
    
end

function My:Open()
    self.trans.gameObject:SetActive(true)
    lsMgr:ShowPlatform();
    self:ShowRoleList()
    UIMgr.Close(UIRefresh.Name)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
end

function My:Dispose()
    AccMgr.curIndex=nil
    ListTool.ClearToPool(self.list)
    if self.model then self.model.eLoadModelCB:Remove(self.SetPos,self) ObjPool.Add(self.model) self.model=nil end
    TableTool.ClearUserData(self)
end