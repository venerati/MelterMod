#
# UEF Small Yield Nuclear Bomb
#
local TIFSmallYieldNuclearBombProjectile = import('/lua/terranprojectiles.lua').TArtilleryAntiMatterProjectile
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

TIFSmallYieldNuclearBomb01 = Class(TIFSmallYieldNuclearBombProjectile) {
	PolyTrail = '/effects/emitters/default_polytrail_04_emit.bp',
	FxLandHitScale = 0.5,
    FxUnitHitScale = 0.5,
    OnImpact = function(self, TargetType, TargetEntity)
	LOG("Impact log " .. TargetType, self.Data)
        if TargetType == 'Shield' and self.Data then
            self.DamageData.DamageAmount = self.Data
            LOG("Hello I am bomber and I am going to do " .. self.Data .. " to this FUCKING SHIELD")
        end
        TIFSmallYieldNuclearBombProjectile.OnImpact(self, TargetType, TargetEntity)
        if TargetType != 'Shield' and TargetType != 'Water' and TargetType != 'UnitAir' then
            local rotation = RandomFloat(0,2*math.pi)

            CreateDecal(self:GetPosition(), rotation, 'crater_radial01_normals', '', 'Alpha Normals', 10, 10, 300, 0, self:GetArmy())
            CreateDecal(self:GetPosition(), rotation, 'crater_radial01_albedo', '', 'Albedo', 12, 12, 300, 0, self:GetArmy())
        end
    end,
}


TypeClass = TIFSmallYieldNuclearBomb01