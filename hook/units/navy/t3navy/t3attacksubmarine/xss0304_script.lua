--****************************************************************************
--**
--**  File     :  /data/units/xss0304/xss0304_script.lua
--**  Author(s):  Greg Kohne, Dru Staltman, Gordon DUclos
--**
--**  Summary  :  Seaphim Submarine Hunter Script
--**
--**  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
--****************************************************************************
local SSubUnit = import('/lua/seraphimunits.lua').SSubUnit
local SANUallCavitationTorpedo = import('/lua/seraphimweapons.lua').SANUallCavitationTorpedo
local SDFAjelluAntiTorpedoDefense = import('/lua/seraphimweapons.lua').SDFAjelluAntiTorpedoDefense
local SAALosaareAutoCannonWeapon = import('/lua/seraphimweapons.lua').SAALosaareAutoCannonWeaponSeaUnit

XSS0304 = Class(SSubUnit) {
    DeathThreadDestructionWaitTime = 0,
    Weapons = {
        TorpedoFront = Class(SANUallCavitationTorpedo) {},
        AntiTorpedoLeft = Class(SDFAjelluAntiTorpedoDefense) {},
        AntiTorpedoRight = Class(SDFAjelluAntiTorpedoDefense) {},
        AutoCannon = Class(SAALosaareAutoCannonWeapon) {},
    },
    
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
			ChangeState(self, self.ContractingVision)
			else
                self:SetIntelRadius('Vision', 16)
            end
		end,
		
	OnLayerChange = function(self, new, old)
		SSubUnit.OnLayerChange(self, new, old)
		LOG("Layerchange")
		--if self.WeaponsEnabled then
    		if new == 'Sub' then
				local bp = self:GetBlueprint()
                self:SetIntelRadius('Vision', bp.Intel.VisionRadius)
            elseif new == 'Water' then
			ChangeState(self, self.ExpandingVision)
            end
    	end,
	
		    ExpandingVision = State {
        Main = function(self)
            WaitSeconds(0.3)
                local CurrentRadius = self:GetIntelRadius('vision')
				local bp = self:GetBlueprint()
            if not self.CannonAnim then
                self.CannonAnim = CreateAnimator(self)
                self.Trash:Add(self.CannonAnim)
            end
            self.CannonAnim:PlayAnim(bp.Display.CannonOpenAnimation)
            self.CannonAnim:SetRate(bp.Display.CannonOpenRate or 1)
            WaitFor(self.CannonAnim)
            self:SetWeaponEnabledByLabel('AutoCannon', true)
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
            self:SetWeaponEnabledByLabel('AutoCannon', false)
            if self.CannonAnim then
                local bp = self:GetBlueprint()
                self.CannonAnim:SetRate( -1 * ( bp.Display.CannonOpenRate or 1 ) )
                WaitFor(self.CannonAnim)
            end
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
TypeClass = XSS0304