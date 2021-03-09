TitleModel = Super:New{Name = "TitleModel"}

require("Tool/MyGbjPool")

local M = TitleModel
local aMgr = Loong.Game.AssetMgr

function M:Init(root)
    local G = ComTool.Get

    self.title = TransTool.Find(root, "Title")
    self.labTime = G(UILabel, root, "Time")
    self.name = G(UILabel, root, "Name")
    self.level = G(UILabel, root, "Level")
    self.model = ObjPool.Get(RoleSkin)
    self.model.eLoadModelCB:Add(self.SetModel, self)
    self.model:CreateSelf(root)

    self.name.text = User.MapData.Name
    self.level.text = User.MapData.Level

    self.gbjPool = ObjPool.Get(MyGbjPool)
end

function M:SetModel(go)
    go.transform.localScale = Vector3(300,300,300)
    go.transform.localPosition = Vector3(-37,-280,0)
end


function M:UpdateModel(data)
    if not data then
        self.labTime.gameObject:SetActive(false)   
        return
    end
    self:UpdateTitle(data.cfg.id)
    self:UpdateTime(data.have)
end


--更新称号
function M:UpdateTitle(id)
    local name = TitleCfg[tostring(id)].prefab1
    if StrTool.IsNullOrEmpty(name) then return end
    if self.curTitle and self.curTitle.name == name then return end
    name = QualityMgr:GetQuaEffName(name)
    local go = self.gbjPool:Get(name)
    if not go then
        if not AssetTool.IsExistAss(name) then 
            UITip.Log("该称号资源正在加载...")
            return 
        end
        aMgr.LoadPrefab(name, GbjHandler(self.SetTitle, self))
    else
        self:SetTitle(go)
    end
end

function M:SetTitle(go)  
    if not LuaTool.IsNull(self.title) then
        self.gbjPool:Add(self.curTitle)
        self.curTitle = go
        go.transform:SetParent(self.title)
        go.transform.localScale = Vector3.one
        go.transform.localPosition = Vector3(0,230,0)
    else
        self:Unload(go)
    end
end

function M:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name,".prefab", false)
    GameObject.DestroyImmediate(go)
end


--更新称号有效时间
function M:UpdateTime(time)
    self.labTime.gameObject:SetActive(time>=0)   
    if time == 0 then
        self.labTime.text = "永久"
        self:StopTimer()
    elseif time > 0 then
        self:StartTimer(time)
    end
end

function M:StopTimer()
    if self.timer then
        self.timer:Stop()
    end
end

function M:StartTimer(eTime)
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
    end
    local timer = self.timer
    timer:Stop()
    local now = TimeTool.GetServerTimeNow()*0.001
    local dValue = eTime - now
    if dValue <= 0 then
        timer.remain=""
    else
        timer.seconds = dValue
        timer.invlCb:Add(self.UpTime, self)
        timer.complete:Add(self.Complete, self)
        timer:Start()
        self:UpTime()
    end
end

function M:UpTime()
    self.labTime.text = string.format("有效期限：%s", self.timer.remain)
end

function M:Complete()
    self.labTime.text = "";
end

function M:Dispose()
    ObjPool.Add(self.model)
    self.model.eLoadModelCB:Clear()
    self.model = nil
    ObjPool.Add(self.gbjPool)
    self.gbjPool = nil
    self:Unload(self.curTitle)
    self.curTitle = nil
    TableTool.ClearUserData(self)
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
end

return M