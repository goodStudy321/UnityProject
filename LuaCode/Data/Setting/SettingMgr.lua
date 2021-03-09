
SettingMgr={Name="SettingMgr"}
local My = SettingMgr
local SL=require("Data/Setting/SettingSL")
local prv = {}
My.QuickPeople = {0,2,6,99}
--统一设置场景的name为场景key=id.."set"
--初始化方法
function  My:Init ()
    --ut组的字段
    My.SQName = {"low","fluency","delicacy","perfect"}
    My.SPName={"screen","point"}
    My.MAName={"music","audio"}
    My.SetLsnr("Add")

end
--监听场景
function My.SetLsnr(func)
    EventMgr[func]("SelectSuc", My.brigde)   
    EventMgr[func]("OnChangeScene", My.OtherCtrl)
    -- EventMgr[func]("RequestClipPlayerNum", My.SetNormalSenceNum)
end

function My.brigde(  )
        My.openLisnr("Add")
    -- end  
end

--执行开始改变
function My.openLisnr(func)
    EventMgr[func]("BegChgScene", My.beOpnOnce)
    EventMgr[func]("OnChangeScene", My.openOnWay)
    EventMgr[func]("OnChangeScene", My.opnOnce)
end
function My.beOpnOnce(  )
    local name =  tostring(User.instance.MapData.UID).."jgxSet";
    My.SaveDic= SettingSL:ReadName(name)
    prv.Checkless()  

    --赋初始值
    My.MusicCtrl()
    My.AudioCtrl() 
    My.IsInitLoadScene = User.instance.IsInitLoadScene  
end
function My.opnOnce( )
    My.ChangeSetting(My.SaveDic,true) 
    My.openLisnr("Remove")
end

function prv.Checkless()
    My.SaveDic["devour_wb_less5_equip"]=My.SaveDic["devour_wb_less5_equip"]==nil and true or My.SaveDic["devour_wb_less5_equip"];
    My.SaveDic["sell_wb_less5_equip"]=My.SaveDic["sell_wb_less5_equip"]==nil and true or My.SaveDic["sell_wb_less5_equip"];
    My.SaveDic["whiteEquip"]=My.SaveDic["whiteEquip"]==nil and true or My.SaveDic["whiteEquip"];
    My.SaveDic["blueEquip"]=My.SaveDic["blueEquip"]==nil and true or My.SaveDic["blueEquip"];
    My.SaveDic["purpleEquip"]=My.SaveDic["purpleEquip"]==nil and true or My.SaveDic["purpleEquip"];
    My.SaveDic["upPurpleEquip"]=My.SaveDic["upPurpleEquip"]==nil and true or My.SaveDic["upPurpleEquip"];
    My.SaveDic["other"]=My.SaveDic["other"]==nil and true or My.SaveDic["other"];
    if  My.SaveDic["blockOtherFx"]==nil then
        My.SaveDic["blockOtherFx"]=false;
    end
    if  My.SaveDic["blockTitle"]==nil then
        My.SaveDic["blockTitle"]=false;
    end
end

--根据名称获取值
function My.GetValue(Name,tip)
    if Name==nil then   iTrace.Error("soon","未传入组件名称  ",tip)  end
    if type(Name)~="string" then   iTrace.Error("soon","应传入一个string类型数据  ",tip)  end
    local SSL=My.SaveDic 
    for k,v in pairs(SSL) do
        if k==Name then
            return v
        end
    end
    iTrace.Error("soon","无此名称组件 ",tip)
end
--根据名称快速获取值
--无提示,必须传入String类型存在的UI名
function My.GetValueFast(Name)
    if My.SaveDic==nil then
        return "无此数据"
    end
    local value =  My.SaveDic[Name]
    if  value==nil then
        return "无此数据"
    end
    return value
end
--设置总表的值,如果没有直接改变保存
function My.SaveValue(SDic)
    if SDic  == nil  then SDic = My.SaveDic   end
    My.ChangeSetting(SDic,false)
    for k,v in pairs(SDic) do
        My.SaveDic[k]=v
    end
    local name =  tostring(User.instance.MapData.UID).."jgxSet";
    SL:OnSave(My.SaveDic,name)      
end
-- 调用 改变全局参数,音乐除外
-- My.UTName={"blockOther","blockOtherFx","blockMonster",
-- "blockLessNine","blockTitle","whiteEquip","blueEquip",
-- "purpleEquip","upPurpleEquip","gold","other","sell_wb_less5_equip",
-- "devour_wb_less5_equip"
-- }
 function My.ChangeSetting(SDic,bool)
    local b = bool --需要开始赋值的if后加  or b
    if b==nil then b=false end
    local SSL = My.SaveDic
    local scene_name = tostring(User.instance.SceneId).."set"
    --同屏人数
    if SSL[scene_name]~=SDic[scene_name] or b  then
        SSL[scene_name]=SDic[scene_name]
        My.OtherCtrl()
    end
    -- 屏蔽特效
    if SSL["blockOtherFx"]~=SDic["blockOtherFx"] or b  then
        EventMgr.Trigger("OnShieldEff",SDic["blockOtherFx"])
    end 

    if SSL["blockLessNine"]~=SDic["blockLessNine"] or b  then
        -- 调用的接口
    end
    --屏蔽标题
    if SSL["blockTitle"]~=SDic["blockTitle"] or b  then
        local b1 = not SDic["blockTitle"]
        User.instance.IsShowTitle=b1;
    end
    if SSL["whiteEquip"]~=SDic["whiteEquip"] or b  then
        EventMgr.Trigger("PickEquip",1,SDic["whiteEquip"])
    end
    if SSL["blueEquip"]~=SDic["blueEquip"]  or b then
        EventMgr.Trigger("PickEquip",2,SDic["blueEquip"])
    end
    if SSL["purpleEquip"]~=SDic["purpleEquip"] or b  then
        EventMgr.Trigger("PickEquip",3,SDic["purpleEquip"])
    end
    if SSL["upPurpleEquip"]~=SDic["upPurpleEquip"] or b  then
        EventMgr.Trigger("PickEquip",4,SDic["upPurpleEquip"])
        EventMgr.Trigger("PickEquip",5,SDic["upPurpleEquip"])
        EventMgr.Trigger("PickEquip",6,SDic["upPurpleEquip"])
    end
    if SSL["other"]~=SDic["other"]  or b then
        EventMgr.Trigger("PickEquip",0,SDic["other"])
    end
    if SSL["sell_wb_less5_equip"]~=SDic["sell_wb_less5_equip"] or b then
        local value = SDic["sell_wb_less5_equip"]
        if b then
            PropMgr.isAuto=value
            PropMgr.AutoSell(value)  
        else
            PropMgr.AutoSell(value)            
        end
    end
    if SSL["devour_wb_less5_equip"]~=SDic["devour_wb_less5_equip"] or b then
        local value = SDic["devour_wb_less5_equip"]
        if b then
            PropMgr.isAutoDevour=value
            PropMgr.AutoDevour(value)
        else
            PropMgr.AutoDevour(value)            
        end
    end
 --画质是否改变 
    My.SQchange( SDic,b)
--挂机地点
        local SPName = My.SPName
        local c= b and true or not SSL[SPName[1]]   
        if   SDic[SPName[1]]==true and c then
            -- 调用的接口
        else 
            -- 调用的接口
        end
    end


function My.SQchange( SDic,b)
    local SQName =My.SQName
    local SSL = My.SaveDic    
    local best ,max= QualityTool:GetSetUseQuality()
    local isAllFalse = true
    for i=1,#SQName do
        local c= b and true or (not SSL[SQName[i]])
        if SDic[SQName[i]]==true and c then
            isAllFalse=false
             if b == true and i>max  then
                --非选择还原默认
                    for k=1,#SQName do
                        if best==k then
                            SSL[SQName[k]]=true
                            else
                            SSL[SQName[k]]=false
                        end
                    end
                 QualityMgr:ChangeQuaByIndex(best-1)
            else
                QualityMgr:ChangeQuaByIndex(i-1)            
            end 
        end
    end
    if isAllFalse and b then
        SSL[SQName[best]]=true
        SDic[SQName[best]]=true
        QualityMgr:ChangeQuaByIndex(best-1)
    end
end
  --音乐控制
  --传入一个float类型的数据
  --如果不传入则读取存储数据\
function My.MusicCtrl(FN )
    local name = My.MAName[1]
    local SD = My.GetValueFast(name)
    if SD == "无此数据" then
        SD = 1
    end
    if type(FN)=="number"  then
        SD=FN
    end
    Music.Volume=SD
end
  --音效控制
function My.AudioCtrl(FN)
    local name = My.MAName[2]
    local SD = My.GetValueFast(name)
    if SD == "无此数据" then
        SD = 1
    end
    if type(FN)=="number" then
        SD=FN
    end 
    Audio.Volume=SD
end


function My.openOnWay( )
        --onway预加载
    --     if User.instance.MapData.Level==1 then
    --         PreloadPrefab.Add("UIOnWay",false)
    --     UIMgr.Open(UIOnWay.Name)
    -- end
end

--人数控制
function My.OtherCtrl()
    local id= tostring(User.instance.SceneId)
    local name = id.."set"
    local num = My.GetValueFast(name)
    if num == "无此数据" then
        num=My.NilChooseNum( )
    end
    My.SaveDic[name]=num
    EventMgr.Trigger("OnChgShowNum",num)
end

function My.NilChooseNum( )
    local id= tostring(User.instance.SceneId)
    local num = 4
    if id==nil or SceneTemp[id]==nil or SceneTemp[id].maxNum==nil then
        return num
    end
    local b=false
    local x = 1
    local SQName =My.SQName
    for i=1,#SQName do
        if My.GetValueFast(SQName[i])==true then
          x=i;
          b=true
          break;
        end 
    end
    if b==false then
       x= QualityTool:GetSetUseQuality()
    end
    local max = SceneTemp[id].maxNum == nil and 0 or  SceneTemp[id].maxNum
    local qp = My.QuickPeople[x] == nil and max or  My.QuickPeople[x]
    num=max<qp and max or qp
    return num
end

function My.Clear()
end

return My