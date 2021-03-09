--[[
语音聊天
]]

UISendVoice=UIBase:New{Name="UISendVoice"}
local My = UISendVoice

function My:InitCustom()
    if not self.voiceList then self.voiceList={} end
    local trans = self.root
    local CG = ComTool.Get
	local TF = TransTool.FindChild
    self.Send=TF(trans,"Send")
    self.Cancel=TF(trans,"Cancel")
    local v1 = TF(trans,"Send/v1")
    self.voiceList[1]=v1
    local vv = v1.transform
    for i=2,7 do
        local v = TF(vv,"v"..i)
        self.voiceList[i]=v
    end
    self.index=2
end

function My:Update()
    if UnityEngine.Input.GetAxis("Mouse Y")>0.3 and self.isSendVoice==true then 
        self:IsCancel(true)
        self:IsSend(false)
    end

    if not self.sendActive then return end
    if self.index==#self.voiceList then
         self.index=2 
        for i,v in ipairs(self.voiceList) do
            if i>1 then v:SetActive(false) end
        end
        return 
    end
   local go = self.voiceList[self.index]
   go:SetActive(true)
   self.index=self.index+1
end

function My:IsSend(state)
    self.sendActive=state
    self.Send:SetActive(state)
end

function My:IsCancel(state)
    self.Cancel:SetActive(state)
end

function My:OpenCustom()
    self.isSendVoice=true
    self:IsSend(true)
end

-- function My:CloseCustom()
--     self:IsSend(false)
--     self:IsCancel(false)
-- end

function My:DisposeCustom()
    self.isSendVoice=nil
    if self.voiceList then ListTool.Clear(self.voiceList) end
end

return My


