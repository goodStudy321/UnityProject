--[[
角色基本信息
--]]
RoleTb=Super:New{Name="RoleTb"}
local My=RoleTb

function My:Ctor()
    self.skinList={}
end

--角色id,名字，等级，性别，职业
function My:Init(roleId,name,lv,sex,cate,skinList)
    self.roleId=tostring(roleId)
    self.name=name
    self.lv=lv
    self.sex=sex
    self.cate=cate
    if(skinList.Count>0)then
        for i=0,skinList.Count-1 do
            self.skinList[i+1]=skinList[i]
        end
    end
end

function My:Dispose()
    self.roleId=nil
    self.name=nil
    self.lv=nil
    self.sex=nil
    self.cate=nil
    ListTool.Clear(self.skinList)
end