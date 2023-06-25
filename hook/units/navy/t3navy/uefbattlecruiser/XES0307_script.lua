----------------------------------------------------------------------------
--
--  File     :  /cdimage/units/UES0307/UES0307_script.lua
--  Author(s):  Drew Staltman, Gordon Duclos, Greg Kohne
--
--  Summary  :  UEF Battleship Script
--
--  Copyright © 2007 Gas Powered Games, Inc.  All rights reserved.
----------------------------------------------------------------------------
local TSeaUnit = import("/lua/terranunits.lua").TSeaUnit
local WeaponsFile = import("/lua/terranweapons.lua")
local TDFGaussCannonWeapon = WeaponsFile.TDFShipGaussCannonWeapon
local TDFHiroPlasmaCannon = WeaponsFile.TDFHiroPlasmaCannon
local TIFSmartCharge = WeaponsFile.TIFSmartCharge

---@class UES0302 : TSeaUnit
UES0302 = Class(TSeaUnit) {
    Weapons = {
        HiroCannonFront = Class(TDFHiroPlasmaCannon) {},
        HiroCannonBack = Class(TDFHiroPlasmaCannon) {},
        AntiTorpedo = Class(TIFSmartCharge) {},
        GaussCannon = Class(TDFGaussCannonWeapon) {},
    },



        OnKilled = function(self, instigator, type, overkillRatio)
            if not self.Dead then
                local wep1 = self:GetWeaponByLabel('HiroCannonFront')
                local bp1 = wep1:GetBlueprint()
                if bp1.Audio.BeamStop then
                    wep1:PlaySound(bp1.Audio.BeamStop)
                end
                if bp1.Audio.BeamLoop and wep1.Beams[1].Beam then
                    wep1.Beams[1].Beam:SetAmbientSound(nil, nil)
                end
                for k, v in wep1.Beams do
                    v.Beam:Disable()
                end

                local wep2 = self:GetWeaponByLabel('HiroCannonBack')
                local bp2 = wep2:GetBlueprint()
                if bp2.Audio.BeamStop then
                    wep2:PlaySound(bp2.Audio.BeamStop)
                end
                if bp2.Audio.BeamLoop and wep2.Beams[1].Beam then
                    wep2.Beams[1].Beam:SetAmbientSound(nil, nil)
                end
                for k, v in wep2.Beams do
                    v.Beam:Disable()
                end
            end
            TSeaUnit.OnKilled(self, instigator, type, overkillRatio)
        end,
}
TypeClass = UES0302