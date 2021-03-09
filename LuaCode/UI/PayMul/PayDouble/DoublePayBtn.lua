DoublePayBtn = Super:New{Name = "DoublePayBtn"}
local My = DoublePayBtn

function My:Init(obj)
    self.Gbj = obj.gameObject
    local trans = obj.transform
    local name = trans.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local US = UITool.SetLsnrSelf
    self.chargeLab = CG(UILabel,trans,"lab",name)
    self.getLab = CG(UILabel,trans,"lab2",name)
end

function My:BtnAct(ac)
    self.Gbj:SetActive(ac)
end

function My:UpdateData(data)
	local double = GlobalTemp["179"].Value2[4]
	local data = data
	self.Gbj.name = data.id
	local chargeNum = data.gold
	local getNum = data.getGold
	getNum = getNum * double
    self.chargeLab.text = string.format("充值￥%s",chargeNum)
    self.getLab.text = string.format("获得%s元宝",getNum)
end

function My:Dispose()
    TableTool.ClearUserData(self)
end