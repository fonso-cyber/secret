local env = (type(getgenv) == "function" and getgenv()) or _G
env.Config = Config
_G.Config = Config
shared.Config = Config

local url = "https://raw.githubusercontent.com/fonso-cyber/secret/main/bloodz.lol" -- corrige a URL
local HttpGet = game.HttpGet
local Load    = loadstring
local pcall_  = pcall
local tostring_ = tostring

local okGet, src = pcall_(function()
    return HttpGet(game, url)
end)
if not okGet or type(src) ~= "string" or #src == 0 then
    error("HttpGet failed, please report this error to discord: " .. tostring_(src))
end

local fn, lerr = Load(src)
if not fn then error("loadstring failed, please report this error to discord: " .. tostring_(lerr)) end

local okRun, rerr = pcall_(fn)
if not okRun then error("error executing remote, please report this error to discord: " .. tostring_(rerr)) end
