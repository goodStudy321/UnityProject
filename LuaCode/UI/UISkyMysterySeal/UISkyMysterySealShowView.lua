UISkyMysterySealShowView = {}

local M = UISkyMysterySealShowView

function M:New(go)
    self.Root = go  
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealShowView"
    self.BG = C(UITexture, trans, "BG", name, false)
    self.PageBtn = T(trans, "Page")
    self.PageBG = C(UISprite, trans, "Page/Background")
    self.PageLock = T(trans, "Page/Lock")
    self.PageLab = C(UILabel, trans, "Page/Label", name, false)
    self.PageAction = T(trans, "Page/Action")
    --self.ShowPro = T(trans, "ShowPro")
    self.AllScoreLab = C(UILabel, trans, "AllScore", name, false)
    self.ActivePro = C(UILabel, trans, "ActivePro", name, false)
    self.ActiveType = C(UILabel, trans, "ActivePro/Type", name, false)

    self.TipBtn = T(trans, "Label")
    self.TipRoot = T(trans, "Tip")
    self.TipDes = C(UILabel, trans, "Tip/Label", name, false)
    local temp = InvestDesCfg["2005"]
    if temp then
        self.TipDes.text = temp.des
    end

    self.Items = {}
    for i=0,8 do
        self:AddItem(T(trans, string.format("%s",i)), i)
    end

    
    --UITool.SetLsnrSelf(self.ShowPro, self.OnClickShowPro, self, nil, false)
    local SLS = UITool.SetLsnrSelf
    SLS(self.PageBtn, self.OnClickPageBtn, self, nil, false)
    SLS(self.TipBtn, self.OnClickTipBtn, self, nil, false)
    SLS(self.TipRoot, self.OnClickTipRoot, self, nil, false)
	return self
end

function M:AddItem(go, index)
    if LuaTool.IsNull(go) == true then return end
    local item = ObjPool.Get(UISkyMysterySealItem)
    item:Init(go, self, index)
    self.Items[tostring(index)] = item
end

-----------------------------------------------------
function M:UpdateData()
    self:UpdateBG()
    self:UpdatePageLab()
    self:UpdateItems()
    self:UpdateAllScoreLab(true)
    self:UpdateActivePro(true)
    self:UpdatePageBtn(true)
    self:UpdateShowPro(true)
end

function M:UpdatePreview(info)
    self:ResetItems()
    --self:Reset()
    local page = SMSMgr.PageType.Yang
    self:UpdateBG(page)
    self:UpdatePageLab(page)
    --self:UpdateItems(page)
    self:UpdateAllScoreLab(false)
    self:UpdateActivePro(false)
    self:UpdatePageBtn(false)
    self:UpdateShowPro(false)
    self:UpdatePreviewItems(info)
end

function M:UpdateBG(page)
    local pageType = SMSMgr.PageType 
    if page == nil then page = SMSMgr.CurPage end
    local path = ""
    if page == pageType.Yang then
        path = "tianji_bagua_yang.png"
    elseif page == pageType.Yin then
        path = "tianji_bagua_yin.png"
    end
    if path == self.Path then return end
    self:UnloadPic()
	local bg = self.BG
	if bg then
		if not StrTool.IsNullOrEmpty(path) then	
			self.Path = path
			local del = ObjPool.Get(DelLoadTex)
			del:Add(bg)
			del:SetFunc(self.SetPicIcon,self)
			AssetMgr:Load(path,ObjHandler(del.Execute, del))
			return
		end
	end
end

function M:SetPicIcon(tex, pic)
	if LuaTool.IsNull(pic) == false then
        pic.mainTexture = tex
    else
        self:UnloadPic()
	end
end

function M:UpdateItems(page)
    self:ResetItems()
    if not page then page = SMSMgr.CurPage end
    local items = self.Items
    local len = LuaTool.Length(items) - 1
    if len > 0 then
        for i=0,len do
            items[tostring(i)]:UpdateData(page)
            --items[tostring(i)]:UpdateEff()
            items[tostring(i)]:UpdateActive()        
        end
    end
end

function M:FirstClick(page)
    if not page then page = SMSMgr.CurPage end
    local items = self.Items
    local len = LuaTool.Length(items) - 1
    if len > 0 then
        for i=0,len do
            local info = SMSMgr:GetPageInfo(page, i)
            local itInfo = items[tostring(i)]
            if info and info.Pro and info.Pro.Item then
                itInfo.Info = info
                itInfo:OnClick(nil,true)
                break
            end
        end
    end
end

function M:UpdateEffect(page)
    if not page then page = SMSMgr.CurPage end
    local items = self.Items
    local len = LuaTool.Length(items) - 1
    if len > 0 then
        for i=0,len do
            items[tostring(i)]:UpdateEff()
        end
    end
end

function M:UpdatePreviewItems(info)
    local id = info[#info]
    local temp = SMSSuitProTemp[tostring(id)]
    local list = temp.condition
    local len = #list 
	if len>=3 then
        local proTemp = SMSProTemp["805301"]
        if proTemp then
            local item = self.Items[tostring(proTemp.index)]
            item:UpdatePreview(proTemp)
        end
	end
    for i=1,len do
        local proTemp = SMSProTemp[tostring(list[i])]
        if proTemp then
            local item = self.Items[tostring(proTemp.index)]
            item:UpdatePreview(proTemp)
        end
    end
end

--点击翻页
function M:UpdatePageLab(page)
    if not page then page = SMSMgr.CurPage end
    local txt = SMSMgr:GetPageName(page)
    self.PageLab.text = txt
    self.ActiveType.text = txt
end

function M:UpdateAllScoreLab(show)
    self.AllScoreLab.gameObject:SetActive(show)
    if not show then return end
    local value = User.MapData:GetFightValue(41)
    if StrTool.IsNullOrEmpty(value) then value = "0" end
    self.AllScoreLab.text = value
end

function M:UpdateActivePro(show)
    self.ActivePro.gameObject:SetActive(show)
    if not show then return end
    local list, dic = SMSMgr:GetAllActiveSuit()
    local strs = ""
    if list and dic then
        for i = 1 ,#list do
            local type = list[i]
            local info = dic[type]
            if info then
                strs = string.format("%s%s[%s/%s][-]",strs, UIMisc.LabColor(info.Quality), info.Num, info.Num)
            end
        end
    end
    if StrTool.IsNullOrEmpty(strs) == true then 
        strs = "无套装"
    else
        --self:UpdateEffect()
    end
    self.ActivePro.text = strs
end

function M:UpdatePageBtn(show)
    self.PageBtn.gameObject:SetActive(show)
    local cur = SMSMgr.CurPage 
    local pageType = SMSMgr.PageType
    if cur == pageType.Yang then
        cur = pageType.Yin
    elseif cur == pageType.Yin then
        cur = pageType.Yang
    end
    local isOpen, temp = SMSMgr:IsOpen(cur)
    self.PageLock:SetActive(not isOpen)
    local strengthState = SMSMgr.PageStrength
    local isRed = isOpen and ((cur == pageType.Yang and strengthState[cur] == true) or (cur == pageType.Yin and strengthState[cur] == true))
    self.PageAction:SetActive(isRed)
    local color = Color.white
    if not isOpen then
        color = Color.gray
    end
    self.PageBG.color = color
end

function M:UpdateShowPro(show)
    --self.ShowPro:SetActive(show)
end
--[[
function M:UpdateSAction()
    if not page then page = SMSMgr.CurPage end
    local items = self.Items
    local len = LuaTool.Length(items) - 1
    if len > 0 then
        for i=0,len do
            items[tostring(i)]:UpdateActive()
        end
    end
end
]]--
-----------------------------------------------------
--更新开孔
function M:UpdateHoldInfo(info, isOpen)
    --
    local key = tostring(info.OpenTemp.index)
    local item = self.Items[key]
    item:UpdateData(SMSMgr.CurPage, isOpen)
    self:OnClickEvent(info)
    self:UpdateAllScoreLab(true)
    self:UpdateActivePro(true)

    for k,v in pairs(self.Items) do
        v:UpdateSuitEff()
    end
end
-----------------------------------------------------
function M:OnClickEvent(info,isInit)
    isInit = isInit or false
    self:UpdateSelectIndex(info.OpenTemp.index)
    local value = SMSMgr.CurToggle
    if value == 1 then 
        if info.Pro then
            if info.Pro.Item ~= nil then
                if not isInit then
                    self:ShowTip(info)
                end
            else
                SMSControl:HideTipView()
            end
            --self:ShowTypeItems(info)
            SMSControl:UpdateWarehouseViewArr(info)           
        end
    elseif value == 2 then
        if info.Pro then
            if info.Pro.Item == nil then
                SMSControl:ShowWarehouseView(info)
                --self:ShowTypeItems(info)
                SMSControl:UpdateWarehouseViewArr(info)    
            else
                SMSControl:ShowStrengthView(info)
            end
        end
    elseif value == 3 then
        if info.Pro then
            if info.Pro.Item ~= nil then
                self:ShowTip(info)
            end
        end
    end
end

function M:UpdateSelectIndex(index)
    local curIndex = SMSMgr.CurSelectIndex
    if curIndex ~= -1 then
        self.Items[tostring(curIndex)]:SetSelect(false)
    elseif curIndex == index then
        return 
    end
    if index ~= -1 then
        self.Items[tostring(index)]:SetSelect(true)
        SMSMgr.CurSelectIndex = index
    end
end

function M:OnClickShowPro()
    SMSControl:ShowProTipView()
end

function M:OnClickPageBtn(go)
    local cur = SMSMgr.CurPage 
    local pageType = SMSMgr.PageType
    if cur == pageType.Yang then
        cur = pageType.Yin
    elseif cur == pageType.Yin then
        cur = pageType.Yang
    end
    if cur == pageType.Yin then
        local isOpen, temp = SMSMgr:IsOpen(cur)
        if isOpen == false and temp then 
            local copyTemp = CopyTemp[tostring(temp.condition)]
            local copy = ""
            if copyTemp then copy = copyTemp.name end
            local layer = ""
            MsgBox.ShowYes(string.format("当前分页未激活\n开启[00ff00]【%s】[-]后方能激活\n是否立即前往？", copy, layer),
            SMSControl.OpenCopyUI, 
            SMSMgr, 
            "确定")
            return 
        end
    end
    self:SetPage(cur)
    if SMSMgr.CurToggle == 1 then
        SMSControl.HideOpenView()
    else
        SMSControl.ShowWarehouseView()
    end
    SMSControl:UpdateStrengthView()
end

function M:OnClickTipBtn(go)
    self.TipRoot:SetActive(true)
end
function M:OnClickTipRoot(go)
    self.TipRoot:SetActive(false)
end

function M:SetPage(cur)
    SMSMgr.CurPage = cur
    self:UpdateBG()
    self:UpdatePageLab()
    self:UpdateItems()
    self:UpdateActivePro(true)
end
-----------------------------------------------------

function M:ShowTip(info)
    if not info or not info.Pro or not info.Pro.Item then return end
    SMSControl:ShowTipView(info.Pro.Item, false)
end

function M:ShowTypeItems(info)
    if not info or not info.Pro then return end
    SMSControl:SetWarehouseViewMenu(info)
end
-----------------------------------------------------


function M:SetActive(bool)
    self.Root:SetActive(bool)
end

function M:ActiveSelf()
    return self.Root.activeSelf
end

function M:Reset()
    self:UnloadPic()
    self:ResetItems()
    self:UpdatePageLab()
    self:UpdateActivePro(false)
end

function M:UnloadPic()
	if not StrTool.IsNullOrEmpty(self.Path) then
		AssetMgr:Unload(self.Path, ".png", false)
	end
    self.Path = nil
    local bg = self.BG
    if bg then
        bg.mainTexture = nil
        bg.gameObject:SetActive(false)
        bg.gameObject:SetActive(true)
    end
end

function M:ResetItems()
    local items = self.Items
    if not items then return end
    for k,v in pairs(items) do
        v:Reset()
    end
end

function M:DestroyItems()
    local items = self.Items
    if not items then return end
    local len = LuaTool.Length(items) - 1
    for i=0,len do
        local item = items[i]
        if item then item:Dispose() end
        ObjPool.Add(item)
        items[i] = nil
    end
    self.Items = nil
end

function M:Dispose()
    self:UnloadPic()
    self:DestroyItems()
    self.PageBtn = nil
    self.PageLab = nil
    self.AllScoreLab = nil
    self.ActivePro = nil
end