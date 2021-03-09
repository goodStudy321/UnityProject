FeedbackMgr = Super:New{Name="FeedbackMgr"}

local M = FeedbackMgr

local ET = EventMgr.Trigger

M.eOpenYes = Event()
M.eONewData = Event()
M.eReSet =  Event()
M.eClose = Event()
local dic={}

function M:Init()
    --意见反馈提交
    self.add1 = ObjPool.Get(StrBuffer)
    self.add1:Apd(App.BSUrl):Apd("index/Feedback/FeedbackSubmit")
    self.url1 = self.add1:ToStr()
   
    --意见反馈列表
    self.add2 = ObjPool.Get(StrBuffer)
    self.add2:Apd(App.BSUrl):Apd("index/Feedback/FeedbackList")
    self.url2 = self.add2:ToStr()

    --意见反馈开关
    self.add3 = ObjPool.Get(StrBuffer)
    self.add3:Apd(App.BSUrl):Apd("index/Feedback/FeedbackSwitch")
    self.url3 = self.add3:ToStr()

    --意见反馈开关
    self.add4 = ObjPool.Get(StrBuffer)
    self.add4:Apd(App.BSUrl):Apd("index/Feedback/FeedbackUpload")
    self.url4 = self.add4:ToStr()

    self.text = ""

    self.err1 = nil
    self.err2 = nil
    self.isOpen = true

    -- 提交信息返回列表
    self.data = {}
    self.eLoadTex = Event()
    EventMgr.Add("eSendTex",EventHandler(self.SendFileTex,self))
end

-- 设置数据
function M:SetSubList(list)
    self.subList = list
    self:SendMsg()
end

-- 获得数据
function M:GetSubList()
    return self.subList
end

function M:GetSelfList()
    return self.data
end

--==============================--


function M:Check()
    if App.isEditor == true then return false end
    do return true end
end

function M:Upload(fn, path, tip)
    --if self:Check() == false then return end
    local func = self[fn]
    if(type(func) ~= "function") then
        iTrace.Error("Loong", self.Name, " no function name:", fn)
        return
    end
    local fm = WWWForm.New()
    func(self, fm)
    local www = UnityWebRequest.Post(path, fm)
    www:SendWebRequest()
    coroutine.www(www)
    local err = www.error
    if StrTool.IsNullOrEmpty(err) then
        local text = www.downloadHandler.text
        for i=1,4 do
            local state = dic[tostring(i)]
            if state == true then
                if i == 1 then
                    local list = json.decode(text)
                    local err = list.status.code
                    local errMsg = list.status.msg
                    if err ~= 10200 then
                        UITip.Log(errMsg)
                    else
                        MsgBox.ShowYesNo("您的意见反馈已经提交",self.yesCb)
                    end
                elseif i == 2 then
                    self:WWWCb(text)
                elseif i == 3 then
                    self:StatusCB(text)
                else
                    local list = json.decode(text)
                    local err = list.status.code
                    errMsg = list.status.msg
                    if err == 10200 then
                        self.url = list.data[1]
						iTrace.Log("hyn","eLoadWWWTex:",self.url)
                        self.eLoadTex()
                    else
                        local ui=UIMgr.Get(UIConnPanel.Name)
                        if ui then
                            ui:OpenTip(false)
                        end
                        UITip.Log(errMsg)
                    end
                end
                dic[tostring(i)] = false
                break
            end
        end
    else
        UITip.Log(err)
    end
    www:Dispose()
end

function M:yesCb()
    UIMgr.Close(UIConnPanel.Name)
    M:SendId()
end

function M:WWWCb(msg)
    local datalist = json.decode(msg)
    local data = datalist.data
    local err = datalist.status.code
    local errMsg = datalist.status.msg
    if data == nil or #data == 0 then
        return
    end
    if err ~= 10200 then
        UITip.Log(errMsg)
    else
        self.data = {}
        for i,v in ipairs(data) do
            local sData = {}
            sData.num = v.number
            sData.type = v.feedback_type
            sData.title = v.title
            sData.time = v.add_time
            sData.status = v.status
            sData.content = v.content
            sData.reply = v.reply
            self.data[#self.data + 1] = sData
        end
        self.eONewData()
    end
end

function M:StatusCB(msg)
    local statusList = json.decode(msg)
    local status = statusList.data
    local err = statusList.status.code
    local errMsg = statusList.status.msg
    if err ~= 10200 then
        UITip.Log(err)
    else
        if status == "" then
            self.isOpen = false
            self.eClose()
        end
    end
end
--==============================--

function M:SendMsg()
    dic["1"] = true
    coroutine.start(self.Upload, self, "SetAll", self.url1)
end

function M:SendId()
    dic["2"] = true
    coroutine.start(self.Upload, self, "SetId", self.url2)
end

function M:SendStatus()
    dic["3"] = true
    coroutine.start(self.Upload, self, "SetStatus", self.url3)
end

function M:SendFileTex()
    dic["4"] = true
    coroutine.start(self.Upload, self, "SetTex", self.url4)
end

--==============================--

function M:SetTex(fm)
    local img = UIConnPanel.loadImg
    local now = TimeTool.GetServerTimeNow()*0.001
    local roldId = User.MapData.UID
    self.imgName = "fb_"..tostring(roldId)..now..".png"
    fm:AddBinaryData("image",img,self.imgName,"image/png")
    local ui=UIMgr.Get(UIConnPanel.Name)
    if ui then
        ui:OpenTip(true)
    end
end

function M:SetId(fm)
    fm:AddField("role_id", tostring(User.MapData.UID))
end

function M:SetAll(fm)
    local subList = self:GetSubList()
    fm:AddField("role_id", tostring(User.MapData.UID))
    fm:AddField("feedback_type", subList.type)
    fm:AddField("title", subList.title)
    fm:AddField("content", subList.content)
    fm:AddField("qq_number",subList.qq)
    fm:AddField("tel_number", subList.tel)
    local url = self.url or ""
    fm:AddField("pic_url", url)
end

function M:SetStatus(fm)
    local gameChanelId = UserMgr:GetGameChannelID()
    fm:AddField("game_channel_id",tostring(gameChanelId))
end

--==============================--

function M:Clear()
    self.status = nil
    ObjPool.Add(self.add1)
    self.add1 = nil
    ObjPool.Add(self.add2)
    self.add2 = nil
    ObjPool.Add(self.add3)
    self.add3 = nil
    ObjPool.Add(self.add4)
    self.add4 = nil
    self.url = ""
    self.isOpen = true
end

return M