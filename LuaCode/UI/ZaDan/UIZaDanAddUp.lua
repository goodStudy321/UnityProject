--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/9/10 上午10:34:24
--=============================================================================


UIZaDanAddUp = Super:New{ Name = "UIZaDanAddUp" }
require("UI/ZaDan/UIZaDanAddUpIt")

local My = UIZaDanAddUp


----BEG PUBLIC

function My:Init(root)
    local des = self.Name
    local CG= ComTool.Get
    local TFC= TransTool.FindChild
    local itGo = TFC(root, "it", des)
    itGo:SetActive(false)
    self.uiTbl = CG(UITable, root, "tbl", des)
    if self.CompareFunc == nil then 
        self.CompareFunc = function(lhs, rhs) return self:Compare(lhs, rhs) end
    end
    self.uiTbl.onCustomSort = self.CompareFunc 
    self:SetItems(itGo)

end

function My:Compare(lhs, rhs)
    local dic = self.itDic
    local lk, rk = lhs.name, rhs.name
    local getDic = ZaDanMgr.getDic
    local lget, rget = (getDic[lk] or 1), (getDic[rk] or 1)
    if lget == 3 then
        return (1)
    elseif rget == 3 then
        return (-1)
    end
    local lid, rid = tonumber(lk), tonumber(rk)
    --iTrace.Error("loong","lid:", lid, ", rid:", rid, ", lget:", lget, ", rget:", rget,",rk:",rk,",lk:",lk)
    if lid < rid then
        return (-1)
    elseif lid > rid then
        return 1
    end
    return 0
end

----END PUBLIC

function My:SetItems(modGo)
    if self.items == nil then 
        --条目:UIZaDanAddUpIt
        self.items = {}
        --k:奖励ID,v:UIZaDanAddUpIt 
        self.itDic = {}
    end
    local its, dic = self.items, self.itDic
    local tbl = self.uiTbl
    local p, c , k  = tbl.transform
    local cfgs = ZaDanAddUpCfg
    local num= nil
    local tnum = ZaDanMgr:GetConfigNum()
    local addChild = TransTool.AddChild
    for i, v in ipairs(cfgs) do
        num = v.num
        if tnum == num then
            local it = ObjPool.Get(UIZaDanAddUpIt)
            local go = Instantiate(modGo)
            go:SetActive(true)
            c = go.transform
            k = tostring(v.id)
            go.name = k
            addChild(p, c)
            it:Init(c, v)
            its[#its+1] = it
            dic[k] = it
        end
    end
    tbl:Reposition()
end

function My:RespGet(msg)
    local k = tostring(msg.id)
    local it = self.itDic[k]
    it:SetState(3)
    self.uiTbl:Reposition()
end

function My:SetStateByTime(tm, max)
    for i, v in ipairs(self.items) do
        v:SetStateByTime(tm, max)
    end
end

function My:Dispose()
    TableTool.ClearDic(self.itDic)
    ListTool.ClearToPool(self.items)
end


return My