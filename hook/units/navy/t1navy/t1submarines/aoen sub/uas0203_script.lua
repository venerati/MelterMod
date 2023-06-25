--****************************************************************************
--**
--**  File     :  /cdimage/units/uas0203/uas0203_script.lua
--**  Author(s):  John Comes, Jessica St. Croix
--**
--**  Summary  :  Aeon Attack Sub Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local ASubUnit = import("/lua/aeonunits.lua").ASubUnit
local AANChronoTorpedoWeapon = import("/lua/aeonweapons.lua").AANChronoTorpedoWeapon

---@class UAS0203 : ASubUnit
UAS0203 = Class(ASubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = ClassWeapon(AANChronoTorpedoWeapon) {},
    },
	
	OnCreate = function(self)	
	ASubUnit.OnCreate(self)
	self:SetSpeedMult(0.66)
	self:SetAccMult(0.80)
	self:SetTurnMult(0.80)
	end,
	
	OnMotionVertEventChange = function(self, new, old)
        ASubUnit.OnMotionVertEventChange(self, new, old)
	-- Surfacing and sinking, landing and take off idle effects
        local layerV = self.Layer
            if new == 'Down' and layerV == 'Water' then
			self:SetSpeedMult(0.66)
			self:SetAccMult(0.80)
			self:SetTurnMult(0.80)
			ChangeState(self, self.ContractingVision)		
            end
		end,
	
	    OnLayerChange = function(self, new, old)
		ASubUnit.OnLayerChange(self, new, old)
		--if self.WeaponsEnabled then
    		if new == 'Sub' then
				local bp = self:GetBlueprint()
                self:SetIntelRadius('Vision', bp.Intel.WaterVisionRadius)
            elseif new == 'Water' then			
			self:SetSpeedMult(1)
			self:SetAccMult(1)
			self:SetTurnMult(1)
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
                CurrentRadius = CurrentRadius + 1
				WaitSeconds(0.3)
                end
        end,
    },
	    ContractingVision = State {
        Main = function(self)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
                while CurrentRadius > bp.Intel.WaterVisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.3)
                end
        end,
    },

}

TypeClass = UAS0203