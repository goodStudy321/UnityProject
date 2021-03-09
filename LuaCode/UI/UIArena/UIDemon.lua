UIDemon = ArenaBase:New{Name = "UIDemon"}
local My = UIDemon;

function My:Open(go)
    TopThrDemon:Open(go);
end

function  My:Close()
    TopThrDemon:Close();
end