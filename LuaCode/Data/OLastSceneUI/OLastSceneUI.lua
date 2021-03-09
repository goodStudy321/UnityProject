OLastSceneUI = {Name = "OLastSceneUI"}
local My = OLastSceneUI;
local needSceneId = nil
local isNeedOpenUI = false

My.OpenOEvent = Event()

function My:Init()
    EventMgr.Add("OnChangeScene", EventHandler(self.OpenEnterUI, self))
end

function My:OpenEnterUI(sceneId)
    JumpMgr:Clear()
    if isNeedOpenUI == true then
        self:OpenNeedUI()
    end

    local exitSceneId = tostring(sceneId)
    local sceneTemp = SceneTemp[exitSceneId]
    local openUITab = sceneTemp.enterUI
    if  openUITab ~= nil then
        isNeedOpenUI = true
        needSceneId = exitSceneId
    end
end

function My:OpenNeedUI()
    local sceneTemp = SceneTemp[needSceneId]
    local openUITab = sceneTemp.enterUI
    local uId = openUITab[1]
    local uFlag = openUITab[2]
    if uId == nil then
        iTrace.eError("GS","要打开的界面配置为空，请检查场景设置表，场景id为：",needSceneId)
        return
    end
    uId = tostring(uId)
    local openUICfg = ESOUICfg[uId]
    local uiName = openUICfg.tn
    if uiName == "UIArena" and uFlag == 2 then
        UIArena.OpenArena(2)
    elseif uiName == "UIArena" and uFlag == 1 then
        UIArena.OpenArena(1)
    elseif uiName == "UIRobbery" then
        if uFlag == 1 then --渡劫成功弹出面板
            local robberyState = RobberyMgr.RobberyState
            if robberyState == 2 then --渡劫失败
                return
            end
            -- UIRobberyTip:OpenRobberyTip(1)
            UIRobbery:OpenRobbery(1)
        elseif uFlag > 1 then
            UIRobbery:OpenRobbery(uFlag)
            self.OpenOEvent()
        end
    end
    isNeedOpenUI = false
end

function My:Clear()
    isNeedOpenUI = false
end

function My:Dispose()
    self:Clear();
end

return My