-----------------------------------------------------------------
-- File     :  /cdimage/units/UAA0310/UAA0310_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon CZAR Script
-- Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------
local AirUnit = import('/lua/defaultunits.lua').AirUnit
local AAirUnit = import('/lua/aeonunits.lua').AAirUnit
local BaseTransport = import('/lua/defaultunits.lua').BaseTransport
local aWeapons = import('/lua/aeonweapons.lua')
local AQuantumBeamGenerator = aWeapons.AQuantumBeamGenerator
local AAAZealotMissileWeapon = aWeapons.AAAZealotMissileWeapon
local AANDepthChargeBombWeapon = aWeapons.AANDepthChargeBombWeapon
local AAATemporalFizzWeapon = aWeapons.AAATemporalFizzWeapon
local explosion = import('/lua/defaultexplosions.lua')
local Unit = import("/lua/sim/unit.lua").Unit

UAA0310 = Class(AirUnit, AAirUnit, BaseTransport) {
    DestroyNoFallRandomChance = 1.1,
    FactoryAttachBone = 'HelperFactory',
    BuildAttachBone = 'Attachpoint01',
    
    Weapons = {
        QuantumBeamGeneratorWeapon = Class(AQuantumBeamGenerator){},
        SonicPulseBattery1 = Class(AAAZealotMissileWeapon) {},
        SonicPulseBattery2 = Class(AAAZealotMissileWeapon) {},
        SonicPulseBattery3 = Class(AAAZealotMissileWeapon) {},
        SonicPulseBattery4 = Class(AAAZealotMissileWeapon) {},
        DepthCharge01 = Class(AANDepthChargeBombWeapon) {},
        DepthCharge02 = Class(AANDepthChargeBombWeapon) {},
        AAFizz01 = Class(AAATemporalFizzWeapon) {},
        AAFizz02 = Class(AAATemporalFizzWeapon) {},
    },

    OnKilled = function(self, instigator, type, overkillRatio)
                local CurrentRadius = self:GetIntelRadius('vision')
                local CurrentRadius = self:GetIntelRadius('Radar')
                local CurrentRadius = self:GetIntelRadius('Sonar')
                self:SetIntelRadius('Vision', 0)
                self:SetIntelRadius('Radar', 0)
                self:SetIntelRadius('Sonar', 0)
        self:DestroyFacs()
        self:DetachCargo()
        local wep = self:GetWeaponByLabel('QuantumBeamGeneratorWeapon')
        for _, v in wep.Beams do
            v.Beam:Disable()
            if wep.HoldFireThread then
                KillThread(wep.HoldFireThread)
            end
            v.Beam:Destroy()
        end

        self.detector = CreateCollisionDetector(self)
        self.Trash:Add(self.detector)
        self.detector:WatchBone('Left_Turret01_Muzzle')
        self.detector:WatchBone('Right_Turret01_Muzzle')
        self.detector:WatchBone('Left_Turret02_WepFocus')
        self.detector:WatchBone('Right_Turret02_WepFocus')
        self.detector:WatchBone('Left_Turret03_Muzzle')
        self.detector:WatchBone('Right_Turret03_Muzzle')
        self.detector:WatchBone('Attachpoint01')
        self.detector:WatchBone('Attachpoint02')
        self.detector:EnableTerrainCheck(true)
        self.detector:Enable()

        AirUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnAnimTerrainCollision = function(self, bone,x,y,z)
        DamageArea(self, {x,y,z}, 5, 1000, 'Default', true, false)
        explosion.CreateDefaultHitExplosionAtBone(self, bone, 5.0)
        explosion.CreateDebrisProjectiles(self, explosion.GetAverageBoundingXYZRadius(self), {self:GetUnitSizes()})
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        AirUnit.OnStopBeingBuilt(self,builder,layer)
		local bp = self:GetBlueprint()
                local CurrentRadius = self:GetIntelRadius('vision')
                local CurrentRadius = self:GetIntelRadius('Radar')
                local CurrentRadius = self:GetIntelRadius('Sonar')
                self:SetIntelRadius('Vision', bp.Intel.VisionRadius)
                self:SetIntelRadius('Radar', bp.Intel.RadarRadius)
                self:SetIntelRadius('Sonar', bp.Intel.SonarRadius)
        self:CreateHelperFac()
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AirUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    CreateHelperFac = function(self)
        -- Create helper factory and attach to attachpoint bone
        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        if not self.HelperFactory then

            self.HelperFactory = CreateUnitHPR('AAA0001', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
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
        BaseTransport.OnTransportDetach(self, attachBone, unit)
    end,
    
    DestroyFacs = function(self)
        --destroy our helper facs, they arent needed anymore, and this prevents the carrier from trying to detach them.
        self:DetachAll(self.FactoryAttachBone)
        if self.HelperFactory then
            self.HelperFactory:Destroy()
        end
        if self.ProxyAttach then
            self.ProxyAttach:DetachAll(2)
            self.ProxyAttach:Destroy()
        end
    end,

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
        end,

        OnStartBuild = function(self, unitBuilding, order)
		local bp = self:GetBlueprint()
            --AircraftCarrier.OnStartBuild(self, unitBuilding, order)
			if not self.loadingTransport.transData.full or table.getn(self:GetCargo()) <= bp.Transport.StorageSlots and self:TransportHasAvailableStorage() then
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
			else
			ChangeState(self, self.FullState)
			end
        end,
    },

    BuildingState = State {
        Main = function(self)
            self:SetBusy(true)
            self.UnitBeingBuilt:HideBone(0, true)
			if Unit.OnFailedToBuild(self) then
        ChangeState(self, self.IdleState)
            LOG("FailedToBuild Unit1")
            else
            ChangeState(self, self.RollingOffState)
			end
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            if Unit.OnFailedToBuild(self) then
        ChangeState(self, self.IdleState)
            LOG("FailedToBuild Unit2")
            else
            ChangeState(self, self.FullState)
			end
        end,
    },
	
    FullState = State {
        Main = function(self)
		local bp = self:GetBlueprint()
            self:SetBusy(true)
			LOG("Fullstate")
			while self.loadingTransport.transData.full or table.getn(self:GetCargo()) > bp.Transport.StorageSlots or not self:TransportHasAvailableStorage() do
			WaitSeconds(1)
			end
			if table.getn(self:GetCargo()) <= bp.Transport.StorageSlots and not self.loadingTransport.transData.full then
			ChangeState(self, self.IdleState)
			ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
			end
        end,
		LOG("Atlantis FullState done")
    },

    RollingOffState = State {
        Main = function(self)
		local bp = self:GetBlueprint()
                if self.loadingTransport.transData.full or table.getn(self:GetCargo()) >= bp.Transport.StorageSlots + 1 or not self:TransportHasAvailableStorage() then
                    --local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -20})
                    --IssueMoveOffFactory({self.UnitBeingBuilt}, worldPos)
					ChangeState(self, self.FullState)
                    self.UnitBeingBuilt:ShowBone(0,true)
                else
            self:SetBusy(true)
            self:DetachAll(self.BuildAttachBone)
            --if self.UnitBeingBuilt then
			LOG("TransportHasAvailableStorage " .. tostring(self:TransportHasAvailableStorage()))
			LOG(table.getn(self:GetCargo()))
                    self:AddUnitToStorage(self.UnitBeingBuilt)
					LOG("Addingunittostorage " .. tostring(self:TransportHasAvailableStorage()))
					ChangeState(self, self.IdleState)
					ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
                end
            --end
            
            self:SetBusy(false)
            self:RequestRefreshUI()
			LOG("Atlantis RollingOffState run")
        end,
    },
}

TypeClass = UAA0310
