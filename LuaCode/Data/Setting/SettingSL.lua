
SettingSL = Super:New{Name = "SettingSL"}
local UEP = UnityEngine.PlayerPrefs
local My = SettingSL
local m_json = json
local SetStr = UEP.SetString
local GetStr=UEP.GetString
local saveSuc = UEP.Save
local SM = SettingMgr
local SMG = SM.GetValueFast
local SM = SettingMgr
local prv = {}


-- --传入存储UIToggle
 -- function My.UtSave(name,bool)
 --   local n=prv.BoolToInt(bool)
 --   SetInt(name,n)
 -- end
 -- --滑条的存储方法
 -- function My:SaveSlider( name,value )
 --   SetFload(name,value)
 -- end
 -- --bool转数字
 -- function prv.BoolToInt(bool)
 --   return bool and 1 or 0
-- end
--json存储
function My:OnSave(SaveDic,name)
  local jsStr = m_json.encode(SaveDic);
  SetStr(name,jsStr)
  saveSuc();
end

function My:SaveOne( name,value )
  SetStr(name,tostring(value))
  saveSuc();
end

function My:ReadOne( name,value )
  return  GetStr(name,"null")
end
--json读取
function My:ReadName(name)
  local jsn =  GetStr(name,"null")
  local dic = {}
  if jsn == "null" then  return dic end  
  local data = m_json.decode(jsn)
  dic =  prv.SetSaveDic(data)
  return dic
end
 function prv.setType(str)
 if str=="true" then
   str=true
   elseif str=="false" then
   str=false
   else
   str=tonumber(str)
 end
   return str
end
--建立总表
function prv.SetSaveDic(dic)
  local Slst = {}
  local MAName = SM.MAName
  for k,v in pairs(dic) do
      if type(v)~="string" then
         return dic
      end
      v=prv.setType(v)
      Slst[k]=v
  end
  return Slst
end

--[[ 
 --存储名字
 function My:FirstSave(Bas_UT_b,Bas_SL_s,Hang_UT_b)
    local j_table = {}
    j_table["Bas_UT_b"]=Bas_UT_b
    j_table["Bas_SL_s"]=Bas_SL_s
    iTrace.eLog("soon  0 1  ",Bas_SL_s[1])
    j_table["Hang_UT_b"]=Hang_UT_b
    local jsStr = m_json.encode(j_table);
    SetStr("jsName",jsStr)
 end
 --读取名字
 function My:ReadName()
  local jsn =  GetStr("jsName",nil)
  local data = m_json.decode(jsn)
  local bb = data["Bas_UT_b"]
  local bs = data["Bas_SL_s"]
  local hb = data["Hang_UT_b"]
  iTrace.eLog("soon  0   ",bb[1])
  iTrace.eLog("soon  1   ",bs[1])
  iTrace.eLog("soon  2    ",hb[1])
  return bb,bs,hb
 end
 --读取数据
 function My:GetBasDic( )
  local SList = {}
  prv.doGetInt(SList,self.Bas_AllUTNam)
  prv.doGetFoal(SList,self.Bas_SndNam)
  return SList
 end
 function My:GetHanDic( )
  local SList = {}
  prv.doGetInt(SList,self.Han_UTNam)
  return SList
 end
 function prv.doGetInt( SList,list )
  for i=1,#list do
    local gf = GetInt(list[i],0)==1 and true or false
    SList[list[i] ]=gf
  end
 end
 function prv.doGetFoal(SList, list )
  iTrace.eLog("ll 1                          ",list[1])
  for i=1,#list do
    local gf = GetFload(list[i],1)
    SList[list[i] ]=gf
  end
 end
--]]
function My:Clear()

end

return My