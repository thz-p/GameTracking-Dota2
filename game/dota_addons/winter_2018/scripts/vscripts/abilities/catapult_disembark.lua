catapult_disembark = class({})

--------------------------------------------------------------------------------

function catapult_disembark:IsStealable()
	return false
end

--------------------------------------------------------------------------------

-- 当技能施法开始时触发的函数
function catapult_disembark:OnAbilityPhaseStart()
	-- 仅在服务器端执行以下操作
	if IsServer() then
		-- 创建预览特效并附着到施法者身上
		self.nPreviewFX = ParticleManager:CreateParticle( "particles/dark_moon/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
		-- 设置特效控制点，使其跟随施法者位置
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
		-- 设置特效控制点，定义特效大小
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
		-- 设置特效控制点，定义特效颜色
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 252, 118, 46 ) )
	end
	-- 返回 true 表示技能施法继续
	return true
end

--------------------------------------------------------------------------------

function catapult_disembark:OnAbilityPhaseInterrupted()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, false )
	end
end

--------------------------------------------------------------------------------

-- 当投射结束时触发的函数
function catapult_disembark:OnChannelFinish( bInterrupted )
	-- 仅在服务器端执行以下操作
	if IsServer() then
		-- 如果投射未被打断
		if bInterrupted == false then
			-- 销毁预览特效
			ParticleManager:DestroyParticle( self.nPreviewFX, true )

			-- 初始化一个用于存储友方小兵和米波的空表
			local creeps = {}
			local meepos = {}
			
			-- 在地图上找到所有的单位（无论位置），以友方小兵和英雄作为目标
			local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCaster():GetOrigin(), self:GetCaster(), FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, 0, false )
			
			-- 如果发现了敌方单位
			if #enemies > 0 then
				-- 对于每一个发现的单位
				for _,enemy in pairs(enemies) do
					-- 如果敌人存在且还活着
					if enemy ~= nil and enemy:IsAlive() then
						-- 如果单位是友方小兵
						if enemy:GetUnitName() == "npc_dota_creature_creep_melee" then
							-- 将其加入到友方小兵表中
							table.insert( creeps, enemy )
						end 
						-- 如果单位是米波
						if enemy:GetUnitName() == "npc_dota_creature_meepo" then
							-- 将其加入到米波表中
							table.insert( meepos, enemy )
						end
					end
				end
			end

			-- 如果友方小兵数量小于64
			if #creeps < 64 then
				-- 获取生成的小兵数量
				local number_of_creeps = self:GetSpecialValueFor( "number_of_creeps" )
				local nCreepsToSpawn = math.min( number_of_creeps, 64 - #creeps )
				-- 输出日志，显示现有小兵数量和将要生成的小兵数量
				print ( "We have " .. #creeps .. " creeps, spawning " .. nCreepsToSpawn )
				-- 生成小兵
				for i=0,nCreepsToSpawn do
					local hCreep = CreateUnitByName( "npc_dota_creature_creep_melee", self:GetCaster():GetOrigin() + RandomVector( 175 ), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber() )
					-- 如果小兵生成成功
					if hCreep ~= nil then
						-- 设置小兵的所有者
						hCreep:SetOwner( self:GetCaster() )
						hCreep:SetControllableByPlayer( self:GetCaster():GetPlayerOwnerID(), false )
						hCreep:SetInitialGoalEntity( self:GetCaster():GetInitialGoalEntity() )
						hCreep:SetDeathXP( 0 )
						hCreep:SetMinimumGoldBounty( 0 )
						hCreep:SetMaximumGoldBounty( 0 )
					end
				end
			end

			-- 如果米波数量小于32
			if #meepos < 32 then
				-- 获取生成的米波数量
				local number_of_meepos = self:GetSpecialValueFor( "number_of_meepos" )
				local nMeeposToSpawn = math.min( number_of_meepos, 32 - #meepos )
				-- 输出日志，显示现有米波数量和将要生成的米波数量
				print ( "We have " .. #meepos .. " meepos, spawning " .. nMeeposToSpawn )
				-- 生成米波
				for i=0,nMeeposToSpawn do
					local hMeepo = CreateUnitByName( "npc_dota_creature_meepo", self:GetCaster():GetOrigin() + RandomVector( 175 ), true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeamNumber() )
					-- 如果米波生成成功
					if hMeepo ~= nil then
						-- 设置米波的所有者
						hMeepo:SetOwner( self:GetCaster() )
						hMeepo:SetControllableByPlayer( self:GetCaster():GetPlayerOwnerID(), false )
						hMeepo:SetInitialGoalEntity( self:GetCaster():GetInitialGoalEntity() )
						hMeepo:SetDeathXP( 0 )
						hMeepo:SetMinimumGoldBounty( 0 )
						hMeepo:SetMaximumGoldBounty( 0 )

						-- 尝试升级米波的技能“creature_earthbind”
						local hNet = hMeepo:FindAbilityByName( "creature_earthbind" )
						if hNet ~= nil then
							hNet:UpgradeAbility( true )
						end
					end
				end
			end
			
		end
	end
end

--------------------------------------------------------------------------------