---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wangliang.
--- DateTime: 2018/4/20 下午5:51
---
local ViewEffect = require("app.object.view.ViewEffect")
local bind = require("xlua.util").bind
local EffectType = Const.EffectType
local pairs = pairs
local Vector3 = Vector3

local Ballistic = class("Ballistic")

local BallisticManager = {
    ballistics = {},
    lastId = 0,
}

function Ballistic:ctor(id,skill)
    self.id = id
    self.skill = skill
    self.impl = skill.impl
    self.calc = skill.impl.calc:Ref()
end

function Ballistic:Fly(isLastHit)
    self.isLastHit = isLastHit
    --正常子弹是从枪口飞向敌人，但有肯能枪口过长，导致子弹反向飞行，需要排除这种表现
    if self:CheckIsDirOpposite(self.calc) then
        self:OnEnd()
        return
    end
    self.view = ViewEffect.new(EffectType.BALLISTIC)
    self.view:SetMountPos(self.calc.fromPos)
    self.view:Load(self.skill:GetFlyEffect(),self.OnLoaded,self)
end

function Ballistic:Release()
    if self.view then
        self.view:SetOnOver()
        self.view:Release()
        self.view = nil
    end
    self.skill = nil
    self.impl = nil
    self.calc:Release()
    self.calc = nil
end

function Ballistic:OnLoaded()
    self.view:SetOnOver(bind(self.OnEnd,self))
    self.view:PlayBallistic(self.calc.pos,self.skill:GetFlySpeed())
end

function Ballistic:OnEnd()
    self.impl:CalcTarget(self.calc)
    self.impl:Do(self.isLastHit,self.calc)
    BallisticManager:RemoveBallistic(self)
end

--检查子弹反向
function Ballistic:CheckIsDirOpposite(calc)
    local userPos = calc.user:GetPos()
    local fromPos = calc.fromPos
    local forwardDir = fromPos - userPos
    forwardDir.y = 0
    local flyDir = calc.pos - calc.fromPos
    flyDir.y = 0
    return Vector3.Dot(forwardDir,flyDir) <=0
end

---子弹管理器

function BallisticManager:AddBallistic(skill)
    self.lastId = self.lastId + 1
    local ballistic = Ballistic.new(self.lastId,skill)
    self.ballistics[self.lastId] = ballistic
    return ballistic
end

function BallisticManager:RemoveBallistic(ballistic)
    self.ballistics[ballistic.id] = nil
    ballistic:Release()
end

function BallisticManager:Release()
    for _,ballistic in pairs(self.ballistics) do
        ballistic:Release()
    end
    self.ballistics = {}
end

_G.BallisticManager = BallisticManager

