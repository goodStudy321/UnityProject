--[[
改名界面
--]]
UIChangeName=UIBase:New{Name="UIChangeName"}
local My = UIChangeName

function My:InitCustom()
    local TF = TransTool.FindChild
	local CG = ComTool.Get
    local trans = self.root
    
    local U = UITool.SetBtnClick
    U(trans,"Close",self.Name,self.Close,self)
    U(trans,"cancel",self.Name,self.Close,self)
    U(trans,"ok",self.Name,self.Ok,self)
    self.Title=CG(UILabel,trans,"bg/Title",self.Name,false)
    self.curName=CG(UILabel,trans,"curName/lab",self.Name,false)
    self.newName=CG(UIInput,trans,"newName/Input",self.Name,false)
    self.Cell=ObjPool.Get(UIItemCell)
    self.Cell:InitLoadPool(trans,nil,nil,nil,nil,Vector3.New(-56,-41,0))

    self.User=User.instance.MapData
end

function My:UpData(type_id)
    self.type_id=type_id
    self.str = ObjPool.Get(StrBuffer)

    local item = ItemData[tostring(type_id)]
    if not item then iTrace.eError("xiaoyu","道具表为空 id: "..type_id)return end
    self.uFx=item.uFx
    if self.uFx==42 then 
        self.curName.text=self.User.Name
        self.Title.text="角色改名"
    elseif self.uFx==43 then 
        self.curName.text=FamilyMgr:GetFamilyData().Name
        self.Title.text="道庭改名"
    end
    
    --local num = PropMgr.TypeIdByNum(type_id)
    --local need = item.uFxArg
    self.islack=false
    self:CheckItemLack();
    local color = "[ffffff]"
    --if num<need then color="[f21919]" self.islack=true end
    if self.islack == true then
        color="[f21919]";
    end
    self.str:Apd(color):Apd(num):Apd("/"):Apd(need)
    self.Cell:UpData(type_id,self.str:ToStr())

    local goodData = {};
	--唯一id
	goodData.id = 0;
	--道具表id
	goodData.type_id = type_id;
	--是否绑定
	goodData.bind = false;
	--数量
	goodData.num = 1;
	--卓越属性
	goodData.eDic = {};
	--翅膀
	goodData.wing_id = nil;
	goodData.bList = {};
	goodData.lDic = {};

    self.Cell:TipData(goodData, 1);
end

--// LY add begin
function My:CheckItemLack()
    local item = ItemData[tostring(self.type_id)];
    local num = PropMgr.TypeIdByNum(self.type_id);
    local need = item.uFxArg[1];
    if num < need then
        self.islack = true
    else
        self.islack = false;
    end
end
--// LY add end

function My:Ok()
    local name = self.newName.value
    local cur = self.curName.text
    if StrTool.IsNullOrEmpty(name) then UITip.Log("请输入新的名字") return end
    local text,isMask=MaskWord.SMaskWord(name)
    if isMask==true then UITip.Log("名字存在屏蔽词，请重新输入")return end
    if name==cur then UITip.Log("名字重复，请重新输入")return end

    --// LY edit begin
    self:CheckItemLack();
    if self.islack==true then
        --UITip.Log("道具不足，请前往商城购买");
        --return;

        local item = ItemData[tostring(self.type_id)];
        StoreMgr.TypeIdBuy(self.type_id, item.uFxArg[1], true);
        return;
    end
    --// LY edit end

    if self.uFx==42 then  --角色改名卡
        if UICreate:IsCheck(name)==true then
            UITip.Error("角色名包含字母、数字或符号，请重新输入！！！")
            return 
        end
        PropMgr.ReqReName(name)
    elseif self.uFx==43 then  --道庭改名卡
        PropMgr.ReqFamilyName(name)
    end
    self:Close()
end

function My:CloseCustom()
    if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) self.Cell=nil end
    self.User=nil
    self.newName.value=""
    if self.str then ObjPool.Add(self.str) return end
end

return My