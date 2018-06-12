---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wangliang.
--- DateTime: 2018/4/16 下午7:16
---

local ViewPop = class("ViewPop",require("app.ui.UiView"))
ViewPop.res = "dlgpop"
local _G = _G

local LuaUtility = CS.Game.LuaUtility

function ViewPop:OnOpen()
    _G.Pop = self
end

function ViewPop:OnClose()
    _G.Pop = nil
    self:Clear()
end

function ViewPop:Tip(msg)
    LuaUtility.Tip(self.bubble,msg)
end

function ViewPop:Warning(msg)
    LuaUtility.Warning(self.bubble,msg)
end

function ViewPop:PopHp(whoId,whoTrans,hpType,hp)
    LuaUtility.PopHp(self.bubble,whoId,whoTrans,hpType,hp)
end

function ViewPop:RemoveHpPop(whoId)
    LuaUtility.RemoveHpPop(self.bubble,whoId)
end

function ViewPop:Clear()
    LuaUtility.BubbleClear(self.bubble)
end

_G.ViewPop = ViewPop