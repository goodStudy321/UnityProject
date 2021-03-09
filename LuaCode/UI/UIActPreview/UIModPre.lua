UIModPre = Super:New{Name = "UIModPre"}
local M = UIModPre
local aMgr = Loong.Game.AssetMgr

-- 初始化
function M:Init(obj)
    self.obj = obj
    self.trans = obj.transform
    local trans = self.trans
    local US = UITool.SetBtnClick
    local T = TransTool.FindChild
    local C =ComTool.Get
    self.des = C(UILabel,trans,"des")
    self.btnLb = C(UILabel,trans,"goBtn/btnLb")
    self.goBtn = T(trans,"goBtn")
    US(trans,"left",self.Name,self.ClickToUp,self)
    US(trans,"right",self.Name,self.ClickToDown,self)
    US(trans,"goBtn",self.Name,self.ClickToGo,self)
    self.DetailScale =  Vector3(300,300,300)
    self.DetailPos = {
        Vector3(200,100,1000),
        Vector3(0,2,723),
        Vector3(-100,40,723),
        Vector3(-150,23,723),
        Vector3(-60,2,723),
        Vector3(-60,2,723)
    }
    self.index = 0
end

-- function M:SetLsnr(key)
--     ActPreviewMgr.eUpdatePreview[key](ActPreviewMgr.eUpdatePreview, self.InitData, self)
-- end

-- 打开
function M:Open()
    self.obj.gameObject:SetActive(true)
    self:InitData()
end

--关闭
function M:Close()
    self.obj.gameObject:SetActive(false)
end

function M:InitData()
    self.data = ActPreviewMgr:GetModList()
    local data = ActPreviewMgr:GetCurData()
    if not data then 
        data = self.data[1]
    end
    if data.level >self.data[#self.data].level then
        self.curId = self.data[1].id
        self:UpData(self.curId)
        return
    else
        local list = ActPreviewMgr.allList
        if not list then return end
        for i,v in ipairs(list) do
            for j,k in ipairs(self.data) do
                if v.id == k.id then
                    self.curId = v.id
                    self:UpData(self.curId)
                    return
                end
            end
        end
    end
end

function M:UpData(id)
    self.index = 0
    for i,v in ipairs(self.data) do
        if v.id == id then
            self.index = i
        end
    end
    self.info = SystemOpenTemp[tostring(id)]
    local info = self.info
    local mod = info.icon[3]
    self.detailPos = self.DetailPos[id] or Vector3.zero
    self:LoadModel(mod)
    self.des.text = info.preViewDes
    self:UpBtnStatus(info)
end

function M:LoadModel(name)
    aMgr.LoadPrefab(name,GbjHandler(self.SetDetailModel,self))
end

function M:SetDetailModel(go)
    self:ClearCurDetailModel()
    AssetMgr:SetPersist(go.name, ".prefab",true)
    self.curDetailModel = go
    go.transform:SetParent(self.trans)
    go.transform.localPosition =  self.detailPos
    go.transform.localScale = self.DetailScale
end

function M:ClearCurDetailModel()
    if self.curDetailModel then
        AssetMgr:Unload(self.curDetailModel.name, ".prefab", false)
        Destroy(self.curDetailModel)
        self.curDetailModel = nil
    end
end

function M:UpBtnStatus(info)
    local userLv = User.MapData.Level
    local temp = MissionTemp[tostring(info.trigParam)]
    if not temp or not temp.lv then return end 
    local lv = temp.lv
    local id = info.id
    if OpenMgr:IsOpen(tostring(id)) == false then
        self:ShowOpen(false)
    else
        if userLv < lv then
            self:ShowOpen(false)
            return
        end
        self:ShowOpen(true)
    end
end


function M:ShowOpen(bool)
    if bool == false then
        self.btnLb.text = "未解锁"
        UITool.SetGray(self.goBtn)
    else
        self.btnLb.text = "立即前往"
        UITool.SetNormal(self.goBtn)
    end
end
-- 上一个按钮
function M:ClickToUp()
    self.index = self.index - 1
    local index = self.index
    if self.index <= 0 then self.index = 1 return end
    if index ~= self.index then return end
    local id = self.data[self.index].id
    self:UpData(id)
end

-- 下一个按钮
function M:ClickToDown()
    local len = #self.data
    self.index = self.index + 1
    local index = self.index
    if self.index > len then self.index = len return end
    if index ~= self.index then return end
    local id = self.data[self.index].id
    self:UpData(id)
end

--前往按钮
function M:ClickToGo()
    local info = self.info
    QuickUseMgr.JumpOther(info)
end

-- 释放
function M:Dispose()
    -- self:SetLsnr("Remove")
    self:ClearCurDetailModel()
end

return M