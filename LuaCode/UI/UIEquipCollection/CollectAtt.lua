--[[

]]
CollectAtt=Super:New{Name="CollectAtt"}
local My = CollectAtt

function My:Init(go)
    if not self.str1 then self.str1=ObjPool.Get(StrBuffer) end
    if not self.str2 then self.str2=ObjPool.Get(StrBuffer) end
    self.go=go
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local trans = go.transform

    self.lab = CG(UILabel,trans,"Label",self.Name,false)
    self.t=CG(UISprite,trans,"t",self.Name,false)
    self.red=TF(trans,"red")
    self.Tween=TF(trans,"Tween")
    self.lab1 = CG(UILabel,trans,"Tween/lab1",self.Name,false)
    self.lab2 = CG(UILabel,trans,"Tween/lab2",self.Name,false)

    self.playTween=CG(TweenScale,trans,"Tween",self.Name,false)

    self.OnPlayTweenCallback = EventDelegate.Callback(self.OnClick, self)
    EventDelegate.Add(self.playTween.onFinished, self.OnPlayTweenCallback)
    self.isClick=false
end

function My:UpData(num,att,color)
    self.lab.text=tostring(num).."件套属性"
    self.str1:Dispose()
    self.str2:Dispose()
    for i,v in ipairs(att) do
        local x,xx = math.modf(i/2)
        local str = xx==0 and self.str2 or self.str1
        if StrTool.IsNullOrEmpty(str:ToStr())~=true then 
            str:Line() 
        else
            str:Apd(color)
        end
        str:Apd(PropTool.GetNameById(v.id)):Apd("  "):Apd(PropTool.GetValByID(v.id,v.value))
    end
    self.lab1.text=self.str1:ToStr()
    self.lab2.text=self.str2:ToStr()
end

function My:TweenState(isActive)
    self.Tween:SetActive(isActive)
    local path = isActive==true and "ty_11" or "ty_13"
    self.t.spriteName=path
end

function My:OnClick()
    if self.isClick==true then 
        self:TweenState(false)
        self.isClick=false
    else
        self:TweenState(true)
        self.isClick=true
    end
end

function My:ShowRed(isred)
    self.red:SetActive(isred)
end

function My:Dispose()
    if not self.str1 then ObjPool.Add(self.str1) self.str1=nil end
    if not self.str2 then ObjPool.Add(self.str1) self.str2=nil end
    Destroy(self.go)
end