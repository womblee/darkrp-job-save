local GAMEMODE = GAMEMODE or GM

local function init_tbl()
    sql.Query("CREATE TABLE IF NOT EXISTS gr_saved_jobs ( SteamID TEXT, Job INTEGER )")
end

local function save_tbl(ply, job)
    if ply:IsBot() then return end
    if not RPExtraTeams[job] then return end
    local data = sql.Query("SELECT * FROM gr_saved_jobs WHERE SteamID = " .. sql.SQLStr(ply:SteamID64()) .. ";")

    if data and table.Count(data) > 0 then
        sql.Query("UPDATE gr_saved_jobs SET Job = " .. job .. " WHERE SteamID = " .. sql.SQLStr(ply:SteamID64()) .. ";")
    else
        sql.Query("INSERT INTO gr_saved_jobs ( SteamID, Job ) VALUES( " .. sql.SQLStr(ply:SteamID64()) .. ", " .. job .. " )")
    end
end

local function getsavedjob(ply)
    local val = sql.QueryValue("SELECT Job FROM gr_saved_jobs WHERE SteamID = " .. sql.SQLStr(ply:SteamID64()) .. ";")

    if val ~= nil then
        return tonumber(val)
    else
        return GAMEMODE.DefaultTeam
    end
end

hook.Add("Initialize", "CPG_SaveJobTableCreate", function()
    init_tbl()
end)

hook.Add("PlayerInitialSpawn", "CPG_GiveJobOnSpawn", function(ply)
    if ply:IsBot() then return end

    timer.Simple(0.5, function()
        if IsValid(ply) then
            local job = getsavedjob(ply)

            if job ~= nil and job ~= GAMEMODE.DefaultTeam then
                local max = RPExtraTeams[job].max
                local numPlayers = team.NumPlayers(job)

                if max ~= 0 and (max >= 1 and numPlayers >= max or max < 1 and (numPlayers + 1) / player.GetCount() > max) then
                    return
                else
                    local setTeam = ply.changeTeam or ply.SetTeam
                    setTeam(ply, job, true)
                end
            else
                save_tbl(ply, ply:Team())
            end
        end
    end)
end)

hook.Add("OnPlayerChangedTeam", "CPG_SaveJob", function(ply, before, after)
    if GAMEMODE.DefaultTeam ~= after then
        save_tbl(ply, after)
    end
end)
