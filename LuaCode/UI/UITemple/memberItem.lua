memberItem=Super:New{Name="memberItem"}
local My = memberItem

function My:init( go,name )
    local CG = ComTool.Get
    self.go=go
    self.name=name    
    self.btnlbl=CG(UILabel,go.transform,"lbl")
    self.btnlbl.text=name
    UITool.SetBtnSelf(self.go.transform,self.onCick,self)
end
function My:onCick()
    MsgBox.ShowYesNo(string.format( "是否把道具分配给成员%s？",self.name),
     self.YesCb,self, "确定", self.NoCb,self,"取消")
end
--创建type==0时候为终结type==1时候为连胜
function My:YesCb( )
    self.type=UIShowMember.type
    if  self.type==1 then
       UIStreakReward:send(self.name,UIShowMember.btnId)
    elseif  self.type==0 then
        UIShutReward:send(self.name)
    end
end


function My:NoCb( )
    return
end

return My