---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wade.
--- DateTime: 2018/4/17 上午11:59
---
---

local MonsterAI_Patrol_Circle = class("MonsterAI_Patrol_Circle",require("app.object.controller.monster.states.MonsterAIState_Base"))
local random = math.random
local Vector3 = _G.Vector3
local MonsterAIStates = require("app.object.controller.monster.MonsterAIStates")


function MonsterAI_Patrol_Circle:ctor()
    self:AddTransition(MonsterAIStates.Transition.Dead,MonsterAIStates.MonsterAIState.MonsterAI_Dead)

end

function MonsterAI_Patrol_Circle:OnEnter()
    if self.owner.dataModel:IsCoward() then
        self:AddTransition(MonsterAIStates.Transition.AtkedByTarget,MonsterAIStates.MonsterAIState.MonsterAI_Escape)
        self:AddTransition(MonsterAIStates.Transition.FindTarget,MonsterAIStates.MonsterAIState.MonsterAI_Escape)
    else
        self:AddTransition(MonsterAIStates.Transition.AtkedByTarget,MonsterAIStates.MonsterAIState.MonsterAI_Atked)
        self:AddTransition(MonsterAIStates.Transition.FindTarget,MonsterAIStates.MonsterAIState.MonsterAI_Follow)
    end
    --print("enter patrol circle circle circle")
    self.owner.view:SetSpeed(self.owner.dataModel:GetMoveSpeed())
    self.stayTime = random(1,2)
    self.moveEnd = false
    self.owner.actor:Run()

    self:MoveToRandomPos()
end

function MonsterAI_Patrol_Circle:OnUpdate(deltaTime)
    if self.moveEnd then
        self.stayTime = self.stayTime - deltaTime
    end

    if self.moveEnd and self.stayTime <= 0 then
        self.owner.actor:Run()
        self:MoveToRandomPos()
        self.moveEnd = false
        self.stayTime = random(1,2)
    end
    self.owner:UpdateSelector()
end

function MonsterAI_Patrol_Circle:OnExit()
    self.owner.dataModel:SetBeginBattlePos(self.owner:GetPos())
    self.owner.dataModel:StartCountDown()
end

function MonsterAI_Patrol_Circle:MoveEnd()
    self.moveEnd = true
    self.owner.actor:Idle()
end

function MonsterAI_Patrol_Circle:MoveToRandomPos()
    local ownerData = self.owner.dataModel
    local pos = Vector3.new(ownerData.initPos.x,ownerData.initPos.y,ownerData.initPos.z)
    local delta = Vector3.new(random(-1,1),0,random(-1,1)):setNormalize()
    pos = pos + delta:mul(ownerData:GetPatrolRange())
    self.owner:MoveToPos(pos)
end

return MonsterAI_Patrol_Circle