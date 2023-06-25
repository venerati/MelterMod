#****************************************************************************
#**
#**  File     :  /data/projectiles/SIFLaanseTacticalMissile02/SIFLaanseTacticalMissile02_script.lua
#**  Author(s):  Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Laanse Tactical Missile Projectile script, XSS0202
#**
#**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************

local SLaanseTacticalMissile = import('/lua/seraphimprojectiles.lua').SLaanseTacticalMissile

SIFLaanseTacticalMissile05 = Class(SLaanseTacticalMissile) {

    OnCreate = function(self)
        SLaanseTacticalMissile.OnCreate(self)
        self:SetCollisionShape('Sphere', 0, 0, 0, 2.0)
		self.MovementTurnLevel = 1
        self:ForkThread( self.MovementThread )
    end,

    MovementThread = function(self)
        local army = self:GetArmy()
        self:TrackTarget(false)
        self:SetCollision(true)
        #WaitSeconds(2)
        self:SetTurnRate(5)
        WaitSeconds(0.5)
        self:TrackTarget(true)
        self:SetTurnRate(10)
        WaitSeconds(0.5)
        while not self:BeenDestroyed() do
            self:SetTurnRateByDist()
            WaitSeconds(0.5)
        end
    end,

    SetTurnRateByDist = function(self)
        local dist = self:GetDistanceToTarget()
        if dist > 125 and self.MovementTurnLevel < 2 then
            self:SetTurnRate(30)
            self.MovementTurnLevel = 1
        elseif dist > 85 and dist <= 125 and self.MovementTurnLevel < 3 then
            self:SetTurnRate(40)
            self.MovementTurnLevel = 2
        elseif dist > 40 and dist <= 85 and self.MovementTurnLevel < 4 then
            self:SetTurnRate(50)
            self.MovementTurnLevel = 3
        elseif dist < 40 then
            self:SetTurnRate(85)
            self.MovementTurnLevel = 4
        end
    end,

    GetDistanceToTarget = function(self)
        local tpos = self:GetCurrentTargetPosition()
        local mpos = self:GetPosition()
        local dist = VDist2(mpos[1], mpos[3], tpos[1], tpos[3])
        return dist
    end,
}
TypeClass = SIFLaanseTacticalMissile05

