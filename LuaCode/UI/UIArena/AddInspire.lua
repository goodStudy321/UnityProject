AddInspire = {Name = "AddInspire"}
local My = AddInspire;
My.desc = "是否花费20元宝进行鼓舞，增加5%战力?\n（鼓舞提升战力仅限当天结算前有效）";

--打开鼓舞提示
function My:Open(go)
    self.GO = go;
    self.GO:SetActive(true);
    local trans = go.transform;
    local name = trans.name;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    self.Desc = CG(UILabel,trans,"Desc",name,false);
    self.CurInspire = CG(UILabel,trans,"CurInspire",name,false);

    UC(trans,"Close",name,self.Close,self);
    UC(trans,"Cancel",name,self.Close,self);
    UC(trans,"InSpire",name,self.Inspire,self);

    self:SetContext();
end

--设置内容
function My:SetContext()
    self:SetDesc();
    self:SetInspireTimes();
end

--设置描述
function My:SetDesc()
    if self.Desc == nil then
        return;
    end
    local cost = GlobalTemp["67"].Value3;
    local addValPst = GlobalTemp["66"].Value3;
    addValPst = tostring(addValPst)
    local bufCfg = BuffTemp[addValPst]
    if bufCfg == nil then
        iTrace.eError("GS","buff配置表中不存在id:",addValPst)
    end
    local propKey = bufCfg.valueList[1].k
    local propCfg = PropName[propKey]
    local propName = propCfg.name
    local propVal = bufCfg.valueList[1].v
    if propCfg.show == 1 then
        propVal = 0.01 * propVal
    end
    local text = string.gsub(My.desc,"20",cost);
    text = string.gsub(text,"5",propVal);
    text = string.gsub(text,"战力",propName);
    self.Desc.text = text;
end

--设置鼓舞次数
function My:SetInspireTimes()
    if self.CurInspire == nil then
        return;
    end
    local maxInspire = GlobalTemp["68"].Value3;
    local curTimes = Droiyan.InspireNum;
    local text = string.format("%s/%s",curTimes,maxInspire);
    self.CurInspire.text = text;
end

--鼓舞
function My:Inspire(go)
    local maxInspire = GlobalTemp["68"].Value3;
    local curInspire = Droiyan.InspireNum;
    if curInspire >= maxInspire then
        UITip.Log("已达到今天鼓舞次数上限");
        return;
    end
    local cost = GlobalTemp["67"].Value3;
    if cost > RoleAssets.Gold then
        UITip.Log("元宝不足！");
        return;
    end
    Droiyan.ReqInspire();
end

--取消或关闭
function My:Close(go)
    if go == nil then
        return;
    end
    self.GO:SetActive(false);
end