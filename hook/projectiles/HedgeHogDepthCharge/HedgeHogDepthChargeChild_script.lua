--
-- Terran HedgeHog
local ADepthChargeProjectile = import("/lua/aeonprojectiles.lua").ADepthChargeProjectile
local VizMarker = import("/lua/sim/vizmarker.lua").VizMarker
local Projectile = import("/lua/sim/projectile.lua").Projectile
local EffectTemplate = import("/lua/effecttemplates.lua")

local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

local EntityMethods = moho.entity_methods
local EntityGetPosition = EntityMethods.GetPosition
local EntityGetPositionXYZ = EntityMethods.GetPositionXYZ

local UnitMethods = moho.unit_methods
local UnitGetVelocity = UnitMethods.GetVelocity
local UnitGetTargetEntity = UnitMethods.GetTargetEntity

-- upvalue moho functions for performance
local IEffectScaleEmitter = _G.moho.IEffect.ScaleEmitter
local IEffectOffsetEmitter = _G.moho.IEffect.OffsetEmitter
local ProjectileSetVelocity = _G.moho.projectile_methods.SetVelocity

HedgeHogDepthChargeChild = ClassProjectile(ADepthChargeProjectile) {
FxImpactNone = EffectTemplate.ADepthChargeHitUnderWaterUnit01,
    OnCreate = function(self, inWater)
		self:TrackTarget(false)
        self:StayUnderwater(false)
		ProjectileSetVelocity(self, 0, -1, 0)
		self:SetBallisticAcceleration(-.05)
		self:CreateImpactEffects(self:GetArmy(), self.FxEnterWater, .25 )
        Projectile.OnCreate(self, true)

    end,
OnEnterWater = function(self)
		ProjectileSetVelocity(self, 0, -1, 0)
		self:SetBallisticAcceleration(-.05)
		self.TTT1 = self:ForkThread(self.EnterWaterThread)
    end,
    EnterWaterThread = function(self)
		
		LOG("child inherited rad" .. self.DamageData.DamageRadius)
		LOG("child inherited dam " .. self.DamageData.DamageAmount)
		self.DamageData.DamageRadius = 0
		self.DamageData.DamageAmount = 50
		--LOG("child setup" .. self.DamageData.DamageRadius)
		--LOG("child setup" .. self.DamageData.Damage)
		LOG("child setup rad " .. self.DamageData.DamageRadius)
		LOG("child setup dam " .. self.DamageData.DamageAmount)

        WaitTicks(self.TrailDelay)
		local effect 
            local army = self.Army

            for i in self.FxTrails do
                effect = CreateEmitterOnEntity(self, army, self.FxTrails[i])

                -- only do these engine calls when they matter
                if self.FxTrailScale ~= 1 then 
                    IEffectScaleEmitter(effect, self.FxTrailScale)
                end

                if self.FxTrailOffset ~= 1 then 
                    IEffectOffsetEmitter(effect, 0, 0, self.FxTrailOffset)
                end
            end

            if self.PolyTrail ~= '' then
                effect = CreateTrail(self, -1, army, self.PolyTrail)

                -- only do these engine calls when they matter
                if self.PolyTrailOffset ~= 0 then 
                    IEffectOffsetEmitter(effect, 0, 0, self.PolyTrailOffset)
                end
            end


	
		local launcher = self:GetLauncher()
		local wep = launcher:GetWeaponByLabel('MortarDepthCharge')
		local wbp = wep.Blueprint
		local target = UnitGetTargetEntity(launcher)
		local targetPos
            if target then -- target is a unit / prop
			LOG("Target  -- target is a unit / prop")
                targetPos = EntityGetPosition(target)
            else -- target is a position i.e. attack ground
			LOG("Target   -- target is a position i.e. attack ground")
                targetPos = wep:GetCurrentTargetPos()
            end

		--local targetx, targety, targetz = target:GetPositionXYZ()
	
		local projx, projy, projz = self:GetPositionXYZ()
		--LOG("Target Height " .. targetPos[2])
		--LOG("Projectile Height " .. projy)

		--self.DamageData.DamageRadius = 10
		--wep:SetDamageRadius(10)
		--self:SetDamage(30, 10)
		--LOG("SetDamage ")
		
		
		while projy > 1 do
		    if target then -- target is a unit / prop
                targetPos = EntityGetPosition(target)
            else -- target is a position i.e. attack ground
                targetPos = wep:GetCurrentTargetPos()
            end
		projx, projy, projz = self:GetPositionXYZ()
		LOG("Entered While Loop " .. projy)
		WaitSeconds(.1)
		if projy <= targetPos[2] then
		self.DamageData.DamageRadius = 2.7
		self.DamageData.DamageAmount = 50
		LOG("child depth rad " .. self.DamageData.DamageRadius)
		LOG("child depth dam " .. self.DamageData.DamageAmount)
		LOG("OnImpact " .. projy)
		TargetType = "Terrain"
		self:CreateImpactEffects(self:GetArmy(), self.FxEnterWater, 1.25 )
		self:CreateImpactEffects(self.Army, self.FxImpactUnit, 1)
		self:OnImpact(TargetType, nil)
		
		end
		end

    end,

    OnImpact = function(targetType, targetEntity)
        Projectile.OnImpact(targetType, targetEntity)
        
    end,
}
TypeClass = HedgeHogDepthChargeChild