---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wade.
--- DateTime: 2018/4/16 上午11:27
---
local Vector3 = _G.Vector3
local tonumber = tonumber
local EventTrigger = EventTrigger

local EventProcessing = class("EventProcessing")
function EventProcessing:ctor(event,target,callBack)
    self.target = target
    self.callBack = callBack
    if not event then
        self.triggerEvent = 0
        self.triggerParam = 0
        self.executeEvent = 0
        self.executeParam = 0
    else
        self.triggerEvent = event.triggerEvent
        self.triggerParam = event.triggerParam
        self.executeEvent = event.executeEvent
        self.executeParam = event.executeParam
    end
    self.playerInPos = false
    if self.triggerEvent ~= EventTrigger.TriggerType.None and self.triggerParam ~= 0 then
        self.waitTrigger = true
    else
        self.target:Move(function ()
            self:ExecuteEvent()
        end)
    end
end

function EventProcessing:ExecuteEvent()
    if self.executeEvent ~= 0 and self.executeParam ~= 0 then
        if self.executeEvent ==  EventTrigger.EventType.Idle then
            self.target.owner:Idle(tonumber(self.executeParam),self.callBack)
        elseif self.executeEvent == EventTrigger.EventType.Scene then
            local splitList = string.split(self.executeParam,',')
            self.target.owner:Move(Vector3.new(tonumber(splitList[1]) ,tonumber(splitList[2]),tonumber(splitList[3])),
                    function()
                        self.target.owner.actor:Idle()
                        self.callBack()
                    end)
        elseif self.executeEvent == EventTrigger.EventType.Show then
            print("say sth")
        end
    else
        if self.callBack then
            self.callBack()
        end
    end
end

function EventProcessing:OnUpdate(deltaTime)
    if self.waitTrigger then
        if self.triggerEvent == EventTrigger.TriggerType.PlayerEnterTrigger and self.playerInPos then
            self.waitTrigger = false
            self.playerInPos = false
            self.target:Move(function ()
                self:ExecuteEvent()
            end)
        elseif self.triggerEvent == EventTrigger.TriggerType.MonsterTrigger and self.monsterInPos then
            self.waitTrigger = false
            self.monsterInPos = false
            self.target:Move(function ()
                self:ExecuteEvent()
            end)
        else
            if EventTrigger:GetMonsterTrigger(self.triggerParam) then
                self.waitTrigger = false
                self.target:Move(function ()
                    print("monster all dead trigger")
                    self:ExecuteEvent()
                end)
            end
        end
    end
end

function EventProcessing:ProcessingTrigger(type,param)
    if self:IsPlayerTrigger(type) and param == self.triggerParam then
        self.playerInPos = true
    elseif self:IsMonsterTrigger(type) and param == self.triggerParam then
        self.monsterInPos = true
    end
end

function EventProcessing:IsPlayerTrigger(type)
    if type == EventTrigger.TriggerType.PlayerEnterTrigger then
        return true
    end
    return false
end

function EventProcessing:IsMonsterTrigger(type)
    if type == EventTrigger.TriggerType.MonsterTrigger then
        return true
    end
    return false
end


local MonsterAI_Patrol_Point = class("MonsterAI_Patrol_Point",require("app.object.controller.monster.states.MonsterAIState_Base"))
local MonsterAIStates = require("app.object.controller.monster.MonsterAIStates")

function MonsterAI_Patrol_Point:ctor()
    self:AddTransition(MonsterAIStates.Transition.FindTarget,MonsterAIStates.MonsterAIState.MonsterAI_Follow)
    self:AddTransition(MonsterAIStates.Transition.Dead,MonsterAIStates.MonsterAIState.MonsterAI_Dead)
    self:AddTransition(MonsterAIStates.Transition.AtkedByTarget,MonsterAIStates.MonsterAIState.MonsterAI_Atked)
end

function MonsterAI_Patrol_Point:OnEnter()
    self.owner.view:SetSpeed(self.owner.dataModel:GetMoveSpeed())
    local ownerData = self.owner.dataModel
    self.first = true
    self.pointsLen = #ownerData:GetPatrolPoints()
    self.wrap = ownerData:GetPatrolWrap()
    self.sign = 1
    self:DoEvent()
end

function MonsterAI_Patrol_Point:DoEvent()
    local event = self:GetEevent()
    self.curEvent = EventProcessing.new(event,self,function()
        self:DoEvent()
    end
    )
end

function MonsterAI_Patrol_Point:EventTrigger(type,param)
    self.curEvent:ProcessingTrigger(type,param)
end

function MonsterAI_Patrol_Point:GetEevent()
    local ownerData = self.owner.dataModel
    local triggers = ownerData:GetEventTriggers()
    if not triggers then
        return
    end
    local curEvent = triggers[ownerData.posIndex]
    return curEvent
end

function MonsterAI_Patrol_Point:OnUpdate(deltaTime)
    self.owner:UpdateSelector()
    if self.curEvent then
        self.curEvent:OnUpdate(deltaTime)
    end
end

function MonsterAI_Patrol_Point:OnExit()
    self.owner.dataModel:SetBeginBattlePos(self.owner:GetPos())
    self.owner.dataModel:StartCountDown()
    self.owner.controller:Cancel()
    self.curEvent = nil
end


function MonsterAI_Patrol_Point:Move(callBack)
    if self:CanMove() then
        self.owner.actor:Run()
        self.owner:Move(self:GetPos(),function()
            self.owner.actor:Idle()
            self:SetNextPos()
            callBack()
        end)
    end
end

--得到路径点
function MonsterAI_Patrol_Point:GetPos()
    local ownerData = self.owner.dataModel
    local patrolPoints = ownerData:GetPatrolPoints()[ownerData.posIndex]
    local pos = Vector3.new(patrolPoints[1],0,patrolPoints[3])
    return pos
end

function MonsterAI_Patrol_Point:CanMove()
    local ownerData = self.owner.dataModel
    if self.wrap == 0 and ownerData.posIndex == self.pointsLen + 1 then
        return false
    else
        return true
    end
end

function MonsterAI_Patrol_Point:SetNextPos()
    local ownerData = self.owner.dataModel
    if self.wrap == 0 then
        ownerData.posIndex = ownerData.posIndex + 1
    elseif self.wrap == 2 then
        if ownerData.posIndex == self.pointsLen then
            ownerData.posIndex = 1
        else
            ownerData.posIndex = ownerData.posIndex + 1
        end
    else
        if ownerData.posIndex == self.pointsLen or (ownerData.posIndex == 1 and not self.first) then
            self.first = false
            self.sign = self.sign * -1
        end
        ownerData.posIndex = ownerData.posIndex + 1 * self.sign
    end
end

return MonsterAI_Patrol_Point