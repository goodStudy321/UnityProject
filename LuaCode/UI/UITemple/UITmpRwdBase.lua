UITmpRwdBase=Super:New{Name="UITmpRwdBase"}
local My = UITmpRwdBase

function  My:Init(root )
    self.root=root
    UITool.SetBtnClick(root,"btn/close",self.Name,self.close,self)
    self.my_family_info= TempleMgr.GetFmlInfo()
    self.memDic = self.my_family_info.memberName
    self.type=1
    self:InitCustom(root)
    self:my_SetActive(false) 
    self.mdRoot=  UITemple.modelRoot.gameObject
end


function My:open( )
    self:my_SetActive(true)
    self.rank=UITemple.rank
    self.mdRoot:SetActive(false)
    self:my_open()
    UITemple.barrier:SetActive(true)  
end
--子类继承实现
function My:InitCustom( root )
end

function My:my_open( )
end

--是否为自己的道庭返回bool
function My:isMyFamily(checkName)
    local fi = TempleMgr.GetFmlInfo()
    if fi.family_name==nil then
        return false
    end
    local b = false    
    if FamilyMgr.JoinFamily() and checkName == fi.family_name  then
            b=true
    end
    return b
end
--是否拥有分配权
function My:CanAllot ( )
    local canAllot = TempleMgr.GetFmlInfo().canAllot
    return canAllot
end
--改变板子状态方式
function My:my_SetActive( bool )
    self.root.gameObject:SetActive(bool)    
end

function My:close( )
   self:my_SetActive(false)
   if self.Name ~= "UIShowMember" then
    UIShowMember:my_SetActive(false)
    UITemple.barrier:SetActive(false)  
    self.mdRoot:SetActive(true)  
    UIStreakReward:ClearItem();
   end
end

function My:Clear( )
    self:doClear()
end
function My:doClear(  )
    
end
return My