------------------------------------------------------------------
--  File     :  /units/XSA0304/XSA0304_script.lua
--  Author(s):  Drew Staltman, Greg Kohne, Gordon Duclos
--  Summary  :  Seraphim Strategic Bomber Script
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
------------------------------------------------------------------

local SAirUnit = import("/lua/seraphimunits.lua").SAirUnit
local SIFBombZhanaseeWeapon = import("/lua/seraphimweapons.lua").SIFBombZhanaseeWeapon

---@class XSA0304 : SAirUnit
XSA0304 = ClassUnit(SAirUnit) {
    Weapons = {
        Bomb = ClassWeapon(SIFBombZhanaseeWeapon) {            
				CreateProjectileAtMuzzle = function(self, muzzle)
                local proj = SIFBombZhanaseeWeapon.CreateProjectileAtMuzzle(self, muzzle)
                local data = self:GetBlueprint().ShieldDamage
                if proj and not proj:BeenDestroyed() then
                    proj:PassData(data)
                end
            end
		},
    },
    
    OnDamage = function(self, instigator, amount, vector, damageType)
        if instigator and instigator:GetBlueprint().CategoriesHash.STRATEGICBOMBER and instigator.Army == self.Army then
            return
        end
        
        SAirUnit.OnDamage(self, instigator, amount, vector, damageType)
    end,
}
TypeClass = XSA0304