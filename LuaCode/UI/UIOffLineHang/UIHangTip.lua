
UIHangTip={Name="UIHangTip"}
local My=UIHangTip
local prv = {}
function My:Init(root)
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local infoRoot=TF(root,"back/info").transform
    local UL = UILabel
    local tip = My.Name
    self.go=root.gameObject
    self.lvl=CG(UL,infoRoot,"lvl",tip)
    self.def=CG(UL,infoRoot,"def",tip)
    self.msg=CG(UL,infoRoot,"msg",tip)
    self.box=CG(UIWidget,root,"box",tip)
    self.go:SetActive(false)
    UIEvent.Get(self.box.gameObject).onPress=function(gameObject,boolean) self:close() end
end
--创建tip传入位置,和一个WildMapTemp表里string类型的顺序ID
function My.CreatTip(vec,ID)
    My.id=ID
    local m_vec =vec
    m_vec.x=5
    m_vec.y=vec.y-50
    My.go.transform.localPosition=m_vec
    My.go:SetActive(true)
    My:show()
end
--展示
function My:show( )
   local info = WildMapTemp [My.id]
   if info==nil then
    iTrace.Error("soon","请传入怪物id,此id为:"..My.id)
   end
   self.lvl.text=info.minLvl
   self.def.text=info.def
   self.msg.text=info.hgMsg
   if info.hgMsg == "" then
       self:close()
   end
end

--关闭
function My:close(gameObject,bool )
    if self.go.activeSelf==true then
        self.go:SetActive(false)
        self.go.transform.localPosition=Vector3.zero
    end
end
