-- ═══════════════════════════════════════════════════════════════════════
--  SKYFALL HUB | FIXED UNIVERSAL LOADER
-- ═══════════════════════════════════════════════════════════════════════

local Games = {
    -- Add known games here
}

local URL = Games[game.GameId]
local UniversalURL = "https://raw.githubusercontent.com/raziqmuhammadraziq79-dev/Skyfall-hub/main/UniversalGod.lua"

-- Try game-specific first, fallback to universal
if URL then
    loadstring(game:HttpGet(URL))()
else
    loadstring(game:HttpGet(UniversalURL))()
end
