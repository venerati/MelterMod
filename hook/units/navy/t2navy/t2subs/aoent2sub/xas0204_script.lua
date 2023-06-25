--****************************************************************************
--**
--**  File     :  /data/units/xas0204/xas0204_script.lua
--**  Author(s):  Dru Staltman, Jessica St. Croix
--**
--**  Summary  :  Aeon Submarine Hunter Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local ASubUnit = import('/lua/aeonunits.lua').ASubUnit
local AANChronoTorpedoWeapon = import('/lua/aeonweapons.lua').AANChronoTorpedoWeapon
local AIFQuasarAntiTorpedoWeapon = import('/lua/aeonweapons.lua').AIFQuasarAntiTorpedoWeapon
local WeaponsFile = import("/lua/cybranweapons.lua")
local CIFSmartCharge = WeaponsFile.CIFSmartCharge
local WeaponFile = import("/lua/terranweapons.lua")
local TIFSmartCharge = WeaponFile.TIFSmartCharge

XAS0204 = Class(ASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = Class(AANChronoTorpedoWeapon) {},
        Torpedo02 = Class(AANChronoTorpedoWeapon) {},
        AntiTorpedo01 = Class(CIFSmartCharge) {},
        AntiTorpedo02 = ClassWeapon(TIFSmartCharge) {},
    },
	
	OnMotionVertEventChange = function(self, new, old)
        ASubUnit.OnMotionVertEventChange(self, new, old)
	-- Surfacing and sinking, landing and take off idle effects
        local layerV = self.Layer
            if new == 'Down' and layerV == 'Water' then
			ChangeState(self, self.ContractingVision)		
            end
		end,
	
	    OnLayerChange = function(self, new, old)
		ASubUnit.OnLayerChange(self, new, old)
		LOG("Layerchange")
		--if self.WeaponsEnabled then
    		if new == 'Sub' then
				local bp = self:GetBlueprint()
                self:SetIntelRadius('Vision', 16)
            elseif new == 'Water' then
			ChangeState(self, self.ExpandingVision)
            end
    	end,
		    ExpandingVision = State {
        Main = function(self)
            WaitSeconds(0.3)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
                while CurrentRadius < bp.Intel.VisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                LOG("Vision set to CurrentRadius + 1")
                CurrentRadius = CurrentRadius + 1
				WaitSeconds(0.3)
                end
                LOG("Vision set to 32")
        end,
    },
	    ContractingVision = State {
        Main = function(self)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
                while CurrentRadius > 16 do
                self:SetIntelRadius('Vision', CurrentRadius)
                LOG("Vision set to CurrentRadius -1")
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.3)
                end
                LOG("Vision set to 16")
        end,
    },
}

TypeClass = XAS0204