-----------------------------------------------------------------
-- File     :  /cdimage/units/UAL0401/UAL0401_script.lua
-- Author(s):  John Comes, Gordon Duclos
-- Summary  :  Aeon Galactic Colossus Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local AWalkingLandUnit = import('/lua/aeonunits.lua').AWalkingLandUnit
local WeaponsFile = import ('/lua/aeonweapons.lua')
local ADFPhasonLaser = WeaponsFile.ADFPhasonLaser
local ADFTractorClaw = WeaponsFile.ADFTractorClaw
local utilities = import('/lua/utilities.lua')
local explosion = import('/lua/defaultexplosions.lua')
local CreateAeonColossusBuildingEffects = import("/lua/effectutilities.lua").CreateAeonColossusBuildingEffects

-- upvalue for performance
local MathSqrt = math.sqrt
local MathCos = math.cos 
local MathSin = math.sin 

-- store for performance
local ZeroDegrees = Vector(0, 0, 1)
local SignCheck = Vector(1, 0, 0)

UAL0401 = Class(AWalkingLandUnit) {
	
    Weapons = {
        EyeWeapon = Class(ADFPhasonLaser) {
		        CreateProjectileAtMuzzle = function(self, muzzle)

                -- if possible, try not to fire on units that we're tractoring
                local target = self:GetCurrentTarget()
                if target then
                    local unit = (IsUnit(target) and target) or target:GetSource()
                    if unit == unit.Tractored then
                        self:ResetTarget()
                    end
                end
                ADFPhasonLaser.CreateProjectileAtMuzzle(self, muzzle)
            end,
			
		OnLostTarget = function(self, Weapon)
                local target = self:GetCurrentTarget()
                local unit = (IsUnit(target) and target) or target:GetSource()
					if IsDestroyed(target) then				
                        self.weapon:ResetTarget()
					ADFPhasonLaser.OnLostTarget(self)
						end
				end,
			},
        RightArmTractor = Class(ADFTractorClaw) {},
        LeftArmTractor = Class(ADFTractorClaw) {},
    },
	
    StartBeingBuiltEffects = function(self, builder, layer)
        AWalkingLandUnit.StartBeingBuiltEffects(self, builder, layer)
        CreateAeonColossusBuildingEffects(self)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        AWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)

        local wep = self:GetWeaponByLabel('EyeWeapon')
        local bp = wep:GetBlueprint()
        if bp.Audio.BeamStop then
            wep:PlaySound(bp.Audio.BeamStop)
        end

        if bp.Audio.BeamLoop and wep.Beams[1].Beam then
            wep.Beams[1].Beam:SetAmbientSound(nil, nil)
        end

        for k, v in wep.Beams do
            v.Beam:Disable()
        end
    end,

    DeathThread = function(self, overkillRatio , instigator)
        self:PlayUnitSound('Destroyed')
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 4.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {self:GetUnitSizes()})
        WaitSeconds(2)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B02', 1.0)
        WaitSeconds(0.1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)
        WaitSeconds(0.1)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Left_Arm_B02', 1.0)
        WaitSeconds(0.3)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Arm_B01', 1.0)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Right_Leg_B01', 1.0)

        WaitSeconds(3.5)
        explosion.CreateDefaultHitExplosionAtBone(self, 'Torso', 5.0)

        if self.DeathAnimManip then
            WaitFor(self.DeathAnimManip)
        end

        local bp = self:GetBlueprint()
        for i, numWeapons in bp.Weapon do
            if bp.Weapon[i].Label == 'CollossusDeath' then
                DamageArea(self, self:GetPosition(), bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                break
            end
        end

        self:DestroyAllDamageEffects()
        self:CreateWreckage(overkillRatio)

        -- CURRENTLY DISABLED UNTIL DESTRUCTION
        -- Create destruction debris out of the mesh, currently these projectiles look like crap,
        -- since projectile rotation and terrain collision doesn't work that great. These are left in
        -- hopes that this will look better in the future.. =)
        if self.ShowUnitDestructionDebris and overkillRatio then
            if overkillRatio <= 1 then
                self.CreateUnitDestructionDebris(self, true, true, false)
            elseif overkillRatio <= 2 then
                self.CreateUnitDestructionDebris(self, true, true, false)
            elseif overkillRatio <= 3 then
                self.CreateUnitDestructionDebris(self, true, true, true)
                self.CreateUnitDestructionDebris(self, true, true, true)
            else -- Vaporized
                self.CreateUnitDestructionDebris(self, true, true, true)
            end
        end

        self:Destroy()
    end,
}

TypeClass = UAL0401
