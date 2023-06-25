--
-- Terran HedgeHog Launch morter
local TArtilleryProjectile = import("/lua/terranprojectiles.lua").TArtilleryProjectile
local VisionMarkerOpti = import("/lua/sim/vizmarker.lua").VisionMarkerOpti
local EffectTemplate = import("/lua/effecttemplates.lua")
local VizMarker = import('/lua/sim/VizMarker.lua').VizMarker

-- upvalue for performance
local CreateEmitterAtEntity = CreateEmitterAtEntity
local Random = Random
local MathSin = math.sin
local MathCos = math.cos

local TFragmentationSensorShellFrag = import("/lua/effecttemplates.lua").TFragmentationSensorShellFrag 
--

HedgeHogDepthCharge = ClassProjectile(TArtilleryProjectile) {
    FxOnKilled = EffectTemplate.AAntiMissileFlareHit,

	OnCreate = function(self)
	TArtilleryProjectile.OnCreate(self)
	self.TTT1 = self:ForkThread(self.fuse)
	end,

	fuse = function(self)
	WaitSeconds(.3)
	local vx, vy, vz = self:GetVelocity()
	local velocity = self:GetVelocity()
    local bp = self:GetBlueprint().Physics

		-- One initial projectile following same directional path as the original
		LOG(vx .. vy .. vz)
		
		LOG("parent " .. self.DamageData.DamageRadius)
		while vy > 0 do
		vx, vy, vz = self:GetVelocity()
		--LOG("Verticle Speed" .. vy)
		if vy <=0 then
		
		end
		WaitSeconds(.1)
		end
		self.DamageData.DamageRadius = 0
		self.DamageData.DamageAmount = 0
   		LOG("parent before destroy rad " .. self.DamageData.DamageRadius)
   		LOG("parent before destroy dm " .. self.DamageData.DamageAmount)
		WaitSeconds(.1)
	--self:Destroy()
	end,

	OnDestroy = function(self)
	     self.DamageData.DamageRadius = 0
		 self.DamageData.DamageAmount = 0
		 self:SetVelocity(0 , 0, 0)
		 LOG("parent before pass rad " .. self.DamageData.DamageRadius)
		 LOG("parent before pass dam " .. self.DamageData.DamageAmount)
        self:CreateChildProjectile('/mods/Superior FAF Experience/hook/Projectiles/HedgeHogDepthCharge/HedgeHogDepthChargeChild_proj.bp'):SetVelocity(0 , -1, 0):PassDamageData(self.DamageData)
        --local vizEntity = VizMarker(spec)
        TArtilleryProjectile.OnDestroy(self)
		KillThread(self.TTT1)
	end,
  
}
TypeClass = HedgeHogDepthCharge