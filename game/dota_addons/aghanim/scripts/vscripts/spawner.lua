if CDotaSpawner == nil then
	CDotaSpawner = class({})
end

----------------------------------------------------------------------------

-- CDotaSpawner:constructor(szSpawnerNameInput, szLocatorNameInput, rgUnitsInfoInput) 函数用于初始化 CDotaSpawner 类的实例
function CDotaSpawner:constructor(szSpawnerNameInput, szLocatorNameInput, rgUnitsInfoInput)
    -- 将传入的参数赋值给对应的成员变量
    self.szSpawnerName = szSpawnerNameInput
    self.szLocatorName = szLocatorNameInput
    self.rgUnitsInfo = rgUnitsInfoInput
    self.rgSpawners = {}  -- 刷怪点数组
    self.Encounter = nil  -- 遇到信息

    -- 返回初始化后的实例
    return self
end

----------------------------------------------------------------------------

-- CDotaSpawner:GetSpawnerType() 函数用于获取刷怪点的类型
function CDotaSpawner:GetSpawnerType()
    -- 返回刷怪点的类型字符串
    return "CDotaSpawner"
end

----------------------------------------------------------------------------

-- CDotaSpawner:Precache(context) 函数用于预加载资源
function CDotaSpawner:Precache(context)
    -- 遍历所有单位信息
    for _, rgUnitInfo in pairs(self.rgUnitsInfo) do
        -- 使用 PrecacheUnitByNameSync 函数预加载单位资源
        PrecacheUnitByNameSync(rgUnitInfo.EntityName, context, -1)
    end
end

----------------------------------------------------------------------------

-- CDotaSpawner:OnEncounterLoaded(EncounterInput) 函数用于在遇到加载完成时进行处理
function CDotaSpawner:OnEncounterLoaded(EncounterInput)
    -- 打印调试信息，表示遇到加载完成事件被调用
    print("CDotaSpawner:OnEncounterLoaded called for " .. self.szSpawnerName)
    
    -- 将遇到信息保存到成员变量 Encounter 中
    self.Encounter = EncounterInput
    
    -- 在当前房间中查找所有名称为 self.szLocatorName 的实体，即刷怪点
    self.rgSpawners = self.Encounter:GetRoom():FindAllEntitiesInRoomByName(self.szLocatorName, false)
    
    -- 如果未找到刷怪点，则输出错误信息
    if #self.rgSpawners == 0 then
        print("Failed to find entity " .. self.szSpawnerName .. " as spawner position in map " .. self.Encounter:GetRoom():GetMapName())
    end
end

----------------------------------------------------------------------------

-- CDotaSpawner:GetSpawnPositionCount() 函数用于获取刷怪点的数量
function CDotaSpawner:GetSpawnPositionCount()
    -- 返回刷怪点数组的长度，即刷怪点的数量
    return #self.rgSpawners
end

----------------------------------------------------------------------------

-- CDotaSpawner:GetSpawnCountPerSpawnPosition() 函数用于获取每个刷怪点位置生成的单位数量
function CDotaSpawner:GetSpawnCountPerSpawnPosition()
    -- 初始化单位数量为0
    local nCount = 0
    
    -- 遍历所有单位信息，累加单位数量
    for _, rgUnitInfo in pairs(self.rgUnitsInfo) do
        nCount = nCount + rgUnitInfo.Count
    end
    
    return nCount
end

----------------------------------------------------------------------------

-- CDotaSpawner:SpawnUnits() 函数用于从刷怪点生成单位
function CDotaSpawner:SpawnUnits()
    -- 如果刷怪点数组为空，则输出错误信息并返回
    if #self.rgSpawners == 0 then
        print("ERROR - Spawner " .. self.szSpawnerName .. " found no spawn entities, cannot spawn")
        return
    end

    -- 用于统计生成的单位数量
    local nSpawned = 0

    -- 用于存储所有生成的单位
    local hSpawnedUnits = {}

    -- 遍历所有刷怪点
    for nSpawnerIndex, hSpawner in pairs(self.rgSpawners) do
        -- 获取刷怪点的位置
        local vLocation = hSpawner:GetAbsOrigin()
        
        -- 对于每种单位信息，从刷怪点生成相应数量的单位
        for _, rgUnitInfo in pairs(self.rgUnitsInfo) do
            -- 从刷怪点生成单个类型的单位
            local hSingleSpawnedUnits = self:SpawnSingleUnitType(rgUnitInfo, vLocation)
            -- 更新生成的单位数量
            nSpawned = nSpawned + rgUnitInfo.Count

            -- 将生成的单位添加到 hSpawnedUnits 数组中
            for _, hUnit in pairs(hSingleSpawnedUnits) do
                table.insert(hSpawnedUnits, hUnit)
            end
        end
    end

    -- 打印生成的单位数量信息
    printf("%s spawning %d units", self.szSpawnerName, nSpawned)

    -- 如果有生成单位，则调用 Encounter:OnSpawnerFinished 方法
    if #hSpawnedUnits > 0 then
        self.Encounter:OnSpawnerFinished(self, hSpawnedUnits)
    end

    return hSpawnedUnits
end

----------------------------------------------------------------------------

-- CDotaSpawner:SpawnSingleUnitType(rgUnitInfo, vLocation) 函数用于生成单个类型的单位
function CDotaSpawner:SpawnSingleUnitType(rgUnitInfo, vLocation)
    -- 用于存储生成的单位
    local hSpawnedUnits = {}
    
    -- 循环生成指定数量的单位
    for i = 1, rgUnitInfo.Count do
        -- 根据位置信息生成单位的位置
        local vSpawnPos = vLocation
        if rgUnitInfo.PositionNoise ~= nil then
            vSpawnPos = vSpawnPos + RandomVector(RandomFloat(0.0, rgUnitInfo.PositionNoise))
        end

        -- 在指定位置创建单位
        local hUnit = CreateUnitByName(rgUnitInfo.EntityName, vSpawnPos, true, nil, nil, rgUnitInfo.Team)

        -- 如果单位创建失败，则输出错误信息
        if hUnit == nil then
            print("ERROR! Failed to spawn unit named " .. rgUnitInfo.EntityName)
        else
            -- 使单位面向生成位置
            hUnit:FaceTowards(vLocation)
            
            -- 如果有后置生成函数，则调用该函数
            if rgUnitInfo.PostSpawn ~= nil then
                rgUnitInfo.PostSpawn(hUnit)
            end
            
            -- 将生成的单位添加到 hSpawnedUnits 数组中
            table.insert(hSpawnedUnits, hUnit)
        end
    end

    return hSpawnedUnits
end

----------------------------------------------------------------------------

-- CDotaSpawner:GetSpawners() 函数用于获取一组刷怪点
function CDotaSpawner:GetSpawners()
    -- 返回刷怪点数组
    return self.rgSpawners
end

----------------------------------------------------------------------------

-- CDotaSpawner:SpawnUnitsFromRandomSpawners(nSpawners) 函数用于从随机的刷怪点中生成单位
function CDotaSpawner:SpawnUnitsFromRandomSpawners(nSpawners)
    -- 打印正在从多少个刷怪点生成单位
    print("spawning from " .. nSpawners .. " " .. self.szSpawnerName .. " spawners out of " .. #self.rgSpawners)
    
    -- 用于存储所有生成的单位
    local hAllSpawnedUnits = {}
    
    -- 如果刷怪点数组为空，则设置为nil
    local Spawners = nil
    
    -- 从随机的刷怪点中生成单位
    for n = 1, nSpawners do
        -- 如果刷怪点数组为空，或者数组中没有刷怪点了，则复制一份初始刷怪点数组
        if Spawners == nil or #Spawners == 0 then
            Spawners = deepcopy(self.rgSpawners)
        end
        
        -- 随机选择一个刷怪点
        local nIndex = math.random(1, #Spawners)
        local Spawner = Spawners[nIndex]
        
        -- 如果选择的刷怪点为空，输出错误信息
        if Spawner == nil then
            print("ERROR!  SpawnUnitsFromRandomSpawners went WRONG!!!!!!!!!!!!!")
        else
            -- 获取刷怪点的位置
            local vLocation = Spawner:GetAbsOrigin()
            
            -- 对于每种单位信息，从刷怪点生成相应单位
            for _, rgUnitInfo in pairs(self.rgUnitsInfo) do
                local hSpawnedUnits = self:SpawnSingleUnitType(rgUnitInfo, vLocation)
                
                -- 将生成的单位添加到 hAllSpawnedUnits 数组中
                for _, hUnit in pairs(hSpawnedUnits) do
                    table.insert(hAllSpawnedUnits, hUnit)
                end
            end
        end 
        
        -- 从刷怪点数组中移除已经使用过的刷怪点
        table.remove(Spawners, nIndex)
    end

    -- 如果有生成单位，则调用 Encounter:OnSpawnerFinished 方法
    if #hAllSpawnedUnits > 0 then
        self.Encounter:OnSpawnerFinished(self, hAllSpawnedUnits)
    end

    return hAllSpawnedUnits
end

----------------------------------------------------------------------------

-- CDotaSpawner:GetSpawnerName() 函数用于获取刷怪点的名称
function CDotaSpawner:GetSpawnerName()
    -- 返回刷怪点的名称
    return self.szSpawnerName
end

----------------------------------------------------------------------------

-- CDotaSpawner:GetLocatorName() 函数用于获取地图定位器的名称
function CDotaSpawner:GetLocatorName()
    -- 返回地图定位器的名称
    return self.szLocatorName
end