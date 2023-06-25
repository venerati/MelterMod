--****************************************************************************
--**
--**  File     :  /data/units/XRS0204/XRS0204_script.lua
--**  Author(s):  Jessica St. Croix
--**
--**  Summary  :  Cybran Sub Killer Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSubUnit = import("/lua/cybranunits.lua").CSubUnit
local WeaponsFile = import("/lua/cybranweapons.lua")
local CANNaniteTorpedoWeapon = WeaponsFile.CANNaniteTorpedoWeapon
local CIFSmartCharge = WeaponsFile.CIFSmartCharge
local WeaponFile = import("/lua/terranweapons.lua")
local TIFSmartCharge = WeaponFile.TIFSmartCharge

---@class XRS0204 : CSubUnit
XRS0204 = ClassUnit(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,

    Weapons = {
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
        AntiTorpedo01 = ClassWeapon(CIFSmartCharge) {},
        AntiTorpedo02 = ClassWeapon(TIFSmartCharge) {},
    },
    OnCreate = function(self)
        CSubUnit.OnCreate(self)
        self:SetMaintenanceConsumptionActive()
    end,
	
	OnMotionVertEventChange = function(self, new, old)
        CSubUnit.OnMotionVertEventChange(self, new, old)
	-- Surfacing and sinking, landing and take off idle effects
        local layerV = self.Layer
            if new == 'Down' and layerV == 'Water' then
			ChangeState(self, self.ContractingVision)		
            end
		end,
	
	    OnLayerChange = function(self, new, old)
		CSubUnit.OnLayerChange(self, new, old)
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

TypeClass = XRS0204