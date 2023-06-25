#****************************************************************************
#
#    File     :  /data/Projectiles/ADFReactonCannon01/ADFReactonCannon01_script.lua
#    Author(s): Jessica St.Croix, Gordon Duclos
#
#    Summary  : Aeon Reacton Cannon Area of Effect Projectile
#
#    Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local AReactonCannonProjectile = import('/lua/aeonprojectiles.lua').AReactonCannonProjectile
local utilities = import("/lua/utilities.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

ADFReactonCannon01 = Class(AReactonCannonProjectile) {

	    OnImpact = function(self, targetType, targetEntity)
        if targetType == 'Shield' then
		LOG("Init " .. self.DamageData.DoTPulses .. self.DamageData.DoTTime .. targetType)
		self.DamageData.DoTPulses = 8
		self.DamageData.DoTTime = 0.1
		LOG("1 1 " .. self.DamageData.DoTPulses .. self.DamageData.DoTTime .. targetType)
		else
		LOG("Init " .. self.DamageData.DoTPulses .. self.DamageData.DoTTime .. targetType)
		self.DamageData.DoTPulses = 10
		self.DamageData.DoTTime = 3
		LOG("3 30 " .. self.DamageData.DoTPulses .. self.DamageData.DoTTime .. targetType)
		end
		AReactonCannonProjectile.OnImpact(self, targetType, targetEntity)
		self:Destroy()
		LOG("Self Destroy")
		end,
}
TypeClass = ADFReactonCannon01