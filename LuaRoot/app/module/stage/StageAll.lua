---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by wangliang.
--- DateTime: 2018/5/11 下午5:38
---
--- 关卡存储信息
--- 一个scene可能对应多个stage, 多个stage是一个先后关系，必须先打低级关卡，再打高级关卡
---

local CfgData = CfgData
local pairs,next = pairs,next
local tostring,tonumber = tostring,tonumber

local Global = Global
local StorageEvent = StorageEvent

local StageData = require("app.module.stage.StageData")

local StageAll = {}
extendMethod(StageAll,require("app.base.Savable"))

function StageAll:Create()
    self.stages = {}
    self.stageTags = {}
end

function StageAll:Export(modified)
    local data = self.lastSave or {}
    local mod = modified and {} or nil
    for tid,changed in pairs(self.stageTags) do
        if changed then
            self.stageTags[tid] = false
            local stage = self.stages[tid]
            if stage then
                local tidStr = tostring(tid)
                local sdata,smod = stage:Export(modified)
                data[tidStr] = sdata
                if mod then
                    mod[tidStr] = smod
                end
            end
        end
    end
    return data,mod
end

function StageAll:Import(data)
    self.stages = {}
    self.stageTags = {}
    for tidStr,stageData in pairs(data) do
        local stage = StageData.new()
        stage:Import(stageData)
        self.stages[tonumber(tidStr)] = stage
        stage:BindChangeNotify(self.OnStageChanged,self)
    end
end


function StageAll:EnterScene(sceneId)
    local sceneCfg = CfgData:GetScene(sceneId)
    local stageId = sceneCfg and sceneCfg.stageId
    self:EnterStage(stageId)
end

function StageAll:EnterStage(stageTid)
    local stage = self:GetStage(stageTid,true)
    stage:Enter()
end

function StageAll:LeaveStage(stageTid)
    local stage = self:GetStage(stageTid)
    if not stage then return end
    Global:FireEvent(StorageEvent.INST_SAVE)
    stage:Leave()
end

function StageAll:GetStage(stageTid,autoGen)
    local stage = self.stages[stageTid]
    if not stage and autoGen then
        stage = StageData.new()
        stage:BindChangeNotify(self.OnStageChanged,self)
        stage:Create(stageTid)
        self.stages[stageTid] = stage
    end
    return stage
end

function StageAll:OnStageChanged(stage)
    self:MarkDirty()
    self.stageTags[stage.tid] = true
end

_G.StageAll = StageAll