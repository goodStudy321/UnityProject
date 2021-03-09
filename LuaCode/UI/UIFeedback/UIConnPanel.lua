UIConnPanel = UIBase:New{Name = "UIConnPanel"}

local M = UIConnPanel
local ET = EventMgr.Trigger
local togs = {}
local US = UITool.SetLsnrClick

function M:InitCustom()
    local root = self.root
    local C = ComTool.Get
    local T = TransTool.FindChild
    local S =  UITool.SetLsnrSelf

    self.type = nil

    -- 提示警告
    self.tip1 = T(root,"tip1")
    self.tip2 = T(root,"tip2")
    self.tip3 = T(root,"tip3")
    self.tip4 = T(root,"tip4")

    -- 图片上传提示面板
    self.tip = T(root,"Tip")
    US(root, "Tip/Sprite", "", self.CloseTip, self)

    -- 提交按钮
    US(root, "subBtn", "", self.ClickToSub, self)
    -- 关闭按钮
    US(root, "closeBtn", "", self.ClickToClose, self)

    -- 添加图片按钮
    US(root, "Tex/addBTn", "", self.ClickToAdd, self)

    self.titleInput = C(UIInput,root,"titleInput",tip,false)
    self.msgInput = C(UIInput,root,"msgInput",tip,false)
    self.qqInput = C(UIInput,root,"qqInput",tip,false)
    self.telInput = C(UIInput,root,"telInput",tip,false)

    self.titleLb = C(UILabel,root,"titleInput/Label",tip,false)
    self.msgLb = C(UILabel,root,"msgInput/Label",tip,false)
    self.qqLb = C(UILabel,root,"qqInput/Label",tip,false)
    self.telLb = C(UILabel,root,"telInput/Label",tip,false)

    self.bg = T(root,"Tex/bg")
    self.tex = C(UITexture,root,"Tex/Tex",tip,false)

    for i=1, 5 do
        local tog = C(UIToggle,root,"type"..i,tip,false)
        S(tog.transform, self.OnTog, self)
        togs [#togs + 1] = tog
    end

    self:SetLsnr("Add")

    iTrace.sLog("HYN","this is a test 1")
end

function M:CloseTip()
    self:OpenTip(false)
end

function M:OpenTip(isOpen)
    self.tip:SetActive(isOpen)
end

function M:OpenCustom()
    self.isOpen = true
end

function M:CloseCustom()
    self.isOpen =  false
end

function M:SetLsnr(key)
    FeedbackMgr.eLoadTex[key](FeedbackMgr.eLoadTex, self.SetTex, self)
end

function M:ClickToAdd()
    MobileMedia.PickImage(function (imagePath)
       self:OpenTexCb(imagePath)
    end )
end

function M:OpenTexCb(imagePath)
    if not StrTool.IsNullOrEmpty(imagePath) then
       iTrace.Log(imagePath)
        local imageBytes = System.IO.File.ReadAllBytes(imagePath)
        local width = tonumber(Screen.width * 0.2)
        local height = tonumber(Screen.height * 0.2)
        local fmt = self:GetFormt()
        self.newTex = UnityEngine.Texture2D.New(width,height,fmt,false)
        self.newTex:LoadImage(imageBytes)
        self.loadImg = self.newTex:EncodeToPNG()
        ET("eSendTex")
    else
        iTrace.Log("Path is empty or null")
    end
end

function M:GetFormt()
    iTrace.sLog("HYN","this is a test 2, GetFormat")
    if App.platform == Platform.Android then
        iTrace.sLog("HYN","this is a test 3, GetFormat")
        return UnityEngine.TextureFormat.ETC2_RGBA8
    else
        iTrace.sLog("HYN","this is a test 4, GetFormat")
        return UnityEngine.TextureFormat.RGB24
    end
end

function M:SetTex()
    if self.isOpen == false then return end
    self.tex.mainTexture = self.newTex
    iTrace.sLog("HYN","设置TexSuc")
    self:OpenTip(false)
    UITip.Log("上传成功")
end

function M:OnTog(go)
    if go.name == "type1" then
        self.type = "1"
        self:ChangeChoose(1)
    elseif go.name == "type2" then
        self.type = "2"
        self:ChangeChoose(2)
    elseif go.name == "type3" then
        self.type = "3"
        self:ChangeChoose(3)
    elseif go.name == "type4" then
        self.type = "4"
        self:ChangeChoose(4)
    elseif go.name == "type5" then
        self.type = "5"
        self:ChangeChoose(5)
    end
end

function M:ChangeChoose(num)
    for i,v in ipairs(togs) do
        if i == num then
            v.value = true
        else
            v.value = false
        end
    end
end

function M:ClickToSub()
    local type = self.type
    local title =  self.titleInput.value
    local msg = self.msgInput.value
    local qq = self.qqInput.value
    local tel = self.telInput.value
    if not StrTool.IsNullOrEmpty(type)  then
        self.tip1:SetActive(false)
        if not StrTool.IsNullOrEmpty(title) then
            self.tip2:SetActive(false)
            if not StrTool.IsNullOrEmpty(msg) then
                self.tip3:SetActive(false)
                if not StrTool.IsNullOrEmpty(qq) or not StrTool.IsNullOrEmpty(tel) then
                    local data = {}
                    data.type = self.type
                    data.title = title
                    data.content = msg
                    data.qq = qq
                    data.tel = tel
                    FeedbackMgr:SetSubList(data)
                else
                    self.tip4.gameObject:SetActive(true)
                end
            else
                self.tip3:SetActive(true)
            end
        else
            self.tip2:SetActive(true)
        end
    else
        self.tip1:SetActive(true)
    end
end

function M:ClickToClose()
    self:Close()
end

function M:ResetTip()
    self.tip1:SetActive(false)
    self.tip2:SetActive(false)
    self.tip3:SetActive(false)
    self.tip4:SetActive(false)
end

function M:Clear()
    self:SetLsnr("Remove")
    local texName = FeedbackMgr.imgName
    Destroy(self.tex.gameObject)
	if self.newTex then
		Destroy(self.newTex)
    end
    self:ResetTip()
end


return M