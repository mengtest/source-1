local FurnitureItem = require("app.object.entity.SceneItems.SceneItem_Furniture")local pairs = pairslocal _G = _Glocal tostring,tonumber = tostring,tonumberlocal LuaUtility = CS.Game.LuaUtilitylocal getHost = Global.GetHostlocal hostlocal FurnitureManager ={    createSceneItemTid = nil,    items = {},       --所有的item    itemTags = {}, --修改的itemFlag}--===================================================--todo: Locate import/default furnituresfunction FurnitureManager:EnterStage(stage)    host = HostPlayer    LuaUtility.BuilderSet(_G.SceneEnv.placeManager)    self.stage = stage    self:GenByImport(stage.furnitures)endfunction FurnitureManager:LeaveStage()    LuaUtility.BuilderSet()end--===================================================function FurnitureManager:GenByImport(data)    if not data then return end    for id,furnitureData in pairs(data) do        local furItem = FurnitureItem.new()        furItem:Import(furnitureData)        self.items[furItem:GetId()] = furItem        furItem:BindChangeNotify(self.OnFurnitureChanged,self)        furItem:Load()    endendfunction FurnitureManager:Export(modified)    local furnitureDatas = self.stage.furnitures    if not furnitureDatas then        furnitureDatas = {}    end    local modDatas    for id,changed in pairs(self.itemTags) do        if changed then            self.itemTags[id] = false            local idStr = tostring(id)            local item = self.items[id]            local data,mod            if item then                data,mod= item:Export(modified)                furnitureDatas[idStr] = data            else                data = {}                mod = {}                furnitureDatas[idStr] = nil            end            if mod then                if not modDatas then modDatas = {} end                modDatas[idStr] = mod            end        end    end    return furnitureDatas,modDatasendfunction FurnitureManager:Release()    for _,furniture in pairs(self.items) do        furniture:Release()    end    LuaUtility.BuilderSet(nil)    self.items = {}    self.itemTags = {}    self.stage = nil    self.createSceneItemTid = nil    self.buildDataId = nil    self.consumeTid = nil    self.consumeCount = nil    self.updateId = nilend---从c#端创建的回调function FurnitureManager:BuildFurniture(view,dir,index)    if not self.createSceneItemTid then return end    local fiItem = FurnitureItem.new()    fiItem:Born(self.createSceneItemTid)    fiItem:SetByCreate(view,dir,index,self.updateId)    self.items[fiItem:GetId()] = fiItem    self:OnFurnitureChanged(fiItem.dataModel)    if self.buildDataId then        getHost().dataModel.bag:ConsumeById(self.buildDataId)    else        getHost().dataModel.bag:Consume(self.consumeTid,self.consumeCount)    end    local canBuild = self:CanBuild()    if not canBuild then        self:SetCreateInfo()    end    return canBuildendfunction FurnitureManager:GetFurniture(id)    return self.items[id]endfunction FurnitureManager:RemoveFurniture(id)    self.stage:MarkFurnitureDirty()    self.itemTags[id] = true    self.items[id] = nilendfunction FurnitureManager:BuildUpdate(selectId,view)    if selectId and self.items[selectId] then        local updateId = self.items[selectId]:GetUpdateId()        if not updateId then            return false        end        local cfg = _G.CfgData:GetFurniture(updateId)        self.itemTags[selectId] = true        self.items[selectId]:SetUpdateInfo(cfg.mapItemId,view,cfg.levelId)        self.stage:MarkFurnitureDirty()        return true    end    return falseend--function FurnitureManager:OnFurnitureChanged(furnitureData)    local id = furnitureData.id    if id then        self.stage:MarkFurnitureDirty()        self.itemTags[id] = true    endendfunction FurnitureManager:SetCreateInfo(sceneItemTid,buildDataId,consumeTid,consumeCount,updateId)    self.createSceneItemTid = sceneItemTid    self.buildDataId = buildDataId    self.consumeTid = consumeTid    self.consumeCount = consumeCount    self.updateId = updateIdendfunction FurnitureManager:CanBuild()    if self.buildDataId then        return false    elseif self.consumeTid and self.consumeCount then        return host.dataModel.bag:TotalNum(self.consumeTid) >= self.consumeCount    end    return trueend_G.FurnitureManager = FurnitureManager