MRecordIt=Super:New{Name="MRecordIt"} 
local My = MRecordIt

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.des = ComTool.GetSelf(UILabel,trans,name)
end

function My:SetActive(ac)
    self.Gbj:SetActive(ac)
end

function My:SetName(num)
    self.Gbj.name = num
end

function My:UpdateData(data)
    local typeDesTab = {"配对失败","配对成功","完美情缘"}  
    local name = data.role_name --角色名字
    local type = data.reward_type --奖励类型
    local rewId = data.type_id_list[1] --道具ID
    -- local tn , qtColor, itCfg = nil, nil, nil
    local sb = ObjPool.Get(StrBuffer)
    -- local LabColor = UIMisc.LabColor
    sb:Apd("[F4DDBDFF]")
    itCfg = ItemData[tostring(rewId)]
    -- qtColor = LabColor(itCfg.quality)
    sb:Apd("恭喜[00FF00]["):Apd(name):Apd("[-]]"):Apd("[E461DEFF]["):Apd(typeDesTab[type])
    sb:Apd("][-]获得道具"):Apd("[E461DEFF]["):Apd(itCfg.name):Apd("][-]")
    self.des.text = sb:ToStr()
    ObjPool.Add(sb)
end

function My:Dispose()
    TableTool.ClearUserData(self)
end