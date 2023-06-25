--****************************************************************************
--**
--**  File     :  /cdimage/units/URS0203/URS0203_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  Cybran Attack Sub Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local CSubUnit = import("/lua/cybranunits.lua").CSubUnit
local CANNaniteTorpedoWeapon = import("/lua/cybranweapons.lua").CANNaniteTorpedoWeapon
local CDFLaserHeavyWeapon = import("/lua/cybranweapons.lua").CDFLaserHeavyWeapon

---@class URS0203 : CSubUnit
URS0203 = ClassUnit(CSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    
    Weapons = {
        MainGun = ClassWeapon(CDFLaserHeavyWeapon) {},
        Torpedo01 = ClassWeapon(CANNaniteTorpedoWeapon) {},
    },
	
	OnCreate = function(self)	
	CSubUnit.OnCreate(self)
	self:SetSpeedMult(0.66)
	self:SetAccMult(0.80)
	self:SetTurnMult(0.80)
	end,
	
    OnStopBeingBuilt = function(self, builder, layer)
        CSubUnit.OnStopBeingBuilt(self,builder,layer)
        if(self:GetCurrentLayer() == 'Water') then
            ChangeState( self, self.ExpandingVision )
        else
            ChangeState( self, self.ContractingVision )
        end
    end,

	
	
		OnMotionVertEventChange = function(self, new, old)
        CSubUnit.OnMotionVertEventChange(self, new, old)
	-- Surfacing and sinking, landing and take off idle effects
        local layerV = self.Layer
            if new == 'Down' and layerV == 'Water' then
			self:SetSpeedMult(0.66)
			self:SetAccMult(0.80)
			self:SetTurnMult(0.80)
			ChangeState(self, self.ContractingVision)
			else
                self:SetIntelRadius('Vision', 16)		
            end
		end,
	
	    OnLayerChange = function(self, new, old)
		CSubUnit.OnLayerChange(self, new, old)
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
            WaitSeconds(0.1)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
            self:SetWeaponEnabledByLabel('MainGun', true)
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
            self:SetWeaponEnabledByLabel('MainGun', false)
                while CurrentRadius > bp.Intel.WaterVisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.3)
                end
        end,
    },
}

TypeClass = URS0203