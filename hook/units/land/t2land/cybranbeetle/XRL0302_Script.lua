----------------------------------------------------------------
-- File     :  /data/units/XRL0302/XRL0302_script.lua
-- Author(s):  Jessica St. Croix, Gordon Duclos
-- Summary  :  Cybran Mobile Bomb Script
-- Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local CWalkingLandUnit = import('/lua/cybranunits.lua').CWalkingLandUnit
local CMobileKamikazeBombWeapon = import('/lua/cybranweapons.lua').CMobileKamikazeBombWeapon
local EffectUtil = import("/lua/effectutilities.lua")
local EffectTemplate = import("/lua/effecttemplates.lua")

local Weapon = import("/lua/sim/weapon.lua").Weapon

--- A unique death weapon for the Fire Beetle
local DeathWeaponKamikaze = ClassWeapon(Weapon) {
    OnFire = function(self)
        -- do regular death weapon of unit if we didn't already
        if not self.unit.Dead then 
            self.unit:Kill()
        end
    end,
}

--- A unique death weapon for the Fire Beetle
local DeathWeapon = Class(Weapon) {

	FxDeath = EffectTemplate.CMobileKamikazeBombExplosion,

    OnCreate = function(self)
        Weapon.OnCreate(self)
        self:SetWeaponEnabled(false)
    end,

    Fire = function(self)
        local blueprint = self:GetBlueprint()
        local position = self.unit:GetPosition()
        local army = self.unit.Army
        for k, v in self.FxDeath do
            CreateEmitterAtBone(self.unit, -2, army, v)
			end
			if not self.unit.transportDrop then
            
            local rotation = math.random(0, 6.28)
            
            DamageArea( self.unit, position, 6, 1, 'TreeForce', true )
            DamageArea( self.unit, position, 6, 1, 'TreeForce', true )
            
            CreateDecal( position, rotation, 'scorch_010_albedo', '', 'Albedo', 11, 11, 250, 120, army)
        end
        DamageArea(self.unit, position, blueprint.DamageRadius, blueprint.Damage, blueprint.DamageType or 'Normal', blueprint.DamageFriendly or false)
        self.unit:PlayUnitSound('Destroyed')
        self.unit:Destroy()
    end,
}

XRL0302 = ClassUnit(CWalkingLandUnit) {
	IntelEffects = {
        Cloak = {
            {
                Bones = {
                    'XRL0302',
                },
                Scale = 3.0,
                Type = 'Cloak01',
            },
        },
    },

    Weapons = {
        Suicide = Class(CMobileKamikazeBombWeapon) {},
        DeathWeapon = ClassWeapon(DeathWeapon) {},
    },
		AmbientExhaustBones = {
        'XRL0302',
    },

    AmbientLandExhaustEffects = {
        '/effects/emitters/cannon_muzzle_smoke_12_emit.bp',
    },

    OnCreate = function(self)
        CWalkingLandUnit.OnCreate(self)

        self.EffectsBagXRL = TrashBag()
        self.AmbientExhaustEffectsBagXRL = TrashBag()
        self:CreateTerrainTypeEffects(self.IntelEffects.Cloak, 'FXIdle',  self.Layer, nil, self.EffectsBagXRL)
        self.PeriodicFXThread = self:ForkThread(self.EmitPeriodicEffects)
    end,
	    --- Adds the cloaking mesh to the unit to hide it
    HideUnit = function(self)
        WaitTicks(1)
        self:SetMesh(self:GetBlueprint().Display.CloakMeshBlueprint, true)
    end,
    -- Allow the trigger button to blow the weapon, resulting in OnKilled instigator 'nil'
	OnProductionPaused = function(self)
        self:GetWeaponByLabel('Suicide'):FireWeapon()

    end,

    EmitPeriodicEffects = function(self)
	
        local army = self.Army
        local ambientLandExhaustEffects = self.AmbientLandExhaustEffects
        local ambientExhaustBones = self.AmbientExhaustBones

        while not self.Dead do

            -- create the effects
            --for kE, vE in ambientLandExhaustEffects do
                --for kB, vB in ambientExhaustBones do
                    --CreateAttachedEmitter(self, vB, army, vE)
                --end
            --end

            WaitSeconds(3)
        end
    end,

    DoDeathWeapon = function(self)

        if self:IsBeingBuilt() then return end

        -- handle regular death weapon procedures
        CWalkingLandUnit.DoDeathWeapon(self)

        -- clean up some effects
        self.EffectsBagXRL:Destroy()
        self.AmbientExhaustEffectsBagXRL:Destroy()

        -- stop the periodice effects
        self.PeriodicFXThread:Destroy()
        self.PeriodicFXThread = nil


    end, 	
	
    OnScriptBitSet = function(self, bit)
        if bit == 8 then
            self.AutoCloack = false
            ChangeState( self, self.VisibleState )
        else
            CWalkingLandUnit.OnScriptBitSet(self, bit)
        end
    end,

    OnScriptBitClear = function(self, bit)
        if bit == 8 then
            self.AutoCloack = true
            if not self:IsMoving() then
                ChangeState( self, self.InvisState )
            end
        else
            CWalkingLandUnit.OnScriptBitClear(self, bit)
        end
    end,

    OnAttachedToTransport = function(self, transport, transportBone)
        ChangeState( self, self.VisibleState )
        CWalkingLandUnit.OnAttachedToTransport(self, transport, transportBone)
    end,

    OnDetachedFromTransport = function(self, transport, transportBone)
        if self.AutoCloack == true then
            ChangeState( self, self.InvisState )
        end
        CWalkingLandUnit.OnDetachedFromTransport(self, transport, transportBone)
    end,

    OnStopBeingBuilt = function(self, builder, layer)
        CWalkingLandUnit.OnStopBeingBuilt(self, builder, layer)
        --These start enabled, so before going to InvisState, disabled them.. they'll be reenabled shortly
        self:DisableUnitIntel('RadarStealth')
        self:DisableUnitIntel('Cloak')
        self.Cloaked = false
        self.AutoCloack = true
        ChangeState( self, self.InvisState ) -- If spawned in we want the unit to be invis, normally the unit will immediately start moving
		--self:ForkThread(self.HideUnit, self)
    end,

    OnKilled = function(self, instigator, type, overkillRatio)
        CWalkingLandUnit.OnKilled(self, instigator, type, overkillRatio)
            self:GetWeaponByLabel('Suicide'):FireWeapon()
    end,


    InvisState = State() {
        Main = function(self)
            self.Cloaked = false
            local bp = self:GetBlueprint()
            if bp.Intel.StealthWaitTime then
                WaitSeconds( bp.Intel.StealthWaitTime )
            end
            self:EnableUnitIntel('RadarStealth')
            self:EnableUnitIntel('Cloak')
            self:SetMaintenanceConsumptionActive()
            self.Cloaked = true
        end,

        OnMotionHorzEventChange = function(self, new, old)
            if new != 'Stopped' and self.AutoCloack == true then
                ChangeState( self, self.VisibleState )
            end
            CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },

    VisibleState = State() {
        Main = function(self)
            if self.Cloaked then
                self:DisableUnitIntel('RadarStealth')
                self:DisableUnitIntel('Cloak')
	        self:SetMaintenanceConsumptionInactive()
            end
        end,

        OnMotionHorzEventChange = function(self, new, old)
            if new == 'Stopped' and self.AutoCloack == true then
                ChangeState( self, self.InvisState )
            end
            CWalkingLandUnit.OnMotionHorzEventChange(self, new, old)
        end,
    },
}

TypeClass = XRL0302
