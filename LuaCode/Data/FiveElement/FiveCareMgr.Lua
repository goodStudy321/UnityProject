FiveCareMgr=Super:New{Name="FiveCareMgr"}
local My = FiveCareMgr
--存储的字典
My.BossDic=nil
function My.Init(  )
    
end

function My.Lsnr(  )
    EventMgr.Add("AddSkill", My.OnUpDate)  
end

function My.OnUpDate( id )
    local care = My.IsCear( id )
    if care then
        
    end
end

--1选中2不选中
function My.OnChange( id,num )
    My.BossDic[tostring(id)]=num
end

--是否选中
function My.IsCear( id )
   local num = My.BossDic[tostring(id)]
   return num==1
end

--保存
function My.SaveMsg( )
    local Name = tostring(User.instance.MapData.UID).."FiveBossId";
    SettingSL:OnSave( My.BossDic,Name); 
end


function My.ReadInOpen(  )
    local Name = tostring(User.instance.MapData.UID).."FiveBossId";    
    My.BossDic=SettingSL:ReadName(Name)
end

function My.Save(  )

end

return My;