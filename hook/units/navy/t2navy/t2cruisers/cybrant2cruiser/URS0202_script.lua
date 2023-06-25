-----------------------------------------------------------------
-- File     :  /cdimage/units/URS0202/URS0202_script.lua
-- Author(s):  David Tomandl, Jessica St. Croix
-- Summary  :  Cybran Cruiser Script
-- Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
-----------------------------------------------------------------

local CSeaUnit = import("/lua/cybranunits.lua").CSeaUnit
local CybranWeaponsFile = import("/lua/cybranweapons.lua")
local CDFProtonCannonWeapon = CybranWeaponsFile.CDFProtonCannonWeapon
local CAANanoDartWeapon = CybranWeaponsFile.CAANanoDartWeapon
local CAMZapperWeapon03 = CybranWeaponsFile.CAMZapperWeapon03
local TargetingLaser = import("/lua/kirvesweapons.lua").TargetingLaserInvisible

---@class URS0202 : CSeaUnit
URS0202 = ClassUnit(CSeaUnit) {
    Weapons = {
        ParticleGun = ClassWeapon(CDFProtonCannonWeapon) {},
        AAGun = ClassWeapon(CAANanoDartWeapon) {
            IdleState = State (CAANanoDartWeapon.IdleState) {
                OnGotTarget = function(self)
                    CAANanoDartWeapon.IdleState.OnGotTarget(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                    self.unit:GetWeaponManipulatorByLabel('GroundGun'):SetHeadingPitch(self.unit:GetWeaponManipulatorByLabel('AAGun'):GetHeadingPitch())
                    self.unit:SetWeaponEnabledByLabel('AAGun', true)
                end,
            },

                OnWeaponFired = function(self)
                    CAANanoDartWeapon.IdleState.OnWeaponFired(self)
                    self.unit:SetWeaponEnabledByLabel('GroundGun', false)
                end,
				
            OnLostTarget = function(self)
                CAANanoDartWeapon.OnLostTarget(self)
                self.unit:SetWeaponEnabledByLabel('GroundGun', true)
            end,
        },
        GroundGun = ClassWeapon(CAANanoDartWeapon) {
		OnWeaponFired = function(self)
		end,
		},
        Zapper = ClassWeapon(CAMZapperWeapon03) {},
    },
}

TypeClass = URS0202