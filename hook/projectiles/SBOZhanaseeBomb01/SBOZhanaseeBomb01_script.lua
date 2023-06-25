#****************************************************************************
#**
#**  File     :  /data/projectiles/SBOZhanaseeBomb/SBOZhanaseeBomb01_script.lua
#**  Author(s):  Greg Kohne, Gordon Duclos, Aaron Lundquist
#**
#**  Summary  :  Zhanasee Bomb script, used on XSA0304
#**
#**  Copyright � 2007 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local SZhanaseeBombProjectile = import('/lua/seraphimprojectiles.lua').SZhanaseeBombProjectile
local DefaultExplosion = import('/lua/defaultexplosions.lua')
local RandomFloat = import('/lua/utilities.lua').GetRandomFloat

SBOZhanaseeBombProjectile01 = Class(SZhanaseeBombProjectile){

    OnImpact = function(self, TargetType, TargetEntity)   
        CreateLightParticle(self, -1, self:GetArmy(), 26, 5, 'sparkle_white_add_08', 'ramp_white_24' )
        
        # One initial projectile following same directional path as the original
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect01/SBOZhanaseeBombEffect01_proj.bp', 0, 0, 0, 0, 10.0, 0):SetCollision(false):SetVelocity(0,10.0, 0)
        self:CreateProjectile('/effects/entities/SBOZhanaseeBombEffect02/SBOZhanaseeBombEffect02_proj.bp', 0, 0, 0, 0, 0.05, 0):SetCollision(false):SetVelocity(0,0.05, 0)
        
        if TargetType == 'Terrain' then
            ### WaitSeconds(5.0)
            ### Create our decals for like nine seconds that way there will be no problem when it comes to bombs dropping all the time.
            local pos = self:GetPosition()
            DamageArea( self, pos, self.DamageData.DamageRadius, 1, 'Force', true )
            DamageArea( self, pos, self.DamageData.DamageRadius, 1, 'Force', true )              
            CreateDecal( pos, RandomFloat(0.0,6.28), 'Scorch_012_albedo', '', 'Albedo', 40, 40, 300, 200, self:GetArmy())          
        end
        if TargetType == 'Shield' and self.Data then
            self.DamageData.DamageAmount = self.Data
            LOG("Hello I am bomber and I am going to do " .. self.Data .. " to this FUCKING SHIELD")
        end
        SZhanaseeBombProjectile.OnImpact(self, TargetType, TargetEntity)
        if TargetType != 'Shield' and TargetType != 'Water' and TargetType != 'UnitAir' then
            local rotation = RandomFloat(0,2*math.pi)

            CreateDecal(self:GetPosition(), rotation, 'crater_radial01_normals', '', 'Alpha Normals', 10, 10, 300, 0, self:GetArmy())
            CreateDecal(self:GetPosition(), rotation, 'crater_radial01_albedo', '', 'Albedo', 12, 12, 300, 0, self:GetArmy())
        end
    end,
}

TypeClass = SBOZhanaseeBombProjectile01
