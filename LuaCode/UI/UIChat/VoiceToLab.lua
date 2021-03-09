--[[
语音转文字
]]

VoiceToLab=Super:New{Name="VoiceToLab"}
local My = VoiceToLab
My.info=nil

function My:Init(go)
    self.go=go
    local trans = go.transform
    
    UITool.SetBtnSelf(go,self.OnClickToLab,self,self.Name)
    UITool.SetLsnrClick(trans,"Mask",self.Name,self.Close,self)

end

function My:SetPos()
    self.go.transform.position=My.info.trans.position
    local pos = self.go.transform.localPosition
    local x = -130
    local y = -28
    if My.info.isself==false then
        x=153
    end
    self.go.transform.localPosition=Vector3.New(pos.x+x,pos.y+y,0)
end

function My:OnToGetLab(text)
    iTrace.Log("xiaoyu","结束录音语音识别返回")
    if StrTool.IsNullOrEmpty(text) then UITip.Log("转文字失败")return end
    
end

--语音转文字
function My:OnClickToLab()
    UITip.Log("语音转文字")
    self:Close()
    My.info:OnVoiceToLab()
end

function My:Open()
    self.go:SetActive(true)
    self:SetPos()
end

function My:Close()
    self.go:SetActive(false)
end

function My:Dispose()
    
end