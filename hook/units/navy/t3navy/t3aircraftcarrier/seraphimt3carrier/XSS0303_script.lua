#****************************************************************************
#**
#**  File     :  /cdimage/units/XSS0303/XSS0303_script.lua
#**  Author(s):  Greg Kohne, Drew Staltman, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Seraphim Aircraft Carrier Script
#**
#**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SSeaUnit = import('/lua/seraphimunits.lua').SSeaUnit
local AircraftCarrier = import('/lua/defaultunits.lua').AircraftCarrier
local SeraphimWeapons = import('/lua/seraphimweapons.lua')
local SAALosaareAutoCannonWeapon = SeraphimWeapons.SAALosaareAutoCannonWeaponSeaUnit
local SLaanseMissileWeapon = SeraphimWeapons.SLaanseMissileWeapon
local Unit = import("/lua/sim/unit.lua").Unit

XSS0303 = Class(AircraftCarrier) {

    Weapons = {
        AntiAirRight = Class(SAALosaareAutoCannonWeapon) {},
        AntiAirLeft = Class(SAALosaareAutoCannonWeapon) {},
		CruiseMissile = Class(SLaanseMissileWeapon) {},
        CruiseMissiles = Class(SLaanseMissileWeapon) {},
    },
    
    
    BuildAttachBone = 'Projectile',
    FactoryAttachBone = 'HelperFactory',

    OnStopBeingBuilt = function(self,builder,layer)
        AircraftCarrier.OnStopBeingBuilt(self,builder,layer)
        self:CreateHelperFac()
        ChangeState(self, self.IdleState)
    end,

    OnFailedToBuild = function(self)
        AircraftCarrier.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    CreateHelperFac = function(self)
        -- Create helper factory and attach to attachpoint bone
        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        if not self.HelperFactory then
            --its seems that because of nonsense, spawning the module outside the unit then warping to it helps with pathfinding
            self.HelperFactory = CreateUnitHPR('SSA0001', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.HelperFactory.Parent = self
            self.HelperFactory:SetCreator(self)
            self.Trash:Add(self.HelperFactory)
        end
        if not self.ProxyAttach then
            --yeeeahhhh. attaching a helper fac directly to a carrier hides its strategic icon so we use a proxy ...
            --also for 
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
    
    OnKilled = function(self, instigator, type, overkillRatio)
        self:DestroyFacs()
        AircraftCarrier.OnKilled(self, instigator, type, overkillRatio)
    end,
    
    OnTransportDetach = function(self, attachBone, unit)
        if unit == self.ProxyAttach or self.HelperFactory then return end
        AircraftCarrier.OnTransportDetach(self, attachBone, unit)
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
            LOG("Main buildstate complete")
        end,

        OnStopBuild = function(self, unitBeingBuilt)
            if Unit.OnFailedToBuild(self) then
        ChangeState(self, self.IdleState)
            LOG("FailedToBuild Unit2")
            else
            ChangeState(self, self.FullState)
			end
            LOG("FailedToBuild Unit222")
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

TypeClass = XSS0303

