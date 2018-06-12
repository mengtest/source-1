---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wangliang.
--- DateTime: 2018/4/8 下午3:55
---
local min = math.min
local controlImpl = require("app.module.skill.BuffControlImpl")
local propImpl = require("app.module.skill.BuffPropImpl")
local emptyImpl = {}
function emptyImpl:Exec(owner,undo) end

local EBuffType = {
    CONTROL = 1,--控制
    PROP_VAL = 2,--绝对值属性增减
    PROP_PEC =3,--百分比属性增减
    HP_VAL = 4,--dot/hot绝对值
    HP_PEC = 5,--dot/hot百分比
    SPEC = 6,--特殊
}

local EConditionOff = {
    NONE = 0,--无条件
    HITTED =1,--受到攻击次数
    CURED = 2,--受到治疗次数
    SKILL =3,--技能次数
    HIT = 4,--命中数_目标
    DMG = 5,--受到伤害累积超标
}

local CfgData = CfgData

local Buff = class("Buff")

function Buff:ctor(id,srcId)
    self.id = id
    self.stub = CfgData:GetBuff(id)
    self.layer = 1
    self.srcId = srcId --来源id，由谁挂上
end

--同Id，同源
function Buff:IsSame(other)
    return self.id == other.id and self.srcId == other.srcId
end

function Buff:GetType()
    return self.stub.buffType
end

function Buff:GetSubType()
    return self.stub.buffSubType
end

function Buff:GetVal()
    return self.stub.effectValue
end

function Buff:GetMutex()
    return self.stub.mutex
end

function Buff:GetPriority()
    return self.stub.priority
end

function Buff:GetOverlay()
    return self.stub.overLay
end

function Buff:GetLastTime()
    return self.stub.lastTime
end

function Buff:GetStartTime()
    return self.stub.startTime
end

function Buff:GetPeriod()
    return self.stub.period
end

function Buff:GetConditionOff()
    return self.stub.conditionOff
end

function Buff:GetEffect()
    return self.stub.SpecialEffect
end

function Buff:CanAttach(target)
    return true
end

function Buff:AddLayer()
    local newLayer = min(self.layer + 1,self:GetOverlay())
    if newLayer ~= self.layer then
        self.layer = newLayer
    end
end

function Buff:TryAttach(target)
    if not self:CheckMutexOn(target) then
        return
    end
    if not self:CheckSameOn(target) then
        return
    end
    self:Attach(target)
end

--互斥性检查是否能加
function Buff:CheckMutexOn(target)
    local mutexBuff = target:GetMutexBuff(self:GetMutex())
    local buffType = self:GetType()
    if buffType == EBuffType.CONTROL then
        if mutexBuff then --控制类新的加不上
            return false
        end
    elseif buffType == EBuffType.SPEC then
        if mutexBuff then --特殊类新的替换
            mutexBuff:Detach()
        end
    else
        if mutexBuff then
            if mutexBuff:GetPriority()> self:GetPriority() then --优先级低的忽略
                return false
            elseif mutexBuff.id ~= self.id then --不是相同buff的高优先级的替换
                mutexBuff:Detach()
            end
        end
    end
    return true
end
--叠加检查
function Buff:CheckSameOn(target)
    local overlay = self:GetOverlay()
    if overlay < 0 then
        local sameSrcBuff = target:GetBuff(self.id,self.srcId)
        if sameSrcBuff then
            sameSrcBuff:Detach()
        end
    elseif overlay > 0 then
        local sameSrcBuff = target:GetBuff(self.id,self.srcId)
        if sameSrcBuff then
            sameSrcBuff:AddLayer()
            return false
        end
    end
    return true
end

function Buff:Attach(target)
    self.owner = target
    self.owner:AddBuff(self)
    self.leftTime = self:GetLastTime()
    self.hop = 0
    self.nextHopTime = self:GetNextHopTime()
    self.isOver = false
end

function Buff:Detach()
    if self.hop>0 then---执行过
        self:GetImpl():Exec(self.owner,true)
    end
    self.owner:RemoveBuff(self)
    self.owner = nil
end

function Buff:Update(deltaTime)
    if self.isOver or self:CheckConditionOver() then
        return
    end
    self:CheckHop(deltaTime)
    self.leftTime = self.leftTime - deltaTime
    if self.leftTime <= 0 then
        self.isOver = true
    end
end

function Buff:CheckConditionOver()
    if self:GetConditionOff() == EConditionOff.NONE then
        return false
    end
    self.isOver = true
    return true
end

function Buff:CheckHop(deltaTime)
    if not self.nextHopTime or self.nextHopTime < 0 then return end
    self.nextHopTime = self.nextHopTime - deltaTime
    if self.nextHopTime <= 0 then
        self:OnHop()
    end
end

function Buff:GetNextHopTime()
    if self.hop == 0 then
        return self.stub.startTime
    else
        return self.stub.period
    end
end

function Buff:OnHop()
    self.hop = self.hop + 1
    self.nextHopTime = self:GetNextHopTime()
    self:GetImpl():Exec(self.owner)
end

function Buff:__GenImpl()
    local buffType = self:GetType()
    if buffType == EBuffType.CONTROL then
        return controlImpl[self:GetSubType()].new()
    elseif buffType == EBuffType.SPEC then
        return
    else
        return propImpl[buffType-1].new()
    end
end

function Buff:GetImpl()
    if not self.impl then
        self.impl = self:__GenImpl() or emptyImpl
        self.impl.buff = self
    end
    return self.impl
end

return Buff