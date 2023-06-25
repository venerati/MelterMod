--------------------------------------------------------------------------------
-- File :  /units/XRL0403/XRL0403_script.lua
-- Summary  :  Megalith script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--------------------------------------------------------------------------------
local CWalkingLandUnit = import("/lua/cybranunits.lua").CWalkingLandUnit
local MobileUnit = import("/lua/defaultunits.lua").MobileUnit
local explosion = import("/lua/defaultexplosions.lua")
local CreateDeathExplosion = explosion.CreateDefaultHitExplosionAtBone
local EffectTemplate = import("/lua/effecttemplates.lua")
local utilities = import("/lua/utilities.lua")
local EffectUtil = import("/lua/effectutilities.lua")
local Entity = import("/lua/sim/entity.lua").Entity
local Weapon = import("/lua/sim/weapon.lua").Weapon
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFHvyProtonCannonWeapon = CybranWeaponsFile.CDFHvyProtonCannonWeapon
local CANNaniteTorpedoWeapon = CybranWeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = CybranWeaponsFile.CIFSmartCharge
local CAABurstCloudFlakArtilleryWeapon = CybranWeaponsFile.CAABurstCloudFlakArtilleryWeapon
local CDFBrackmanCrabHackPegLauncherWeapon = CybranWeaponsFile.CDFBrackmanCrabHackPegLauncherWeapon
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread
local CreateUEFBuildSliceBeams = EffectUtil.CreateUEFBuildSliceBeams
local TMobileFactoryUnit = import('/lua/terranunits.lua').TMobileFactoryUnit

---@class XRL0403 : CWalkingLandUnit
XRL0403 = ClassUnit(CWalkingLandUnit) {
    BuildAttachBone = 'Attachpoint01',
    FactoryAttachBone = 'HelperFactory',
    RollOffBones = { 'Attachpoint01' },
    PrepareToBuildAnimRate = 2,
    WalkingAnimRate = 1.2,

    CreateHelperFac = function(self)

        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        if not self.HelperFactory then

            self.HelperFactory = CreateUnitHPR('RLL0001', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.HelperFactory.Parent = self
            self.HelperFactory:SetCreator(self)
            self.Trash:Add(self.HelperFactory)
        end
        if not self.ProxyAttach then

            self.ProxyAttach = CreateUnitHPR('ZXB0302', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.ProxyAttach.Parent = self
            self.ProxyAttach:SetCreator(self)
            self.Trash:Add(self.ProxyAttach)
        end
        self:DetachAll(self.FactoryAttachBone)
        self.ProxyAttach:DetachAll(2)
        self.HelperFactory:AttachTo(self.ProxyAttach, 2)
        self.ProxyAttach:AttachTo(self, self.FactoryAttachBone)
        
        self:SetFactoryRestrictions()
    end,
    
    SetFactoryRestrictions = function(self)
        if not self.HelperFactory then return end
        local restrictions = self:GetBlueprint().Economy.BuildableCategoryMobile
        self.HelperFactory:AddBuildRestriction(categories.ALLUNITS)
        for k,category in restrictions do
            local parsedCat = ParseEntityCategory(category)
            self.HelperFactory:RemoveBuildRestriction(parsedCat)
        end
        self.HelperFactory:RequestRefreshUI()
    end,
    
    OnTransportDetach = function(self, attachBone, unit)
        if unit == self.ProxyAttach or self.HelperFactory then return end
        TSeaUnit.OnTransportDetach(self, attachBone, unit)
		ChangeState(self, self.IdleState)
		LOG("Atlantis OnTransportDetach done")
    end,
	
    IdleState = State {
        OnStartBuild = function(self, unitBuilding, order)
            --TMobileFactoryUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            self.PrepareToBuildManipulator:SetRate(-self.PrepareToBuildAnimRate)
            ChangeState(self, self.BuildingState)
        end,

        Main = function(self)
            self.PrepareToBuildManipulator:SetRate(-self.PrepareToBuildAnimRate)
            self:DetachAll(self.BuildAttachBone)
            --self:SetBusy(false)
        end,
    },

    BuildingState = State {
        Main = function(self)
            self.PrepareToBuildManipulator:SetRate(-self.PrepareToBuildAnimRate)
            WaitFor(self.PrepareToBuildManipulator)
            self.UnitBeingBuilt:ShowBone(0,true)
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            ChangeState(self, self.RollingOffState)
        end,
    },

    RollingOffState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            if not unitBuilding:IsDead() then
                unitBuilding:ShowBone(0,true)
            end
            self.PrepareToBuildManipulator:SetRate(self.PrepareToBuildAnimRate)
            WaitFor(self.PrepareToBuildManipulator)
            WaitFor(self.AttachmentSliderManip)
            
            self:CreateRollOffEffects()
            self.AttachmentSliderManip:SetSpeed(20)
            self.AttachmentSliderManip:SetGoal(0, -20, 0)
            WaitFor(self.AttachmentSliderManip)
            
            self.AttachmentSliderManip:SetGoal(0, -20, 0)
            WaitFor(self.AttachmentSliderManip)
            
            if not unitBuilding:IsDead() then
                unitBuilding:DetachFrom(true)
                self:DetachAll(self.BuildAttachBone)
                local  worldPos = self:CalculateWorldPositionFromRelative({0, 0, -15})
                IssueStop( {unitBuilding} ) --the unit gets engine orders to move to a point not far off the fac
                IssueClearCommands( {unitBuilding} ) --so we need to cancel them since they dont get updated
                IssueMoveOffFactory({unitBuilding}, worldPos)
            end
            
            --reset the slider
            self.AttachmentSliderManip:SetGoal(0, 0, 0)
            self.AttachmentSliderManip:SetSpeed(90)
            WaitSeconds(0.2)
            
            self:DestroyRollOffEffects()
            ChangeState(self, self.IdleState)
            ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
        end,
    },

    CreateRollOffEffects = function(self, unit)
        local army = self:GetArmy()
        local unitB = self.UnitBeingBuilt
        if unitB:IsDead() then WARN('tried to attach effects to a dead unit') return end
        for k, v in self.RollOffBones do
            local fx = AttachBeamEntityToEntity(self, v, unitB, -1, army, EffectTemplate.TTransportBeam01)
            table.insert( self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            
            fx = AttachBeamEntityToEntity( unitB, -1, self, v, army, EffectTemplate.TTransportBeam02)
            table.insert( self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
            
            fx = CreateEmitterAtBone( self, v, army, EffectTemplate.TTransportGlow01)
            table.insert( self.ReleaseEffectsBag, fx)
            self.Trash:Add(fx)
        end
    end,

    DestroyRollOffEffects = function(self)
        for k, v in self.ReleaseEffectsBag do
            v:Destroy()
        end
        self.ReleaseEffectsBag = {}
    end,
	
    Weapons = {
        ParticleGunRight = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        ParticleGunLeft = ClassWeapon(CDFHvyProtonCannonWeapon) {},
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo02 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo03 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        Torpedo04 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedo = ClassWeapon(CIFSmartCharge) {},
        AAGun = ClassWeapon(CAABurstCloudFlakArtilleryWeapon) {},
        HackPegLauncher = ClassWeapon(CDFBrackmanCrabHackPegLauncherWeapon){},
    },

    DisableAllButHackPegLauncher= function(self)
        self:SetWeaponEnabledByLabel('ParticleGunRight', false) -- -- -- Disable all other weapons.
        self:SetWeaponEnabledByLabel('ParticleGunLeft', false)
        self:SetWeaponEnabledByLabel('AAGun', false)
        self:SetWeaponEnabledByLabel('Torpedo01', false)

        self:ShowBone('Missile_Turret', true)
    end,

    EnableHackPegLauncher= function(self)
        self:SetWeaponEnabledByLabel('HackPegLauncher', true)   -- -- -- Enable and show hack-peg launcher.
    end,

    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)
        self:SetWeaponEnabledByLabel('HackPegLauncher', false)
        if self:IsValidBone('Missile_Turret') then
            self:HideBone('Missile_Turret', true)
        end
    end,
	
    OnStartBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStartBeingBuilt(self, builder, layer)

        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end

        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false):SetRate(0)

        -- adjust collision box due to build animation
        self:SetCollisionShape(
            'Box', 
            self.Blueprint.CollisionOffsetX,
            self.Blueprint.CollisionOffsetY,
            self.Blueprint.CollisionOffsetZ,
            0.5 * self.Blueprint.SizeX,
            0.5 * self.Blueprint.SizeY,
            0.5 * self.Blueprint.SizeZ
        )

    end,

    OnStopBeingBuilt = function(self,builder,layer)
        CWalkingLandUnit.OnStopBeingBuilt(self,builder,layer)
        if not self.AnimationManipulator then
            self.AnimationManipulator = CreateAnimator(self)
            self.Trash:Add(self.AnimationManipulator)
        end

        self.AnimationManipulator:PlayAnim(self:GetBlueprint().Display.AnimationActivate, false):SetRate(0)
        TMobileFactoryUnit.OnStopBeingBuilt(self,builder,layer)
        self.EffectsBag = {}
        self.PrepareToBuildManipulator = CreateAnimator(self)
        self.PrepareToBuildManipulator:PlayAnim(self:GetBlueprint().Display.AnimationBuild, false):SetRate(0)
        self.ReleaseEffectsBag = {}
        self.AttachmentSliderManip = CreateSlider(self, self.BuildAttachBone)
        self:CreateHelperFac()
        if layer == 'Land' then
            self:SetFactoryRestrictions()
        elseif layer == 'Seabed' then
            self.HelperFactory:AddBuildRestriction(categories.ALLUNITS)
            self.HelperFactory:RemoveBuildRestriction(categories.xrl0003)
            self.HelperFactory:RemoveBuildRestriction(categories.xrl0008)
            self.HelperFactory:RequestRefreshUI()
			end
        ChangeState(self, self.IdleState)

        -- adjust collision box due to build animation

        ForkThread(function()
            self:SetCollisionShape('Box', 0, 1.7, -0.3, 2.5, 1.7, 3.5)
            WaitSeconds(1.5)
            self:RevertCollisionShape()--set the collision so its above the legs
        end)

        if self:IsValidBone('Missile_Turret') then
            self:HideBone('Missile_Turret', true)
        end

        if self.AnimationManipulator then
            self:SetUnSelectable(false)
            self.AnimationManipulator:SetRate(1)

            self:ForkThread(function()
                WaitSeconds(self.AnimationManipulator:GetAnimationDuration()*self.AnimationManipulator:GetRate())
                self:SetUnSelectable(false)
                self.AnimationManipulator:Destroy()
            end)
        end
    end,

    OnLayerChange = function(self, new, old)
        CWalkingLandUnit.OnLayerChange(self, new, old)

        if new == 'Land' then
            self:DisableUnitIntel('Layer', 'Sonar')
            -- Set movement speed to default
            self:SetSpeedMult(1)
        elseif new == 'Seabed' then
            self:EnableUnitIntel('Layer', 'Sonar')
            -- Increase speed while in water
            self:SetSpeedMult(self:GetBlueprint().Physics.WaterSpeedMultiplier)
        end
    end,

    CreateDamageEffects = function(self, bone, army)
        for k, v in EffectTemplate.DamageFireSmoke01 do
            CreateAttachedEmitter(self, bone, army, v):ScaleEmitter(1.5)
        end
    end,

    CreateDeathExplosionDustRing = function(self)
        local blanketSides = 18
        local blanketAngle = (2*math.pi) / blanketSides
        local blanketStrength = 1
        local blanketVelocity = 2.8

        for i = 0, (blanketSides-1) do
            local blanketX = math.sin(i*blanketAngle)
            local blanketZ = math.cos(i*blanketAngle)

            local Blanketparts = self:CreateProjectile('/effects/entities/DestructionDust01/DestructionDust01_proj.bp', blanketX, 1.5, blanketZ + 4, blanketX, 0, blanketZ)
                :SetVelocity(blanketVelocity):SetAcceleration(-0.3)
        end
    end,

    CreateFirePlumes = function(self, army, bones, yBoneOffset)
        local proj, position, offset, velocity
        local basePosition = self:GetPosition()
        for k, vBone in bones do
            position = self:GetPosition(vBone)
            offset = utilities.GetDifferenceVector(position, basePosition)
            velocity = utilities.GetDirectionVector(position, basePosition) --
            velocity.x = velocity.x + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.z = velocity.z + utilities.GetRandomFloat(-0.3, 0.3)
            velocity.y = velocity.y + utilities.GetRandomFloat(0.0, 0.3)
            proj = self:CreateProjectile('/effects/entities/DestructionFirePlume01/DestructionFirePlume01_proj.bp', offset.x, offset.y + yBoneOffset, offset.z, velocity.x, velocity.y, velocity.z)
            proj:SetBallisticAcceleration(utilities.GetRandomFloat(-1, -2)):SetVelocity(utilities.GetRandomFloat(3, 4)):SetCollision(false)

            local emitter = CreateEmitterOnEntity(proj, army, '/effects/emitters/destruction_explosion_fire_plume_02_emit.bp')

            local lifetime = utilities.GetRandomFloat(12, 22)
        end
    end,

    CreateExplosionDebris = function(self, army)
        for k, v in EffectTemplate.ExplosionDebrisLrg01 do
            CreateAttachedEmitter(self, 'XRL0403', army, v):OffsetEmitter(0, 5, 0)
        end
    end,

    DeathThread = function(self)
        self:PlayUnitSound('Destroyed')
        local army = self.Army

        -- Create Initial explosion effects
        explosion.CreateFlash(self, 'Left_Leg01_B01', 4.5, army)
        CreateAttachedEmitter(self, 'XRL0403', army, '/effects/emitters/destruction_explosion_concussion_ring_03_emit.bp'):OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self,'XRL0403', army, '/effects/emitters/explosion_fire_sparks_02_emit.bp'):OffsetEmitter(0, 5, 0)
        CreateAttachedEmitter(self,'XRL0403', army, '/effects/emitters/distortion_ring_01_emit.bp')
        self:CreateFirePlumes(army, {'XRL0403'}, 0)

        self:CreateFirePlumes(army, {'Right_Leg01_B01','Right_Leg02_B01','Left_Leg02_B01',}, 0.5)

        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        WaitSeconds(1)

        -- Create damage effects on turret bone
        CreateDeathExplosion(self, 'Right_Turret_Barrel', 1.5)
        self:CreateDamageEffects('Right_Turret_Barrel', army)
        self:CreateDamageEffects('Left_Turret_Barrel', army)

        WaitSeconds(1)
        self:CreateFirePlumes(army, {'Right_Leg01_B01','Right_Leg02_B01','Left_Leg02_B01',}, 0.5)
        WaitSeconds(0.4)
        self:CreateDeathExplosionDustRing()
        
        -- only apply death damage when the unit is sufficiently build
        local bp = self:GetBlueprint()
        local FractionThreshold = bp.General.FractionThreshold or 0.99
        if self:GetFractionComplete() >= FractionThreshold then 
            local bp = self:GetBlueprint()
            local position = self:GetPosition()
            local qx, qy, qz, qw = unpack(self:GetOrientation())
            local a = math.atan2(2.0 * (qx * qz + qw * qy), qw * qw + qx * qx - qz * qz - qy * qy)
            for i, numWeapons in bp.Weapon do
                if(bp.Weapon[i].Label == 'MegalithDeath') then
                    position[3] = position[3]+2.5*math.cos(a)
                    position[1] = position[1]+2.5*math.sin(a)
                    DamageArea(self, position, bp.Weapon[i].DamageRadius, bp.Weapon[i].Damage, bp.Weapon[i].DamageType, bp.Weapon[i].DamageFriendly)
                    break
                end
            end
        end
        
        WaitSeconds(0.4)


        -- When the spider bot impacts with the ground
        -- Effects: Explosion on turret, dust effects on the muzzle tip, large dust ring around unit
        -- Other: Damage force ring to force trees over and camera shake
        self:ShakeCamera(40, 4, 1, 3.8)
        CreateDeathExplosion(self, 'Left_Turret_Barrel', 1)

        self:CreateExplosionDebris(army)
        self:CreateExplosionDebris(army)

        local x, y, z = unpack(self:GetPosition())
        z = z + 3
        DamageRing(self, {x,y,z}, 0.1, 3, 1, 'Force', true)
        WaitSeconds(0.5)
        CreateDeathExplosion(self, 'Right_Turret', 2)

        -- Finish up force ring to push trees
        DamageRing(self, {x,y,z}, 0.1, 3, 1, 'Force', true)

        -- Explosion on and damage fire on various bones
        CreateDeathExplosion(self, 'Right_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        CreateDeathExplosion(self, 'Flare_Muzzle03', 2)
        self:CreateFirePlumes(army, {'Torpedo_Muzzle11'}, -1)
        self:CreateDamageEffects('Right_Turret', army)
        WaitSeconds(0.5)

        CreateDeathExplosion(self, 'Left_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        self:CreateDamageEffects('Right_Footfall_02', army)
        WaitSeconds(0.5)
        CreateDeathExplosion(self, 'Left_Turret_Muzzle01', 1)
        self:CreateExplosionDebris(army)

        CreateDeathExplosion(self, 'Right_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        self:CreateDamageEffects('Torpedo_Muzzle01', army)
        WaitSeconds(0.5)

        CreateDeathExplosion(self, 'Left_Leg0' .. Random(1,2) .. '_B0' .. Random(1,2), 0.25)
        CreateDeathExplosion(self, 'Flare_Muzzle06', 2)
        self:CreateDamageEffects('Left_Leg02_B02', army)
        explosion.CreateFlash(self, 'Right_Leg01_B01', 3.2, army)

        self:CreateWreckage(0.1)
        self:ShakeCamera(3, 2, 0, 0.15)
        self:Destroy()
    end,


    OnMotionHorzEventChange = function(self, new, old)
        CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)

        if (old == 'Stopped') then
            local bpDisplay = self:GetBlueprint().Display
            if bpDisplay.AnimationWalk and self.Animator then
                self.Animator:SetDirectionalAnim(true)
                self.Animator:SetRate(bpDisplay.AnimationWalkRate)
            end
         end
    end,
}

TypeClass = XRL0403