UISkyMysterySealItem = Super:New{Name = "UISkyMysterySealItem"}

local M = UISkyMysterySealItem

function M:Init(go, parent, index)
    self.Root = go
    self.Parent = parent
    self.Index = index
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealItem"

    self.Icon = C(UITexture, trans, "Icon", name, false)
    self.Word = C(UISprite, trans, "Index")
    self.SLV = C(UILabel, trans, "StrengthLv", name, false)
    self.SLVBG = T(trans, "StrengthLv/Sprite")
    self.Lock = T(trans, "Lock")
    self.Mask = T(trans, "Mask")
    self.Select = T(trans, "Select")
    self.Eff = C(UIWidget, trans, "Eff", name, false)
    self.OpenEff = T(trans, "OpenEff")
    self.Action = T(trans, "Action")

    UITool.SetLsnrSelf(go, self.OnClick, self, nil, false)
end

function M:UpdateData(type, isOpen)
    self:Reset()
    local info = SMSMgr:GetPageInfo(type, self.Index)
    if info then
        self.Info = info
        local pro = info.Pro
        self:UpdateIcon(pro)
        self:UpdateWord(pro ~= nil and pro.Item ~= nil, info.OpenTemp.index)
        self:UpdateSL(pro)
        self:UpdateLock(pro == nil)
        self:UpdateSuitEff()
        if isOpen == true then
            self.OpenEff:SetActive(true)
        end
        local type = SMSMgr.CurPage
        local index = SMSMgr.CurSelectIndex
        if type == info.OpenTemp.type and  index ~= -1 then
            if index == info.OpenTemp.index then
                self:SetSelect(true)
            end
        end
    end
end

function M:UpdateSuitEff()
    if not self.Info or not self.Info.Pro or not self.Info.Pro.Item then 
        self:UnloadMode()
        return 
    end
    if self.Info.OpenTemp.index ~= 0 then
        if SMSMgr:IsCheckSuitActiveForId(self.Info.Pro.Item.type_id) == false then 
            self:UnloadMode()
            return 
        end
    else
        if #SMSMgr.SuitActiveInfos[SMSMgr.CurPage] <=0 then 
            self:UnloadMode()
            return 
        end
    end
    self:UpdateEff()
end

function M:UpdatePreview(temp)
    local info = {}
    info.OpenTemp = SMSOpenTemp[tostring(1010 + temp.index)]
    info.Pro = {}
    info.Pro.Item = ItemData[tostring(temp.id)]
    self.Info = info
    self:SetIcion(info.Pro.Item.icon)
    self:UpdateLock(false)
    self:UpdateEff(temp)
    self:UpdateWord(true, info.OpenTemp.index)
    --self:UpdateData(false, temp.index)
end

function M:UpdateIcon(pro)
    self.Mask:SetActive(pro ~=nil and pro.Item ~= nil)
    if pro == nil or pro.Item == nil then
        self:UnloadPic()
        return
    end
    local temp = ItemData[tostring(pro.Item.type_id)]
    if not temp then
        self:UnloadPic()
        return
    end
    self:SetIcion(temp.icon)
end

function M:SetIcion(path)
    if self.Path ~= path then
        self:UnloadPic()
    end
	local pic = self.Icon
	if pic then
		if not StrTool.IsNullOrEmpty(path) then	
			self.Path = path
			local del = ObjPool.Get(DelLoadTex)
			del:Add(pic)
			del:SetFunc(self.SetPicIcon,self)
			AssetMgr:Load(path,ObjHandler(del.Execute , del))
			return
		end
	end
end

function M:UpdateWord(status, index)
    local cur = SMSMgr.CurPage
    local page = "yang"
    if cur ~= 1 then page = "yin" end
    if status == true then
        self.Word.spriteName = string.format("%s%s",page, index)
    else
        self.Word.spriteName = string.format("%s%s_bg",page, index)
    end
end

function M:UpdateSL(pro)
    local lv = nil
    if pro and pro.StrengthLv ~= nil and pro.StrengthLv > 0 and pro.Item ~= nil then
        local proTemp = SMSProTemp[tostring(pro.Item.type_id)]
        if proTemp then
            if pro.StrengthLv > proTemp.limit then
                lv = tostring(proTemp.limit)
            else
                lv = tostring(pro.StrengthLv)
            end
        end
    end
    if lv ~= nil then
        self.SLV.text = "+"..lv
    else
        self.SLV.text = ""
    end 
    if LuaTool.IsNull(self.SLVBG) == false then
        self.SLVBG:SetActive(lv ~= nil)
    end
end

function M:UpdateLock(lock)
    self.Lock:SetActive(lock)
end

function M:SetPicIcon(tex, pic)
    if LuaTool.IsNull(pic) == false then
        pic.mainTexture = tex
    else
        self:UnloadPic()
	end
end

function M:UpdateEff(cfg)
    local temp = cfg
    if not cfg then
        local info = self.Info
        if not info then return end
        local openTemp = info.OpenTemp
        if not openTemp then return end
        local pro = info.Pro
        if not pro then return end
        local item = pro.Item
        if not item then return end
        id = item.type_id
        temp = SMSProTemp[tostring(id)]
    end
    local path = nil
    if temp.index == 0 then
        path = "FX_sky_bj"
    else
        path = string.format("FX_sky_00%s",temp.quality)
    end
    if StrTool.IsNullOrEmpty(path) == true then return end
    if self.EffPath == path then return end
    self:UnloadMode()
    self.EffPath = path
    local del = ObjPool.Get(DelGbj);
	del:Add(self.Eff);
    del:SetFunc(self.LoadEff,self);
    Loong.Game.AssetMgr.LoadPrefab(path,GbjHandler(del.Execute,del));
end

function M:LoadEff(go, parent)
    if not self.Info or not self.Info.Pro or not self.Info.Pro.Item  or go.name ~= self.EffPath then 
        self:UnloadMode()
        return
    end
    self.Effect = go
    local trans = go.transform
    trans.parent = parent.transform
	trans.eulerAngles = Vector3.zero
	trans.localPosition = Vector3.zero
    trans.localScale = Vector3.one
    local cs = go:AddComponent(typeof(UIEffBinding))
    if cs then
        cs.specifyWidget = parent
    end
    LayerTool.Set(trans, 5)
    go:SetActive(true)
end

function M:UnloadMode()
	if LuaTool.IsNull(self.Effect) == false then
		Destroy(self.Effect)
		if not StrTool.IsNullOrEmpty(self.EffPath) then
			AssetMgr:Unload(self.EffPath,".prefab", false)
		end
	end
	self.Effect = nil
	self.EffPath = nil
end

-------------GS  Star---------------------------

function M:UpdateActive()
    if LuaTool.IsNull(self.Action) == true then return end
    if self.Info and self.Info.Pro then
        local index = self.Info.Pro.Index
        -- local index = self.Info.OpenTemp.index
        local isAc = false
        if SMSMgr.HoleRedTab[index] then
            isAc = true
        end
        self.Action:SetActive(isAc)
    end
end
------------GS  End----------------------------
--[[
function M:UpdateActive()
    if LuaTool.IsNull(self.Action) == true then return end
    if self.Info and self.Info.Pro then
        self.Action:SetActive(self.Info.Pro.SStatus)
    end
end
]]--
-----------------------------------------------------
function M:OnClick(go,isInit)
    local info = self.Info
    if not info then return end
    if not info.Pro then
        local status = FiveElmtMgr.UnLockCopy(info.OpenTemp.condition)
        if status == false then
            local temp = info.OpenTemp
            local name = temp.name
            local copyTemp = CopyTemp[tostring(temp.condition)]
            local copy = ""
            if copyTemp then copy = copyTemp.name end
            MsgBox.ShowYes(string.format("当前选中的[00ff00]【%s】[-]未激活\n开启[00ff00]【%s】[-]后方能激活\n是否立即前往？",name, copy, layer),
            SMSControl.OpenCopyUI, 
            SMSMgr, 
            "确定")
        else
            if info.OpenTemp.item then
                SMSControl:ShowOpenView(info)
            end
        end
    end
    local parent = self.Parent
    if parent then
        parent:OnClickEvent(info,isInit)
    end
end

-----------------------------------------------------

function M:SetSelect(bool)
    self.Select:SetActive(bool)
end

function M:SetActive(bool)
    self.Root:SetActive(bool)
end

function M:ActiveSelf()
    return self.Root.activeSelf
end

function M:Reset()
    if self.Info then
        self:UpdateWord(false, self.Info.OpenTemp.index)
    end
   self.Action:SetActive(false)
    self.Info = nil
    self:UnloadPic()
    self:UpdateSL()
    self:UpdateLock(true)
    self:SetSelect(false)
    self:UnloadMode()
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.Path) then
		AssetMgr:Unload(self.Path, ".png", false)
	end
    self.Path = nil
    local icon = self.Icon
    if icon then
        icon.mainTexture = nil
        icon.gameObject:SetActive(false)
        icon.gameObject:SetActive(true)
    end
end

function M:Dispose()
    self:UnloadPic()
    self:UnloadMode()
    self.BG = nil
    self.SLV = nil
    self.Lock = nil
end

return M