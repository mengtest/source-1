local PointMapData = class("PointMapData",require("app.base.DataModel"))local eventMap_saveFields = {"tid","lastOpenTime","randomTime","posIndex","timeLock","dayOpenNum"}local getSystem = Global.GetSystemlocal Timer = Timerfunction PointMapData:MarkSave()    self:MarkFieldSave(eventMap_saveFields)endfunction PointMapData:Import(data)    PointMapData.super.Import(self, data)endfunction PointMapData:Export(modified)    local data,mod = PointMapData.super.Export(self,modified)    return data,modendfunction PointMapData:Init(tid,lastOpenTime,randomTime,posIndex,timeLock,dayOpenNum)    self:SetValue("tid",tid,true)    self:SetValue("lastOpenTime",lastOpenTime,true)    self:SetValue("randomTime",randomTime,true)    self:SetValue("posIndex",posIndex,true)    self:SetValue("timeLock",timeLock,true)    self:SetValue("dayOpenNum",dayOpenNum,true)    print("<color=blue>SetPointEvent Value</color>",self.tid,self.lastOpenTime,self.posIndex,self.timeLock,self.dayOpenNum)end--监听倒计时事件function PointMapData:StartPointEventCountDown()    if self.randomTime then        local dropExistTime = self.lastOpenTime + self.randomTime - getSystem():CurrentTime()        if dropExistTime > 0 then            self.dropExistTime = dropExistTime            self.activeTime = Timer.Once(dropExistTime,self.FinishCountDown,self):RegisterCd(self.ListenCountDown,self):Start()        end    endendfunction PointMapData:StopPointEventCountDown()    if self.activeTime then        self.activeTime:Stop()        self.activeTime = nil    end    self.activeTimeListener=nil    self.finishActiveListener=nilendfunction PointMapData:AddListenCountDownListener(listener,owner)    self.activeTimeListener = listener    self.activeTimeOwner = ownerendfunction PointMapData:RemoveFinishAttackListener()    self.finishActiveListener = nilendfunction PointMapData:RemoveListenCountDownListener()    self.activeTimeListener = nilendfunction PointMapData:AddFinishCountDownListener(listener,owner)    self.finishActiveListener = listener    self.finishActiveOwner = ownerendfunction PointMapData:ListenCountDown(time)    if self.activeTimeListener then        self.activeTimeListener(self.activeTimeOwner, self.dropExistTime - time)    endendfunction PointMapData:FinishCountDown()    self.totalSeconds = nil    if self.finishActiveListener then        self.finishActiveListener(self.finishActiveOwner)    endend---function PointMapData:GetTimeLock()   return self.timeLockendfunction PointMapData:SetTimeLock(timeLock)    self:SetValue("timeLock",timeLock,true)endfunction PointMapData:SetLastOpenTime(lastOpenTime)    self:SetValue("lastOpenTime",lastOpenTime,true)endfunction PointMapData:SetRandomTime(randomTime)    self:SetValue("randomTime",randomTime,true)endfunction PointMapData:GetDayOpenNum()    --每天重置不叠加    if getSystem():GetDayDeltaTime() > 0 then        self:SetValue("dayOpenNum",0,true)    end    return self.dayOpenNumendreturn PointMapData