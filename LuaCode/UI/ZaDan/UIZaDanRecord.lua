--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/9/10 上午10:34:45
--=============================================================================


UIZaDanRecord = Super:New{ Name = "UIZaDanRecord" }

local My = UIZaDanRecord


----BEG PUBLIC

function My:Init(root)
    self.go = root.gameObject
    local des =  self.Name
    local USBC ,CG= UITool.SetBtnClick,ComTool.Get
    local bg = TransTool.Find(root, "bg", des)

    USBC(bg, "closeBtn", des, self.Close, self)

    self.highDes = CG(UILabel, bg, "rare/des", des)
    self.normDes = CG(UILabel, bg, "all/des", des)

    self:SetRecord(ZaDanMgr.highLogs, ZaDanMgr.normLogs)
end

----END PUBLIC

function My:SetActive(at)
    self.go:SetActive(at)
end

function My:Open()
    self:SetActive(true)
    local highGo = self.highDes.gameObject
    local normGo = self.normDes.gameObject
    highGo:SetActive(false)
    highGo:SetActive(true)
    normGo:SetActive(false)
    normGo:SetActive(true)

end

function My:Close()
    self:SetActive(false)
end

function My:SetRecord(highLogs, normLogs)
    self:SetLogs(highLogs, self.highDes, 5)
    self:SetLogs(normLogs, self.normDes, 30)
end


function My:SetLogs(lst, label, max)
    local tn , qtColor, itCfg = nil, nil, nil
    local sb = ObjPool.Get(StrBuffer)
    local LabColor = UIMisc.LabColor
    local danColor , danColors= nil, UIZaDan.colors
    sb:Apd("[F4DDBD]")
    for i,v in ipairs(lst) do
        if i > max then break end
        tn = UIZaDan:GetDanDes(v.et)
        itCfg = ItemData[tostring(v.itID)]
        qtColor = LabColor(itCfg.quality)
        danColor = danColors[v.et]
        sb:Apd("恭喜[00FF00]"):Apd(v.name):Apd("[-]砸"):Apd(danColor):Apd(tn)
        sb:Apd("[-]获得极品"):Apd(qtColor):Apd(itCfg.name):Apd("[-]\n")
    end
    label.text = sb:ToStr()
    ObjPool.Add(sb)
end


function My:Dispose()

end


return My