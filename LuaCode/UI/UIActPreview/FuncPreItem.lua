FuncPreItem = Super:New{Name = "FuncPreItem"}
local M = FuncPreItem

local aMgr=Loong.Game.AssetMgr
local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetLsnrClick
local btnStatus = nil

function M:Init(obj)
    self.obj = obj
    self.trans = obj.transform

    self.isLoading = false

    local trans = self.trans
    self.tex = C(UITexture,trans,"tex/icon",self.Name)
    self.btnLb = C(UILabel,trans,"goBtn/Lb",self.Name)
    self.name = C(UILabel,trans,"name",self.Name)
    self.des = C(UILabel,trans,"des",self.Name)
    self.need = C(UILabel,trans,"need",self.Name)
    --self.open = T(trans,"open")
    --self.noOpen = T(trans,"noOpen")
    self.show =T(trans,"show")
    self.goBtn = T(trans,"goBtn")
    self.spr = C(UISprite,trans,"spr1",self.Name)
    self.spr1 = T(trans,"spr1")
    self.spr2 = T(trans,"spr2")
    self.spr3 = T(trans,"spr3")
    self.spr4 = T(trans,"spr4")
    self.awardObj = T(trans,"itemGrid")
    self.award = C(UIGrid,trans,"itemGrid",self.Name)
    US(trans,"goBtn",self.Name,self.ClickToGo,self)
    self.txBtn = T(trans,"goBtn/action")
    self.y1 = self.spr2.transform.localPosition.y
    self.y2 = self.spr3.transform.localPosition.y
    self.type = nil
    self.items = {}
    self:SetLsner("Add")
end

function M:SetLsner(key)
    ActPreviewMgr.eChgBtn[key](ActPreviewMgr.eChgBtn, self.UpBtnStatus, self)
end

function M:InitItem(data)
    self.data = data
    local tex = data.texture
    local award = data.award
    self:ClearItem()
    if data.award then
        for i=1,#award do
            self.item = ObjPool.Get(UIItemCell)
            self.item:InitLoadPool(self.awardObj.transform,0.8)
            self.item:UpData(award[i].id,award[i].num)
            self.items[#self.items + 1] = self.item
        end
    end
    self:LoadTexture(tex[1])
    local str = data.trigType==1 and "开启" or "主线开启"
    self.des.text = string.format("%s级%s", UIMisc.GetLv(data.level), str)
    self.need.text = data.previewDes
    self.name.text = data.des
    self:UpBtnStatus()
    self:InitLbSize()
    self.award:Reposition()
end

function M:InitLoadPool(parent)
    self.isLoading = true
    local path = "UIFuncOpenItem"
    local del = ObjPool.Get(DelGbj)
	del:Adds(parent)
	del:SetFunc(self.LoadItem,self)
	aMgr.LoadPrefab(path,GbjHandler(del.Execute,del))
end

function M:LoadItem(go,parent)
    self.isLoading = false
    self:Init(go)
    go.transform.parent=parent
    local strans = self.trans
    go.transform.localPosition = Vector3.zero
	--go.transform.localRotation = strans.localRotation
    go.transform.localScale = Vector3.one
    
end

function M:InitSprPos()
    self.spr1.transform.localPosition = Vector3(0,self.y1,0)
    self.spr2.transform.localPosition = Vector3(0,self.y1,0)
    self.spr3.transform.localPosition = Vector3(0,self.y2,0)
    self.spr4.transform.localPosition = Vector3(0,self.y2,0)
end

function M:InitLbSize()
    local nObj = self.name.gameObject
    local dObj = self.des.gameObject
    local p1 = self.spr.width/2
    local w1 = self.name.width/2
    local w2 = self.des.width/2
    local x1 = nObj.transform.localPosition.x
    local x2 = dObj.transform.localPosition.x
    local lerp1 = w1 + p1 + 3
    local lerp2 = w2 + p1 + 3
    --local trans1 = self.spr1.gameObject.transform
    local trans1 = self.spr1.transform
    local pos1 = trans1.localPosition
    local trans2 = self.spr2.transform
    local pos2 = trans2.localPosition
    local trans3 = self.spr3.transform
    local pos3 = trans3.localPosition
    local trans4 = self.spr4.transform
    local pos4 = trans4.localPosition
    trans1.localPosition = pos1 + Vector3(x1+lerp1,0,0)
    trans2.localPosition = pos2 + Vector3(x1-lerp1,0,0)
    trans3.localPosition = pos3 + Vector3(x2-lerp2,0,0)
    trans4.localPosition = pos4 + Vector3(x2+lerp2,0,0)
end

function M:LoadTexture(texture)
    AssetMgr:Load(texture,ObjHandler(self.SetIcon, self))
end

function M:SetIcon(texture)
    AssetMgr:SetPersist(texture.name, ".png",true)
    if self.tex then
        --self.tex:MakePixelPerfect()
        self.tex.mainTexture = texture
    end
end

function M:UpBtnStatus()
    local userLv = User.MapData.Level
    local id = self.data.id
    if OpenMgr:IsOpen(tostring(id)) == false then
        self:ShowOpen(false)
    else
        if userLv < self.data.level then
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
        self.show:SetActive(false)
        self.txBtn:SetActive(false)
    else
        local list = ActPreviewMgr.getList
        local id = self.data.id
        self.type = 1
        self.btnLb.text = "领取奖励"
        self.show:SetActive(false)
        self.txBtn:SetActive(false)
        self.txBtn:SetActive(true)
        for i,v in ipairs(list) do
            if v == self.data.id or not self.data.award then
                self.btnLb.text = "立即前往"
                self.txBtn:SetActive(false)
                self.type = 0
                if self.data.award then
                    self.show:SetActive(true)
                else
                    self.show:SetActive(false)
                end
            end
        end
        UITool.SetNormal(self.goBtn)
    end
    --self.open:SetActive(bool)
    --self.noOpen:SetActive(not bool)
end

-- 前往按钮
function M:ClickToGo()
    if self.type == 0 then
        local data = self.data
        QuickUseMgr.JumpOther(data)
        return
    end
    local id = self.data.id
    ActPreviewMgr:ReqAward(id)
end

function M:Show(bool)
    self.obj:SetActive(bool)
end

function M:ClearItem()
    while #self.items > 0 do
        local item = self.items[#self.items]
        item:DestroyGo()
        ObjPool.Add(item)
        self.items[#self.items] = nil
    end
end

function M:UnLoad()
    if self.isLoading==false then
        self:InitSprPos()
        -- self.obj.transform.parent = nil
        -- self.obj:SetActive(true)
		GbjPool:Add(self.obj)
	end
end

function M:Dispose()
    self.type = nil
    AssetTool.UnloadTex(self.tex)
    self.tex = nil
    self:ClearItem()
    
    self:UnLoad()
    self:SetLsner("Remove")
    TableTool.ClearUserData(self)
end

return M