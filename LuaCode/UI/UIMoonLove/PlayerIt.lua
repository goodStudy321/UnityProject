PlayerIt=Super:New{Name="PlayerIt"}
local My = PlayerIt


function My:InitLoadIt(go,paTrans)
    local go = Instantiate(go)
    local trans = go.transform
    self.gbj = go.gameObject
    self:SetActive(true)
    TransTool.AddChild(paTrans.transform,trans)
    trans.localPosition = Vector3.zero
    trans.localScale = Vector3.one
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local des = self.Name
    self.sp=CG(UISprite,trans,"sp",des,false)
    self.lab=CG(UILabel,trans,"lab",des,false)
end

--index1:1 男     2 女    
--index2:   1      2      3       4 
function My:RefreshData(index1,index2)
    local spTab = nil
    local boySpTab = {"boy_01","boy_02","boy_03","boy_04"}
    local girlSpTab = {"girl_01","girl_02","girl_03","girl_04"}
    if index1 == 1 then
        spTab = boySpTab
    elseif index1 == 2 then
        spTab = girlSpTab
    end
    local labTab = {"天作之合","两小无猜","一见钟情","白头偕老"}
    self.sp.spriteName = spTab[index2]
    self.lab.text = labTab[index2]
end

function My:SetActive(ac)
    self.gbj:SetActive(ac)
end

function My:Dispose( ... )
    
end