--[[
    WARNINGS
    
    * Lua metatables are not being used as classes for this example (since they violate encapsulation),
    but 
    * They are meant here to show how to "glue" Solar2D display elements into one simple "object", and
    show how to create new instances of them
    * Server part is also a simple example, in this case to show how to communicate with button
    listeners
    * Server has its "users database" representated as a single table, they won't be saved
    anywhere once shutdown takes place
]]

display.setStatusBar(display.DefaultStatusBar)

local composer = require("composer")

local testing_phase = true
local testing_scene = "game"

if testing_phase then
    composer.gotoScene(testing_scene, {params={testing_phase = true}})
else
    composer.gotoScene("game", {params={testing_phase=false}})
end