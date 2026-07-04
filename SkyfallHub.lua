-- ═══════════════════════════════════════════════════════════════════════
--  SKYFALL HUB | UNIVERSAL GAME LOADER
--  Game-specific scripts for known games
--  Universal God Mode for unknown games
-- ═══════════════════════════════════════════════════════════════════════

local HttpGet = game.HttpGet
local GameId = game.GameId

-- ═══════ GAME DATABASE ═══════
local Games = {
    -- Menara Kerja Tim / Locked In Towers
    [0] = "https://raw.githubusercontent.com/raziqmuhammadraziq79-dev/Skyfall-hub/main/LockedInTowers.lua",
    
    -- Add more games here with their PlaceId
    -- [PLACE_ID] = "URL",
}

-- ═══════ UNIVERSAL FALLBACK ═══════
local UniversalURL = "https://raw.githubusercontent.com/raziqmuhammadraziq79-dev/Skyfall-hub/main/UniversalGod.lua"

-- ═══════ LOAD ═══════
local URL = Games[GameId]

if URL then
    loadstring(HttpGet(game, URL))()
else
    loadstring(HttpGet(game, UniversalURL))()
end
