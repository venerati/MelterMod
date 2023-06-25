--****************************************************************************
--**
--**  File     :  /cdimage/units/UES0203/UES0203_script.lua
--**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
--**
--**  Summary  :  UEF Attack Sub Script
--**
--**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************

local TSubUnit = import("/lua/terranunits.lua").TSubUnit
local TANTorpedoAngler = import("/lua/terranweapons.lua").TANTorpedoAngler
local TDFLightPlasmaCannonWeapon = import("/lua/terranweapons.lua").TDFLightPlasmaCannonWeapon

---@class UES0203 : TSubUnit
UES0203 = ClassUnit(TSubUnit) {
    PlayDestructionEffects = true,
    DeathThreadDestructionWaitTime = 0,

    Weapons = {
        Torpedo01 = ClassWeapon(TANTorpedoAngler) {},
        PlasmaGun = ClassWeapon(TDFLightPlasmaCannonWeapon) {}
    },
	
	OnCreate = function(self)
	TSubUnit.OnCreate(self)
	self:SetSpeedMult(0.66)
	self:SetAccMult(0.80)
	self:SetTurnMult(0.80)
	end,
	
    OnStopBeingBuilt = function(self, builder, layer)
        TSubUnit.OnStopBeingBuilt(self,builder,layer)
        if(self:GetCurrentLayer() == 'Water') then
            ChangeState( self, self.ExpandingVision )
        else
            ChangeState( self, self.ContractingVision )
        end
    end,

		OnMotionVertEventChange = function(self, new, old)
        TSubUnit.OnMotionVertEventChange(self, new, old)
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
		TSubUnit.OnLayerChange(self, new, old)
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
            self:SetWeaponEnabledByLabel('PlasmaGun', true)
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
            self:SetWeaponEnabledByLabel('PlasmaGun', false)
                while CurrentRadius > bp.Intel.WaterVisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.3)
                end
        end,
    },
}


TypeClass = UES0203