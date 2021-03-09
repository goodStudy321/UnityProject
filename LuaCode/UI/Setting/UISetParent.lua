UISetParent = Super:New{Name = "UISetParent"}
local My = UISetParent
My.SM = SettingMgr

-- 保存UIToggle类型UI
-- 主要保存bool类型做判断的ui是否被改变
-- 调用使用字段AllUtList或NVDic
function My:AddAllUt(root)
    local mlist = root:GetComponentsInChildren(typeof(UIToggle))
    local list = {}
    local NV={}
    local len=mlist.Length-1
    for k=0,len do
        local v=mlist[k]
        list[k+1]=v
        NV[v.name]=v
    end
    return list,NV
  end
--传入名称和值
function My:OnSave()
    UISetting:CloseAndSave()
end

--传入类型为type的list,限定bool返回
function My:ShowInfo(tyLst)
    for i=1,#tyLst do
        local ty = tyLst[i]
        local b = self.SM.GetValueFast(ty.name)
        if b=="无此数据" then
            b=false
        end
        ty.value=b
    end
end

return My