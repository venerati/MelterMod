#
# Aeon Serpentine Missile
#
local AMissileSerpentineProjectile = import('/lua/aeonprojectiles.lua').AMissileSerpentineProjectile
local utilities = import("/lua/utilities.lua")
local RandomFloat = import("/lua/utilities.lua").GetRandomFloat

AIFMissileSerpentine01 = Class(AMissileSerpentineProjectile) {

    OnCreate = function(self)
        AMissileSerpentineProjectile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2)
        self.MoveThread = self.Trash:Add(ForkThread(self.MovementThread,self))
    end,

    MovementThread = function(self)
        self.Distance = self:GetDistanceToTarget()
        self:SetTurnRate(8)
        WaitTicks(4)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitTicks(2)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > self.Distance then
        	self:SetTurnRate(75)
        	WaitTicks(31)
        	self:SetTurnRate(8)
        	self.Distance = self:GetDistanceToTarget()
        end
        if dist > 50 then
            WaitTicks(21)
            self:SetTurnRate(10)
        elseif dist > 30 and dist <= 50 then
						self:SetTurnRate(12)
						WaitTicks(16)
            self:SetTurnRate(12)
        elseif dist > 10 and dist <= 25 then
            WaitTicks(4)
            self:SetTurnRate(50)
				elseif dist > 0 and dist <= 10 then
            self:SetTurnRate(100)
            KillThread(self.MoveThread)
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
	
	    OnImpact = function(self, targetType, targetEntity)
        local bp = self.Blueprint.Audio
        local snd = bp['Impact'.. targetType]	
        if snd then
            self:PlaySound(snd)
            -- Generic Impact Sound
        elseif bp.Impact then
            self:PlaySound(bp.Impact)
        end

        if targetType == 'Shield' then
		self.DamageData.DoTPulses = 10
		self.DamageData.DoTTime = 1
		else
		self.DamageData.DoTPulses = 30
		self.DamageData.DoTTime = 3
		end
		self:CreateImpactEffects( self.Army, self.FxImpactNone, self.FxNoneHitScale )
		local x,y,z = self:GetVelocity()
		local speed = utilities.GetVectorLength(Vector(x*10,y*10,z*10))

		-- One initial projectile following same directional path as the original
        self:CreateChildProjectile('/projectiles/AIFMiasmaShell02/AIFMiasmaShell02_proj.bp')
        :SetVelocity(x,y,z):SetVelocity(speed).DamageData = self.DamageData			
        self:Destroy()

    end,
}

TypeClass = AIFMissileSerpentine01