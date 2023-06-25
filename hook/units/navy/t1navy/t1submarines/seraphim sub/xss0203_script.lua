--****************************************************************************
--**
--**  File     :  /cdimage/units/XSS0203/XSS0203_script.lua
--**
--**  Summary  :  Seraphim Attack Sub Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SSubUnit = import("/lua/seraphimunits.lua").SSubUnit
local SWeapons = import("/lua/seraphimweapons.lua")

local SANUallCavitationTorpedo = SWeapons.SANUallCavitationTorpedo
local SDFOhCannon = SWeapons.SDFOhCannon02
local SDFAjelluAntiTorpedoDefense = SWeapons.SDFAjelluAntiTorpedoDefense

---@class XSS0203 : SSubUnit
XSS0203 = ClassUnit(SSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        Torpedo01 = ClassWeapon(SANUallCavitationTorpedo) {},
        Cannon = ClassWeapon(SDFOhCannon) {},
        AntiTorpedo = ClassWeapon(SDFAjelluAntiTorpedoDefense) {},
    },

	OnCreate = function(self)	
	SSubUnit.OnCreate(self)
	self:SetSpeedMult(0.66)
	self:SetAccMult(0.80)
	self:SetTurnMult(0.80)
	end,
	
    OnStopBeingBuilt = function(self,builder,layer)
        SSubUnit.OnStopBeingBuilt(self,builder,layer)
        if layer == 'Water' then
            ChangeState( self, self.ExpandingVision )
        else
            ChangeState( self, self.ContractingVision )
        end
    end,
	
	OnMotionVertEventChange = function(self, new, old)
        SSubUnit.OnMotionVertEventChange(self, new, old)
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
		SSubUnit.OnLayerChange(self, new, old)
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
            if not self.CannonAnim then
                self.CannonAnim = CreateAnimator(self)
                self.Trash:Add(self.CannonAnim)
            end
            self.CannonAnim:PlayAnim(bp.Display.CannonOpenAnimation)
            self.CannonAnim:SetRate(bp.Display.CannonOpenRate or 1)
            WaitFor(self.CannonAnim)
            self:SetWeaponEnabledByLabel('Cannon', true)
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
            self:SetWeaponEnabledByLabel('Cannon', false)
            if self.CannonAnim then
                local bp = self:GetBlueprint()
                self.CannonAnim:SetRate( -1 * ( bp.Display.CannonOpenRate or 1 ) )
                WaitFor(self.CannonAnim)
			end
                while CurrentRadius > bp.Intel.WaterVisionRadius do
                self:SetIntelRadius('Vision', CurrentRadius)
                CurrentRadius = CurrentRadius - 1
				WaitSeconds(0.3)
                end
        end,
    },
}
TypeClass = XSS0203