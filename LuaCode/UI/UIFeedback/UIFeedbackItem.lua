UIFeedbackItem = Super:New{Name = "UIFeedbackItem"}
local M = UIFeedbackItem

local C = ComTool.Get
local T = TransTool.FindChild

local ET = EventMgr.Trigger

function M:Init(obj)
    self.obj = obj
    self.objTrans = self.obj.transform
    -- 条目
    self.num = C(UILabel,self.objTrans,"Base/numLb",tip,false)
    self.type = C(UILabel,self.objTrans,"Base/typeLb",tip,false)
    self.title = C(UILabel,self.objTrans,"Base/titleLb",tip,false)
    self.time = C(UILabel,self.objTrans,"Base/timeLb",tip,false)
    self.state = C(UILabel,self.objTrans,"Base/stateLb",tip,false)

    self.revice = C(UILabel,self.objTrans,"Msg/revice",tip,false)
    self.details = C(UILabel,self.objTrans,"Msg/details",tip,false)

    self.msg = T(self.objTrans,"Msg")
    self.selSign = T(self.objTrans,"SelSign")

    self.isShowMsg = false

    UITool.SetLsnrClick(self.objTrans,"Base","",self.ClickToSelf, self)
end

function M:InitAndLink(data,selCB)
    self.data = data
    self.selCallBack = selCB
    self.num.text = self.data.num
    self.type.text = self.data.type
    self.title.text = self.data.title
    self.time.text = self.data.time
    if self.data.status == "已解决" then
        self.state.text = "[F39800]"..self.data.status.."[-]"
    else
        self.state.text = "[00FF00]"..self.data.status.."[-]"
    end
    if StrTool.IsNullOrEmpty(self.data.reply) then
        self.revice.text = "亲爱的玩家您好，您提出的问题，小汐妹还在努力的帮您解决，请您耐心等候哦，成功解决后将会通过邮件给您反馈结果，感谢您的支持！"
    else
        self.revice.text = self.data.reply
    end
    self.details.text = string.gsub( self.data.content,"\n"," " )
end

function M:ClickToSelf()
    if self.isShowMsg == false then
        self:ShowMsg(true)
        self.isShowMsg = true
    else
        self:ShowMsg(false)
        self.isShowMsg = false
    end
    FeedbackMgr.eReSet()
    if self.selCallBack ~= nil then
		self.selCallBack()
    end
end

function M:ShowMsg(isShow)
    self.msg:SetActive(isShow)
end

function M:Show(isShow)
    self.obj:SetActive(isShow)
end

function M:SelSign(isSel)
    self.selSign:SetActive(isSel)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.selCallBack = nil
    self.isShowMsg = nil
    self.data = nil
end

return M