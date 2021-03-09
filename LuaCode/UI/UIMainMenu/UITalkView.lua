--[[
主界面聊天
--]]
require("UI/UIChat/EmoInfo")
UITalkView=Super:New{Name="UITalkView"}
local My = UITalkView
local str = ObjPool.Get(StrBuffer)

function My:Ctor()
    self.list={}  --最多显示10条
    self.recordList={}
end

function My:Init(go)
    self.trans=go.transform
    self.CG=ComTool.Get
    local TF=TransTool.FindChild 

    self.Tab=self.CG(UITable,self.trans,"Sprite/Panel/Table",self.Name,false)
    self.back=TF(self.trans,"Sprite").transform
    self.pre=TF(self.back,"cell")
    self.emoPre=TF(self.back,"emo")

    self:AddE() --不清理事件，主界面只初始化一次

end

function My:AddE()
    ChatMgr.eAddChat:Add(self.AddChat,self)
    ChatMgr.eSys:Add(self.AddSys,self)
    ChatMgr.eRecord:Add(self.OnRecordChat,self)
end

function My:OnRecordChat()
    local daoting = ChatMgr.MsgDic["2"]
    if daoting then
        for i,v in ipairs(daoting) do
            v.tp=2
            table.insert( self.recordList, v)
        end
    end
    local shijie = ChatMgr.MsgDic["1"]
    if shijie then
        for i,v in ipairs(shijie) do
            v.tp=1
            table.insert( self.recordList, v)
        end
    end
    if #self.recordList>1 then 
        table.sort(self.recordList,function(a,b) return a.time < b.time end)
    end

    local count = #self.recordList>10 and #self.recordList-10 or 1
    if count==0 then return end
    for i=count,#self.recordList do
        local data = self.recordList[i]
        self:AddChat(data.tp,nil,data)
    end
end

function My:AddChat(tp,count,tb)
    if tp==4 then return end --忽略私聊
    if not tb.info then return end --忽略各自频道的系统消息
    if ChatMgr.tpDic[tostring(tp)]==true then 
        str:Dispose()
        local name = tb.info.rN
        local msg = ""
        if tb.voice==nil or tb.voice==0 then msg=tb.msg end
        local server = tb.info.server
        if StrTool.IsNullOrEmpty(server) then 
            str:Apd("　　　  [67cc67]"):Apd(name):Apd(":[-]  "):Apd(msg) 
        else           
            str:Apd("　　　  [67cc67][CC2500FF]"):Apd(server):Apd("[-]"):Apd(name):Apd(":[-]  "):Apd(msg)
        end
        
        self:CreateChat(str:ToStr(),tp,tb.voice)
    end
end

function My:AddSys(tp,index,ismain)
    if ismain==false then return end
    if ChatMgr.tpDic[tostring(tp)]==true then 
        local msg = nil
        if tp==0 then
            msg=ChatMgr.SysList[index].k
        elseif tp==5 then 
            msg=ChatMgr.TeamList[index]
        end
        self:CreateChat("　　　  "..msg,tp)
    end
end

function My:CreateChat(msg,tp,voice,server)
    local cell=nil
    if #self.list>=10 then
        cell = self.list[1]
        cell. go.transform.parent=nil
        cell. go.transform.parent=self.Tab.transform
        cell. go.transform.localPosition=Vector3.zero
        cell. go.transform.localScale=Vector3.one

        cell:Clean()
        table.remove( self.list,1)
    else
        local go=GameObject.Instantiate(self.pre)       
        go:SetActive(true)

        go.transform.parent=self.Tab.transform
        go.transform.localPosition=Vector3.zero
        go.transform.localScale=Vector3.one

        cell = ObjPool.Get(EmoInfo)
        cell:Init(go,self.emoPre)

        go.name=#self.list 
    end
    self.list[#self.list+1]=cell
    cell.go.name=tostring(tp)
    cell:InitData(tp,msg,voice)

    self.Tab.repositionNow=true
end

function My:Dispose()
    TableTool.ClearDicToPool(self.recordList)
    TableTool.ClearDicToPool(self.list)
    if self.timer then self.timer:Stop() self.timer:AutoToPool() end
end