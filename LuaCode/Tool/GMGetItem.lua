--[[

]]
GMGetItem={Name="GMGetItem"}
local My = GMGetItem
My.isClick=false
My.id=nil

function My.Init()
    UIItemCell.eClickGM:Add(My.OnClick)
end

function My.OnClick(id)
    My.isClick=true
    My.id=id
end

function My.Update()
    local isF8 = UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.F8)
    local isclick = My.isClick
    if(UnityEngine.Input.GetKey(UnityEngine.KeyCode.F8)) then
        if My.isClick==true then 
            My.isClick=false
            GMManager.instance:SendReqMes("bag_create_goods",My.id..";1")
        end
    end
     
end