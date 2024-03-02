catapult_disembark = class({})

--------------------------------------------------------------------------------

function catapult_disembark:IsStealable()
	return false
end

--------------------------------------------------------------------------------

function catapult_disembark:OnAbilityPhaseStart()
	if IsServer() then
		self.nPreviewFX = ParticleManager:CreateParticle( "particles/dark_moon/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 252, 118, 46 ) )
	end
	return true
end

--------------------------------------------------------------------------------

function catapult_disembark:OnAbilityPhaseInterrupted()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, false )
	end
end

--------------------------------------------------------------------------------

function catapult_disembark:OnChannelFinish(bInterrupted)
    if IsServer() then
        -- 在服务器端运行的情况下执行以下操作
        if bInterrupted == false then
            -- 如果引导未被打断，则执行以下操作
            ParticleManager:DestroyParticle(self.nPreviewFX, true)
            -- 销毁之前创建的粒子效果

            local creeps = {}
            local meepos = {}
            -- 创建两个空数组，用于存放找到的小兵和米波单位

            local enemies = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), self:GetCaster():GetOrigin(), self:GetCaster(), FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, 0, false)
            -- 在施法者周围搜索所有敌方单位
            if #enemies > 0 then
                -- 如果找到了敌方单位
                for _, enemy in pairs(enemies) do
                    -- 遍历找到的每个单位
                    if enemy ~= nil and enemy:IsAlive() then
                        -- 确保单位存在且还活着
                        if enemy:GetUnitName() == "npc_dota_creature_creep_melee" then
                            -- 如果是小兵单位
                            table.insert(creeps, enemy)
                            -- 将该单位存入小兵数组
                        end
                        if enemy:GetUnitName() == "npc_dota_creature_meepo" then
                            -- 如果是米波单位
                            table.insert(meepos, enemy)
                            -- 将该单位存入米波数组
                        end
                    end
                end
            end

            if #creeps < 64 then
                -- 如果小兵数量小于 64
                local number_of_creeps = self:GetSpecialValueFor("number_of_creeps")
                -- 获取特殊数值 "number_of_creeps"，表示生成小兵的数量
                local nCreepsToSpawn = math.min(number_of_creeps, 64 - #creeps)
                -- 计算需要生成的小兵数量
                print("We have " .. #creeps .. " creeps, spawning " .. nCreepsToSpawn)
                -- 打印当前场景中已有的小兵数量和即将生成的小兵数量
                for i = 0, nCreepsToSpawn do
                    -- 循环生成小兵
                    local hCreep = CreateUnitByName("npc_dota_creature_creep_melee", self:GetCaster():GetOrigin() + RandomVector(175), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
                    -- 在施法者周围的随机位置创建小兵单位
                    if hCreep ~= nil then
                        -- 确保成功创建了单位
                        hCreep:SetOwner(self:GetCaster())
                        -- 设置小兵单位的所有者为施法者
                        hCreep:SetControllableByPlayer(self:GetCaster():GetPlayerOwnerID(), false)
                        -- 设置小兵单位为不可控制状态
                        hCreep:SetInitialGoalEntity(self:GetCaster():GetInitialGoalEntity())
                        -- 设置小兵单位的初始目标实体
                        hCreep:SetDeathXP(0)
                        -- 设置小兵单位的死亡经验值为0
                        hCreep:SetMinimumGoldBounty(0)
                        -- 设置小兵单位的最小金币奖励为0
                        hCreep:SetMaximumGoldBounty(0)
                        -- 设置小兵单位的最大金币奖励为0
                    end
                end
            end

            if #meepos < 32 then
                -- 如果米波数量小于 32
                local number_of_meepos = self:GetSpecialValueFor("number_of_meepos")
                -- 获取特殊数值 "number_of_meepos"，表示生成米波的数量
                local nMeeposToSpawn = math.min(number_of_meepos, 32 - #meepos)
                -- 计算需要生成的米波数量
                print("We have " .. #meepos .. " meepos, spawning " .. nMeeposToSpawn)
                -- 打印当前场景中已有的米波数量和即将生成的米波数量
                for i = 0, nMeeposToSpawn do
                    -- 循环生成米波
                    local hMeepo = CreateUnitByName("npc_dota_creature_meepo", self:GetCaster():GetOrigin() + RandomVector(175), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber())
                    -- 在施法者周围的随机位置创建米波单位
                    if hMeepo ~= nil then
                        -- 确保成功创建了单位
                        hMeepo:SetOwner(self:GetCaster())
                        -- 设置米波单位的所有者为施法者
                        hMeepo:SetControllableByPlayer(self:GetCaster():GetPlayerOwnerID(), false)
                        -- 设置米波单位为不可控制状态
                        hMeepo:SetInitialGoalEntity(self:GetCaster():GetInitialGoalEntity())
                        -- 设置米波单位的初始目标实体
                        hMeepo:SetDeathXP(0)
                        -- 设置米波单位的死亡经验值为0
                        hMeepo:SetMinimumGoldBounty(0)
                        -- 设置米波单位的最小金币奖励为0
                        hMeepo:SetMaximumGoldBounty(0)
                        -- 设置米波单位的最大金币奖励为0

                        local hNet = hMeepo:FindAbilityByName("creature_earthbind")
                        -- 获取米波单位的技能 "creature_earthbind"
                        if hNet ~= nil then
                            -- 如果技能存在
                            hNet:UpgradeAbility(true)
                            -- 升级技能
                        end
                    end
                end
            end
        end
    end
end

--------------------------------------------------------------------------------