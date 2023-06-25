#
# Cybran Artillery Projectile
#
local CArtilleryProtonProjectile = import('/lua/cybranprojectiles.lua').CArtilleryProtonProjectile
CIFArtilleryProton01 = Class(CArtilleryProtonProjectile) {
	
	OnImpact = function(self, targetType, targetEntity)
		CArtilleryProtonProjectile.OnImpact(self, targetType, targetEntity)
        local army = self:GetArmy()
        CreateLightParticle( self, -1, army, 24, 12, 'glow_03', 'ramp_red_06' )
        CreateLightParticle( self, -1, army, 8, 22, 'glow_03', 'ramp_antimatter_02' )
        if targetType == 'Terrain' or targetType == 'Prop' then
            CreateSplat( self:GetPosition(), 0, 'scorch_011_albedo', 10, 10, 350, 200, army )
        end
        ForkThread(self.ForceThread, self, self:GetPosition())
        self:ShakeCamera( 2, 3, 2, 1 )        
	end,
	
	ForceThread = function(self, pos)
        DamageArea(self, pos, 10, 1, 'Force', true)
	    WaitTicks(2)
	    DamageArea(self, pos, 10, 1, 'Force', true)
        DamageRing(self, pos, 10, 15, 1, 'Fire', true)
	end,
	    
}

TypeClass = CIFArtilleryProton01