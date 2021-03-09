StateExpProp = Super:New{Name = "StateExpProp"}
local My = StateExpProp

function My:Init(go)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local UC = UITool.SetLsnrClick
    local US = UITool.SetLsnrSelf

    self.curLab = CG(UILabel,root,"curLab",name)
    self.nextLab = CG(UILabel,root,"nextLab",name)
end

function My:SetActive(ac)
    self.Gbj.gameObject:SetActive(ac)
end

--{des = "当前战灵：",cur = 0,next = 0,des2 = "万",add = "+",flag = "%"}
function My:SetCurPLab(data,index)
    local des1 = ""
    local des2 = ""
    if index == 4 or index == 6 then
        des1 = string.format("[F4DDBD]%s[-][F9AB47]%s%s%s[-]",data.des,data.add,data.cur,data.flag)
        des2 = string.format("[00FF00]%s%s%s[-]",data.add,data.next,data.flag)
    else
        des1 = string.format("[F4DDBD]%s[-][F9AB47]%s%s[-]",data.des,data.cur,data.des2)
        des2 = string.format("[00FF00]%s%s[-]",data.next,data.des2)
    end
    self.curLab.text = des1
    self.nextLab.text = des2
end

function My:Dispose()
    TableTool.ClearUserData(self)
end