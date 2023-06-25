-----------------------------------------------------------------
-- File     :  /cdimage/units/UES0401/UES0401_script.lua
-- Author(s):  John Comes, David Tomandl
-- Summary  :  UEF Experimental Submersible Aircraft Carrier Script
-- Copyright Â© 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local TSeaUnit = import('/lua/terranunits.lua').TSeaUnit
local TANTorpedoAngler = import('/lua/terranweapons.lua').TANTorpedoAngler
local TSAMLauncher = import('/lua/terranweapons.lua').TSAMLauncher
local EffectUtil = import('/lua/EffectUtilities.lua')
local CreateBuildCubeThread = EffectUtil.CreateBuildCubeThread
local TAAFlakArtilleryCannon = import('/lua/terranweapons.lua').TAAFlakArtilleryCannon
local WeaponFile = import("/lua/terranweapons.lua")
local TIFSmartCharge = WeaponFile.TIFSmartCharge
local WeaponsFile = import("/lua/cybranweapons.lua")
local CIFSmartCharge = WeaponsFile.CIFSmartCharge
local Unit = import("/lua/sim/unit.lua").Unit

UES0401 = Class(TSeaUnit) {
    BuildAttachBone = 'Attachpoint06',
    FactoryAttachBone = 'HelperFactory',

    Weapons = {
        Torpedo01 = Class(TANTorpedoAngler) {},
        Torpedo02 = Class(TANTorpedoAngler) {},
        Torpedo03 = Class(TANTorpedoAngler) {},
        Torpedo04 = Class(TANTorpedoAngler) {},
        MissileRack01 = Class(TSAMLauncher) {},
        MissileRack02 = Class(TSAMLauncher) {},
        MissileRack03 = Class(TSAMLauncher) {},
        MissileRack04 = Class(TSAMLauncher) {},
        AAGun = Class(TAAFlakArtilleryCannon) {},
        AntiTorpedoDown = ClassWeapon(TIFSmartCharge) {},
        AntiTorpedoUp = ClassWeapon(CIFSmartCharge) {},
    },

    OnKilled = function(self, instigator, type, overkillRatio)
        self:DestroyFacs()
        TSeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    OnCreate = function(self)
        TSeaUnit.OnCreate(self) 
        self.OpenAnimManips = {}
        self.OpenAnimManips[1] = CreateAnimator(self):PlayAnim('/mods/Superior FAF Experience/hook/units/experimentals/Atlantis/ues0401_aopen.sca'):SetRate(-1)
        for i = 2, 6 do
            self.OpenAnimManips[i] = CreateAnimator(self):PlayAnim('/mods/Superior FAF Experience/hook/units/experimentals/Atlantis/ues0401_aopen0' .. i .. '.sca'):SetRate(-1)
        end

        for k, v in self.OpenAnimManips do
            self.Trash:Add(v)
        end

        if self:GetCurrentLayer() == 'Water' then
		LOG("current layer water")
            self:PlayAllOpenAnims(true)
        end
		LOG("Atlantis oncreate done")
    end,

    StartBeingBuiltEffects = function(self, builder, layer)
        self:SetMesh(self:GetBlueprint().Display.BuildMeshBlueprint, true)
        if self:GetBlueprint().General.UpgradesFrom ~= builder:GetUnitId() then
            self:HideBone(0, true)        
            self.OnBeingBuiltEffectsBag:Add(self:ForkThread(CreateBuildCubeThread, builder, self.OnBeingBuiltEffectsBag))
        end
		LOG("Atlantis StartBuildingEffects done")
    end,

    PlayAllOpenAnims = function(self, open)
        for k, v in self.OpenAnimManips do
            if open then
                v:SetRate(1)
            else
                v:SetRate(-1)
            end
        end
    end,

    OnMotionVertEventChange = function( self, new, old )
        TSeaUnit.OnMotionVertEventChange(self, new, old)
        --we want to be able to build underwater but only when our atlantis has enough space for it.
		-- Surfacing and sinking, landing and take off idle effects
		local layerV = self.Layer
        if new == 'Down' then
            self:PlayAllOpenAnims(false)
            self:RemoveCommandCap("RULEUCC_Transport")
            self:RequestRefreshUI()
        elseif new == 'Top' then
            self:PlayAllOpenAnims(true)
            self:AddCommandCap("RULEUCC_Transport")
            self:RequestRefreshUI()
        end
		
		if new == 'Down' and layerV == 'Water' then
            self:RemoveCommandCap("RULEUCC_Transport")
            self:RequestRefreshUI()
			self:ForkThread(self.ContractingVision, self)
        end			

        if new == 'Up' and old == 'Bottom' then -- When starting to surface
            self:RemoveCommandCap("RULEUCC_Transport")
            self:RequestRefreshUI()
            self.WatchDepth = false
        end

        if new == 'Bottom' and old == 'Down' then -- When finished diving
            self:AddCommandCap("RULEUCC_Transport")
            self:RequestRefreshUI()
            self.WatchDepth = true
            if not self.DiverThread then
                self.DiverThread = self:ForkThread(self.DiveDepthThread)
			end
        end
		LOG("Atlantis OnMotionVertEventChange done")
        --ChangeState(self, self.IdleState)
        --ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
    end,

    DiveDepthThread = function(self)
        -- Takes the given location, adjusts the Y value to the surface height on that location, with an offset
        local Yoffset = 1.2 -- The default (built in) offset appears to be 0.25 - if the place where thats set is found, that would be epic.
        -- 1.2 is for tempest to clear the torpedo tubes from most cases of ground clipping, keeping overall height minimal.
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) -- Target depth, in this case the seabed
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5) -- Doesnt sink too much, just maneuveres the bed better.
            self.SinkSlider:SetSpeed(1)
            
            self.SinkSlider:SetGoal(0, difference, 0)
            WaitSeconds(1)
        end

        self.SinkSlider:SetGoal(0, 0, 0) -- Reset the slider while we are not watching depth
        WaitFor(self.SinkSlider)-- We have to wait for it to finish before killing the thread or it stops

        KillThread(self.DiverThread)
		LOG("Atlantis DiveDepthThread done")
    end,

    OnStopBeingBuilt = function(self,builder,layer)
        TSeaUnit.OnStopBeingBuilt(self,builder,layer)
        self:CreateHelperFac()
        ChangeState(self, self.IdleState)
        ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
        if not self.SinkSlider then -- Setup the slider and get blueprint values
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true) -- Create sink controller to overlay ontop of original collision detection
            self.Trash:Add(self.SinkSlider)
        end

        self.WatchDepth = false
		LOG("Atlantis OnStopBeingBuilt done")
    end,

    OnFailedToBuild = function(self)
        TSeaUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
		LOG("Atlantis OnFailedToBuild done")
    end,

    CreateHelperFac = function(self)

        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        if not self.HelperFactory then

            self.HelperFactory = CreateUnitHPR('ESA0001', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
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
		LOG("Atlantis CreateHelperFac done")
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
		LOG("Atlantis SetFactoryRestrictions done")
    end,
    
    OnTransportDetach = function(self, attachBone, unit)
        if unit == self.ProxyAttach or self.HelperFactory then return end
        TSeaUnit.OnTransportDetach(self, attachBone, unit)
		ChangeState(self, self.IdleState)
		LOG("Atlantis OnTransportDetach done")
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
		LOG("Atlantis DestroyFacs done")
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
	
		OnLayerChange = function(self, new, old)
		TSeaUnit.OnLayerChange(self, new, old)
		--if self.WeaponsEnabled then
    		if new == 'Sub' then
				local bp = self:GetBlueprint()
                self:SetIntelRadius('Vision', 32)
                self:SetIntelRadius('Radar', 0)
            elseif new == 'Water' then
			self:ForkThread(self.ExpandingVision, self)
            end
		LOG("Atlantis OnLayerChange done")
    	end,
		    ExpandingVision = function(self)
            WaitSeconds(0.1)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
				WaitSeconds(2)
            self:SetWeaponEnabledByLabel('MissileRack01', true)
            self:SetWeaponEnabledByLabel('MissileRack02', true)
            self:SetWeaponEnabledByLabel('MissileRack03', true)
            self:SetWeaponEnabledByLabel('MissileRack04', true)
            self:SetWeaponEnabledByLabel('AAGun', true)
                while CurrentRadius < bp.Intel.VisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                self:SetIntelRadius('Radar', bp.Intel.RadarRadius)
                CurrentRadius = CurrentRadius + 1
				WaitSeconds(0.1)
                end
		LOG("Atlantis ExpandingVision done")
        end,
	    ContractingVision = function(self)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
				LOG("5464564")
            self:SetWeaponEnabledByLabel('MissileRack01', false)
            self:SetWeaponEnabledByLabel('MissileRack02', false)
            self:SetWeaponEnabledByLabel('MissileRack03', false)
            self:SetWeaponEnabledByLabel('MissileRack04', false)
            self:SetWeaponEnabledByLabel('AAGun', false)
            WaitSeconds(6)
                while CurrentRadius > 32 do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.1)
                end
		LOG("Atlantis ContractingVision done")
        end,
}

TypeClass = UES0401