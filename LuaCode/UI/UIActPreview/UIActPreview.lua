UIActPreview = UIBase:New{Name = "UIActPreview"}

local M = UIActPreview
local aMgr = Loong.Game.AssetMgr

function M:InitCustom()
    self.ActName = {"坐骑", "法宝","伙伴", "神兵", "翅膀", "宝座"}
    -- self.DetailPos = {
    --     Vector3(-9,-103,723),
    --     Vector3(-178,2,723),
    --     Vector3(-252,2,723),
    --     Vector3(-287,23,723),
    --     Vector3(-138,2,723),
    --     Vector3(-138,2,723)
    -- }
    -- self.DetailScale =  Vector3(375,375,375)
    self:InitUserData()
    self:ScreenChange(ScreenMgr.orient, true)
    self:SetLsnr("Add")
end

function M:ChgUI(name, state)
    if name == "UICrossfade" then
        self.dataiCam:SetActive(not state)
        -- self.actCam:SetActive(not state)
    end
end

function M:OpenCustom()
    -- if self.detail2.activeSelf then
    --     self.detail2:SetActive(false)
    --     self.act2:SetActive(true)
    --     self:SetMenuState(true)
    -- end
    self:SetMenuState(true)
    self:UpData()
    if self.status == 0 then
        self.act1:SetActive(true)
        self.act2:SetActive(false)
    else
        self.act1:SetActive(false)
        self.act2:SetActive(true)
    end
end


function M:InitUserData()
    local G = ComTool.Get
    local FG = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf 

    local root = self.root

    self.act1 = FG(root, "Act_1")
    self.actIcon = G(UITexture, root, "Act_1/Icon")
    self.des1 = G(UILabel, root, "Act_1/Des1")
    self.des12 = G(UILabel, root, "Act_1/Des2")
    S(self.act1, self.OpenDetail, self, nil, false)
  
    -- self.detail1 = FG(root, "Detail_1")
    -- local trans = self.detail1.transform  
    -- self.dIcon = G(UITexture, trans, "Icon")
    -- self.dIconName= G(UILabel, trans, "Icon/Name")
    -- self.dDes = G(UILabel, trans, "Des")
    -- self.dCond = G(UILabel, trans, "Cond")
    -- S(trans, self.CloseDetail, self, nil, false)

    self.act2 = FG(root, "Act_2")
    self.content = F(root, "Act_2/Act_2")
    self.des2 = G(UILabel, root, "Act_2/Act_2/Des")
    self.actName = G(UILabel, root, "Act_2/Act_2/Name")
    -- self.actCam = FG(root, "Act_2/actCam")
    S(self.content, self.OpenDetail, self, nil, false)
    
    -- self.detail2 = FG(root, "Detail_2")
    -- self.deName = G(UILabel, root, "Detail_2/Name")
    -- local btn = FG(self.detail2.transform, "BtnClose")
    -- S(btn, self.CloseDetail, self, nil, false)

    self.dataiCam = FG(root, "Detail_2/modCam")
end

function M:SetLsnr(key)
    ActPreviewMgr.eUpdatePreview[key](ActPreviewMgr.eUpdatePreview, self.UpData, self)
    -- SceneMgr.eChangeEndEvent[key](SceneMgr.eChangeEndEvent, self.ChangeSceneEnd, self)
    ActPreviewMgr.eChgUI[key](ActPreviewMgr.eChgUI, self.ChgUI, self)
    ScreenMgr.eChange[key](ScreenMgr.eChange, self.ScreenChange, self)
end

function M:ScreenChange(orient, init)
    if orient == ScreenOrient.Right then
            UITool.SetLiuHaiAnchor(self.act1.transform, nil, nil, true,true)
            UITool.SetLiuHaiAnchor(self.content, nil, nil, true,true)
    elseif orient == ScreenOrient.Left then
        if not init then
            UITool.SetLiuHaiAnchor(self.act1.transform, nil, nil, true)
            UITool.SetLiuHaiAnchor(self.content, nil, nil, true)
        end
	end
end

function M:LoadTexture(texture)
    AssetMgr:Load(texture,ObjHandler(self.SetIcon, self))
end

function M:SetIcon(texture)
    AssetMgr:SetPersist(texture.name, ".png",true)
    self.actIcon.mainTexture = texture
    --self.dIcon.mainTexture = texture
    self:ClearCurActModel()  
    --self:ClearCurDetailModel()
end

function M:LoadModel(name1)
    aMgr.LoadPrefab(name1, GbjHandler(self.SetActModel,self))
    --aMgr.LoadPrefab(name2, GbjHandler(self.SetDetailModel,self))
end

function M:SetActModel(go)
    self:ClearCurActModel()  
    AssetMgr:SetPersist(go.name, ".prefab",true)
    self.curActModel = go
    go.transform:SetParent(self.content)
    go.transform.localPosition = Vector3(37,10,1000)
    go.transform.localScale = Vector3.one
end

-- function M:SetDetailModel(go)
--     self:ClearCurDetailModel()
--     AssetMgr:SetPersist(go.name, ".prefab",true)
--     self.curDetailModel = go
--     go.transform:SetParent(self.detail2.transform)
--     go.transform.localPosition =  self.detailPos
--     go.transform.localScale = self.DetailScale
-- end

function M:UpData()
    local data = ActPreviewMgr:GetCurData()
    if not data then
        self:Close()
        return
    end
    if self.curId and self.curId == data.id then
        return
    end
    self.curId = data.id
    local list = data.texture
    if not list then return end
    if #list > 1 then
        self.status = 1
        self:SwitchAct(false)
        local index = data.id
        --self.detailPos = self.DetailPos[index] or Vector3.zero
        --self.deName.text = self.ActName[index] or ""
        self.actName.text = self.ActName[index] or ""
        self:LoadModel(list[2])
        local str = data.trigType==1 and "等级开启" or "主线任务开启"
        self.des2.text = string.format("%s级%s", UIMisc.GetLv(data.level), str) 
    else
        self.status = 0
        self:SwitchAct(true) 
        self:LoadTexture(list[1])
        local str = data.trigType==1 and "等级开启" or "主线任务开启"
        self.des1.text = string.format("%s级%s", UIMisc.GetLv(data.level), str) 
        self.des12.text = data.des
        --self.dIconName.text = data.des
        --self.dDes.text = data.previewDes
        local str = data.trigType == 2 and "[40F214FF]完成主线任务[-]," or ""
        --self.dCond.text = string.format("%s[8A7F72FF]人物达到%s级开放[-]", str , UIMisc.GetLv(data.level))  
        self.actIcon:UpdateAnchors()
    end
end


function M:OpenDetail()
    if self.act1.activeSelf then
        --self.detail1:SetActive(true)
        UIFuncOpen:OpenTag(1)
        self.status = 0
    else
        self.act2:SetActive(false)
        --self.detail2:SetActive(true)
        UIFuncOpen:OpenTag(2)
        self:SetMenuState(false)
        self.status = 1
    end
end

function M:SwitchAct(bool)
    self.act1:SetActive(bool)
    self.act2:SetActive(not bool)
    self.dataiCam:SetActive(not bool)
    -- self.actCam:SetActive(not bool)
    -- self.detail2:SetActive(false)
end

-- function M:CloseDetail()
--     if self.detail2.activeSelf then
--         self.act2:SetActive(true)
--     end
--     self.detail1:SetActive(false)
--     self.detail2:SetActive(false)
--     self:SetMenuState(true)
-- end

function M:SetMenuState(state)
    local ui = UIMgr.Get(UIMainMenu.Name)
    if ui then
        ui.root.localPosition = state and Vector3.zero or Vector3(0,100000,0)
    end
end

function M:ClearCurActModel()
    if self.curActModel then
        AssetMgr:Unload(self.curActModel.name, ".prefab", false)
        Destroy(self.curActModel)
        self.curActModel = nil
    end
end

-- function M:ClearCurDetailModel()
--     if self.curDetailModel then
--         AssetMgr:Unload(self.curDetailModel.name, ".prefab", false)
--         Destroy(self.curDetailModel)
--         self.curDetailModel = nil
--     end
-- end

function M:Clear()
    self.curId = nil
    self.status = nil
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
end

return M