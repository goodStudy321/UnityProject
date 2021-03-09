UIShowMember=UITmpRwdBase:New{Name="UIShowMember"}
local My =  UIShowMember
function  My:InitCustom(root)
    local CG = ComTool.Get
    local tip = self.Name
    self.grid=TransTool.Find(root,"sv/Grid",tip)
    self.item=CG(UIButton,self.grid,"item",tip)
    self.Items={}
    self.memDic = self.my_family_info.memberName
    self.go = self.item.gameObject
    self.go.name="bhfp"
    for k,v in pairs(self.memDic) do
    self:Create(k)
    end
    self.item.gameObject:SetActive(false)
end

function My:my_open(  )
    
end
--设置type
function My:setType( num )
    self.type=num
end
--获取格子的id
function My:setWinTimes( id )
    self.btnId=id
end
--创建格子
function My:Create(k)
    local go =  GbjPool:Get(self.go.name)
    if go==nil then
        local go = self.item.gameObject
            local g = UnityEngine.GameObject.Instantiate(go)
            g.name=self.go.name
            My:AddItem(k,g)
    else 
            self:AddItem(k,go)
    end
end
function My:AddItem(name,go)
    go:SetActive(true)
    local t = go.transform    
    t.parent = self.grid
    t.localScale = Vector3.one
    t.localPosition = Vector3.zero
	local cell = ObjPool.Get(memberItem)
	cell:init(go,name)
    table.insert(self.Items, cell)
end

function My:doClear( )
    if self.items==nil then
        return;
    end
    for i=1,#self.Items do
        GbjPool:Add(self.Items[i].go)   
        ObjPool.Add(memberItem)
    end  
    self.Items=nil
    self.btnId=0
end

return My