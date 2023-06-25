-----------------------------------------------------------------
-- File     :  /cdimage/units/UAS0401/UAS0401_script.lua
-- Author(s):  John Comes
-- Summary  :  Aeon Experimental Sub
-- Copyright Â© 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local ASubUnit = import('/lua/aeonunits.lua').ASubUnit
local ASeaUnit = import('/lua/aeonunits.lua').ASeaUnit
local WeaponsFile = import('/lua/aeonweapons.lua')
local ADFCannonOblivionWeapon = WeaponsFile.ADFCannonOblivionWeapon02
local AANChronoTorpedoWeapon = WeaponsFile.AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = WeaponsFile.AIFQuasarAntiTorpedoWeapon
local CreateAeonTempestBuildingEffects = import("/lua/effectutilities.lua").CreateAeonTempestBuildingEffects
local Unit = import("/lua/sim/unit.lua").Unit

UAS0401 = Class(ASeaUnit) {
    BuildAttachBone = 'Attachpoint01',
    FactoryAttachBone = 'HelperFactory',

    Weapons = {
        MainGun = Class(ADFCannonOblivionWeapon) {},
        Torpedo01 = Class(AANChronoTorpedoWeapon) {},
        Torpedo02 = Class(AANChronoTorpedoWeapon) {},
        Torpedo03 = Class(AANChronoTorpedoWeapon) {},
        Torpedo04 = Class(AANChronoTorpedoWeapon) {},
        Torpedo05 = Class(AANChronoTorpedoWeapon) {},
        Torpedo06 = Class(AANChronoTorpedoWeapon) {},
        AntiTorpedo01 = Class(AIFQuasarAntiTorpedoWeapon) {},
        AntiTorpedo02 = Class(AIFQuasarAntiTorpedoWeapon) {},
    },

    StartBeingBuiltEffects = function(self, builder, layer)
        ASeaUnit.StartBeingBuiltEffects(self, builder, layer)
        CreateAeonTempestBuildingEffects(self)
    end,
	
    OnStopBeingBuilt = function(self, builder, layer)
        self:SetWeaponEnabledByLabel('MainGun', true)
        ASeaUnit.OnStopBeingBuilt(self, builder, layer)

        if layer == 'Water' then
            self:RestoreBuildRestrictions()
            self:RequestRefreshUI()
        else
            self:AddBuildRestriction(categories.ALLUNITS)
            self:RequestRefreshUI()
        end
        self:CreateHelperFac()
        ChangeState(self, self.IdleState)

        if not self.SinkSlider then -- Setup the slider and get blueprint values
            self.SinkSlider = CreateSlider(self, 0, 0, 0, 0, 5, true) -- Create sink controller to overlay ontop of original collision detection
            self.Trash:Add(self.SinkSlider)
        end

        self.WatchDepth = false
    end,

    OnFailedToBuild = function(self)
        ASeaUnit.OnFailedToBuild(self)
        ChangeState(self, self.IdleState)
    end,

    OnMotionVertEventChange = function(self, new, old)
        ASeaUnit.OnMotionVertEventChange(self, new, old)
        if new == 'Top' then
		LOG("CreateHelperFac1")
				self:ReCreateHelperFac()
		LOG("CreateHelperFac2")
            self:SetWeaponEnabledByLabel('MainGun', true)
            self:PlayUnitSound('Open')
        elseif new == 'Down' then
            self:SetWeaponEnabledByLabel('MainGun', false)
            --IssueClearCommands({self.HelperFactory})
            --self.HelperFactory:AddBuildRestriction(categories.ALLUNITS)
            --self.HelperFactory:RequestRefreshUI()
            self:PlayUnitSound('Close')
        end

        if new == 'Up' and old == 'Bottom' then -- When starting to surface
            self.WatchDepth = false
        end

        if new == 'Bottom' and old == 'Down' then -- When finished diving
            self.WatchDepth = true
            if not self.DiverThread then
                self.DiverThread = self:ForkThread(self.DiveDepthThread)
            end
        end
        local layerV = self.Layer
            if new == 'Down' and layerV == 'Water' then
			ChangeState(self, self.ContractingVision)
			else
                self:SetIntelRadius('Vision', 32)		
            end
		end,
	
	    OnLayerChange = function(self, new, old)
		ASeaUnit.OnLayerChange(self, new, old)
		ASubUnit.OnLayerChange(self, new, old)
		--if self.WeaponsEnabled then
    		if new == 'Sub' then
				local bp = self:GetBlueprint()
                self:SetIntelRadius('Vision', bp.Intel.WaterVisionRadius)
            elseif new == 'Water' then
			ChangeState(self, self.ExpandingVision)
            end
    	end,

		ExpandingVision = State {
        Main = function(self)
            WaitSeconds(0.1)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
            self:SetWeaponEnabledByLabel('MainGun', true)
                while CurrentRadius < bp.Intel.VisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius + 1
				WaitSeconds(0.1)
                end
				--self:SetFactoryRestrictions()
				--IssueClearCommands({self.HelperFactory})
				--self.HelperFactory:RequestRefreshUI()
				ChangeState(self, self.IdleState)
        end,
		},
	    ContractingVision = State {
        Main = function(self)
			self:DetachAll(self.FactoryAttachBone)
			self.ProxyAttach:DetachAll(2)
		self.HelperFactory:Destroy()
		self.ProxyAttach:Destroy()
		LOG("destroy factory submerge")
            WaitSeconds(7)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
                while CurrentRadius > 32 do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.1)
                end
                LOG("Vision set to 16")
				ChangeState(self, self.IdleState)
        end,
    },
	
    DiveDepthThread = function(self)
        -- Takes the given location, adjusts the Y value to the surface height on that location, with an offset
        local Yoffset = 1.2 -- The default (built in) offset appears to be 0.25 - if the place where thats set is found, that would be epic.
        -- 1.2 is for Tempest to clear the torpedo tubes from most cases of ground clipping, keeping overall height minimal.
        while self.WatchDepth == true do
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3]) -- Target depth, in this case the seabed
            local difference = math.max(((seafloor + Yoffset) - pos[2]), -0.5) -- Doesnt sink too much, just maneuveres the bed better.
            self.SinkSlider:SetSpeed(1)
            
            self.SinkSlider:SetGoal(0, difference, 0)
            WaitSeconds(0.2)
        end

        self.SinkSlider:SetGoal(0, 0, 0) -- Reset the slider while we are not watching depth
        WaitFor(self.SinkSlider)-- We have to wait for it to finish before killing the thread or it stops

        KillThread(self.DiverThread)
    end,

    CreateHelperFac = function(self)

        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        if not self.HelperFactory or self.HelperFactory == nil then

            self.HelperFactory = CreateUnitHPR('ASS0001', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.HelperFactory.Parent = self
            self.HelperFactory:SetCreator(self)
            self.Trash:Add(self.HelperFactory)
		LOG("self.HelperFactory " .. table.concat(self.HelperFactory, ", "))
        end
        if not self.ProxyAttach then
            self.ProxyAttach = CreateUnitHPR('ZXB0302', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.ProxyAttach.Parent = self
            self.ProxyAttach:SetCreator(self)
            self.Trash:Add(self.ProxyAttach)
		LOG("self.ProxyAttach " .. table.concat(self.ProxyAttach, ", "))
        end
			self:DetachAll(self.FactoryAttachBone)
        if self.ProxyAttach != nil then
			self.ProxyAttach:DetachAll(2)
			self.HelperFactory:AttachTo(self.ProxyAttach, 2)
			self.ProxyAttach:AttachTo(self, self.FactoryAttachBone)
        end
        self:SetFactoryRestrictions()
    end,
	
	ReCreateHelperFac = function(self)

        local location = self:GetPosition(self.FactoryAttachBone)
        --local orientation = self:GetOrientation()
        local army = self:GetArmy()
        --if not self.HelperFactory or self.HelperFactory == nil then

            self.HelperFactory = CreateUnitHPR('ASS0001', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.HelperFactory.Parent = self
            self.HelperFactory:SetCreator(self)
            self.Trash:Add(self.HelperFactory)
		LOG("self.HelperFactory " .. table.concat(self.HelperFactory, ", "))
        --end
        --if not self.ProxyAttach then
            self.ProxyAttach = CreateUnitHPR('ZXB0302', army, location[1], location[2] + 10, location[3] + 5, 0, 0, 0)
            self.ProxyAttach.Parent = self
            self.ProxyAttach:SetCreator(self)
            self.Trash:Add(self.ProxyAttach)
		LOG("self.ProxyAttach " .. table.concat(self.ProxyAttach, ", "))
        --end
			self:DetachAll(self.FactoryAttachBone)
        if self.ProxyAttach != nil then
			self.ProxyAttach:DetachAll(2)
			self.HelperFactory:AttachTo(self.ProxyAttach, 2)
			self.ProxyAttach:AttachTo(self, self.FactoryAttachBone)
        end
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

    IdleState = State {
        Main = function(self)
            self:DetachAll(self.BuildAttachBone)
            self:SetBusy(false)
		LOG("idstmain")
        end,

        OnStartBuild = function(self, unitBuilding, order)
            --ASeaUnit.OnStartBuild(self, unitBuilding, order)
            self.UnitBeingBuilt = unitBuilding
            ChangeState(self, self.BuildingState)
		LOG("idleonstartb")
        end,
    },

    BuildingState = State {
        Main = function(self)
            self:SetBusy(true)
            local unitBuilding = self.UnitBeingBuilt
            local bone = self.BuildAttachBone
            self.UnitBeingBuilt:DetachFrom(true)
            if not self.UnitBeingBuilt.Dead then
				unitBuilding:AttachBoneTo(-2, self, bone)
                if EntityCategoryContains(categories.uas0102 + categories.uas0103 - categories.ENGINEER, self.UnitBeingBuilt) then
                    self.UnitBeingBuilt:SetParentOffset({0, 0, 0.8})
                elseif EntityCategoryContains(categories.TECH2 - categories.ENGINEER - categories.xas0204, self.UnitBeingBuilt) then
                    self.UnitBeingBuilt:SetParentOffset({0, 0, 3})
                elseif EntityCategoryContains(categories.uas0203 + categories.xas0204, self.UnitBeingBuilt) then
                    self.UnitBeingBuilt:SetParentOffset({0, 0, 1.5})
                else
                    self.UnitBeingBuilt:SetParentOffset({0, 0, 2.5})
                end
            end
            self.UnitBeingBuilt:ShowBone(0,true)
            self.UnitDoneBeingBuilt = false
			if Unit.OnFailedToBuild(self) then
            self:SetBusy(true)
            LOG("FailedToBuild Unit1")
        self:ChangeState(self, self.IdleState)
			end
		LOG("abc")
        end,

        OnStopBuild = function(self, unitBeingBuilt)		
            Unit.OnStopBuild(self, unitBeingBuilt)
			if Unit.OnFailedToBuild(self) then
            LOG("FailedToBuild Unit1")
        ChangeState(self, self.IdleState)
            else
            self.UnitDoneBeingBuilt = true
            ChangeState(self, self.FinishedBuildingState)
			end
		LOG("xy")
        end,
		LOG("qwe")
    },
	
    FinishedBuildingState = State {
        Main = function(self)
        local unitBuilding = self.UnitBeingBuilt
		local bp = self:GetBlueprint()
            self:SetBusy(true)
			LOG("FinishedBuildingState")
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
			
			ChangeState(self, self.RollingOffState)
		LOG("Atlantis FinishedBuildingState done")
        end,
    },

    RollingOffState = State {
        Main = function(self)
            local unitBuilding = self.UnitBeingBuilt
            unitBuilding:DetachFrom(true)
            self:SetBusy(true)
            self:DetachAll(self.BuildAttachBone)
            local worldPos = self:CalculateWorldPositionFromRelative({0, 0, -18})
			IssueStop( {unitBuilding} )
			IssueClearCommands( {unitBuilding} )
            IssueMoveOffFactory({self.UnitBeingBuilt}, worldPos)
            ChangeState(self, self.IdleState)
            ChangeState(self.HelperFactory, self.HelperFactory.IdleState) --let our factory know we are done.
		LOG("RollingOffState done")
        end,
    },
    
    --this is here but is it even needed?
    OnKilled = function(self, instigator, type, overkillRatio)
        local nrofBones = self:GetBoneCount() -1
        local watchBone = self:GetBlueprint().WatchBone or 0

        self:ForkThread(function()
            local pos = self:GetPosition()
            local seafloor = GetTerrainHeight(pos[1], pos[3]) + GetTerrainTypeOffset(pos[1], pos[3])
            while self:GetPosition(watchBone)[2] > seafloor do
                WaitSeconds(0.1)
            end

            self:CreateWreckage(overkillRatio, instigator)
            self:Destroy()
        end)

        local layer = self:GetCurrentLayer()
        self:DestroyIdleEffects()
        if layer == 'Water' or layer == 'Seabed' or layer == 'Sub' then
            self.SinkExplosionThread = self:ForkThread(self.ExplosionThread)
            self.SinkThread = self:ForkThread(self.SinkingThread)
        end

        ASeaUnit.OnKilled(self, instigator, type, overkillRatio)
    end
}

TypeClass = UAS0401