#****************************************************************************
#**
#**  File     :  /cdimage/units/UES0202/UES0202_script.lua
#**  Author(s):  John Comes, David Tomandl, Jessica St. Croix
#**
#**  Summary  :  UEF Cruiser Script
#**
#**  Copyright © 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local EffectTemplate = import('/lua/EffectTemplates.lua')
local TSeaUnit = import('/lua/terranunits.lua').TSeaUnit
local WeaponFile = import('/lua/terranweapons.lua')
local TSAMLauncher = WeaponFile.TSAMLauncher
local TDFGaussCannonWeapon = WeaponFile.TDFGaussCannonWeapon
local TAMPhalanxWeapon = WeaponFile.TAMPhalanxWeapon
local TIFCruiseMissileLauncher = WeaponFile.TIFCruiseMissileLauncher
local TargetingLaser = import("/lua/kirvesweapons.lua").TargetingLaserInvisible
local Weapon = import("/lua/sim/weapon.lua").Weapon

UES0202 = Class(TSeaUnit) {
    DestructionTicks = 200,


	Weapons = {
        TargetPainter = Class(TargetingLaser) {
			OnWeaponFired = function(self)
			LOG("LaserFired")
            self.TargetAcquired = true
			self.unit:SetWeaponEnabledByLabel('CruiseMissiles', false)
            self.unit:SetWeaponEnabledByLabel('CruiseMissile', true)
		    LOG("HM enabled CM disabled")
			TargetingLaser.OnWeaponFired(self)
			end,

			
			OnLostTarget = function(self)
	        self.TargetAcquired = false
			LOG("Target Lost unpacking notifying unit changing state and going to idle")
			local unit = self.unit
            if unit then
                unit:OnLostTarget(self)
            end

            Weapon.OnLostTarget(self)
			LOG("TargetLaser Unpacked Going Idle")
            ChangeState(self, self.IdleState)
			
                    
			end,
			
			IdleState = State(TargetingLaser.IdleState) {
                WeaponWantEnabled = true,
                WeaponAimWantEnabled = true,

				OnGotTarget = function(self)
				    Weapon.OnGotTarget(self)
                 	LOG("TargetPainter has a new Target Acquired")				
					self.TargetAcquired = true
					self.unit:SetWeaponEnabledByLabel('CruiseMissiles', false)
                    self.unit:SetWeaponEnabledByLabel('CruiseMissile', true)
		         	LOG("HM enabled CM disabled")
				 	LOG("Setting Rack state to Ready")
				 	ChangeState(self, self.RackSalvoFireReadyState)
				end,

                -- Start with the CruiseMissiles off to reduce twitching of ground fire
                Main = function(self)
				    LOG("IdleState Main Start")
				    local bp = self.Blueprint
                    for _, rack in bp.RackBones do
                       if rack.HideMuzzle then
                          for _, muzzle in rack.MuzzleBones do
                              self.unit:ShowBone(muzzle, true)
                          end
                       end
                    end
		         	LOG("Racks Cycled 1 done")
                if self.NumRackBones > 1 and self.CurrentRackSalvoNumber > 1 then
                   WaitSeconds(bp.RackReloadTimeout)
                   self:PlayFxRackSalvoReloadSequence()
                   self.CurrentRackSalvoNumber = 1
                end
				LOG("Racks Cycled 2 done")
			       	if not self.TargetAcquired then
						LOG("No New Target Acquired while idle ")
                    	self.unit:SetWeaponEnabledByLabel('CruiseMissiles', true)
                    	self.unit:SetWeaponEnabledByLabel('CruiseMissile', false)
                    	LOG("Enabling CMs Disabling HMs Restarting Idle Loop")
						TargetingLaser.IdleState.Main(self)

			       	end

			end,
			
            },
    },
			

        CruiseMissile = Class(TIFCruiseMissileLauncher) {
						
                CurrentRack = 1,
           
                PlayFxMuzzleSequence = function(self, muzzle)
                    local bp = self:GetBlueprint()
                    self.Rotator = CreateRotator(self.unit, bp.RackBones[self.CurrentRack].RackBone, 'y', nil, 90, 90, 90)
                    muzzle = bp.RackBones[self.CurrentRack].MuzzleBones[1]
                    self.Rotator:SetGoal(90)
                    TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
                    WaitFor(self.Rotator)
                    WaitSeconds(1)
					LOG("PlayFxMuzzleSequence1")
                    self.unit:SetWeaponEnabledByLabel('CruiseMissiles', false)
					LOG("Disabling Cruise Missle")
                end,
                
                CreateProjectileAtMuzzle = function(self, muzzle)
                    muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
                    if self.CurrentRack >= 4 then
                        self.CurrentRack = 1
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
                end,
                
                PlayFxRackReloadSequence = function(self)
                    WaitSeconds(1)
                    self.Rotator:SetGoal(0)
                    WaitFor(self.Rotator)
                    self.Rotator:Destroy()
                    self.Rotator = nil
					LOG("Reload of HM Complete Nothing to Re-enable")
                end,
            },
		CruiseMissiles = Class(TIFCruiseMissileLauncher) {
								
                CurrentRack = 1,
				Rack1 = 1,
				Rack2 = 2,
				Rack3 = 3,
				Rack4 = 4,
				NRack = 5,
				NextRack = 6,
				NextNextRack = 7,
				NextNextNextRack = 8,
           
				PlayFxMuzzleSequence = function(self, muzzle)
                    local bp = self:GetBlueprint()
                    self.Rotators = {}
                    for rack = self.Rack1, self.NextNextNextRack do
                        local rotator = CreateRotator(self.unit, bp.RackBones[rack].RackBone, 'y', nil, 90, 90, 90)
                        rotator:SetGoal(90)
                        table.insert(self.Rotators, rotator)
                    end
                    muzzle = bp.RackBones[self.CurrentRack].MuzzleBones[1]
                    for _, rotator in self.Rotators do
                        WaitFor(rotator)
                    end
                    LOG("PlayFxMuzzleSequence2s")
					self.unit:SetWeaponEnabledByLabel('TargetPainter', false)
                    self.unit:SetWeaponEnabledByLabel('CruiseMissile', false)
					LOG("Disabled HM and TargetPainter")
                end,
                
                CreateProjectileAtMuzzle = function(self, muzzle)
                muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 1
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 2
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 3
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 4
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
					WaitSeconds(4)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 5
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 6
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 7
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
				TIFCruiseMissileLauncher.PlayFxMuzzleSequence(self, muzzle)
				WaitSeconds(1.5)
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 8
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
                    TIFCruiseMissileLauncher.CreateProjectileAtMuzzle(self, muzzle)
				muzzle = self:GetBlueprint().RackBones[self.CurrentRack].MuzzleBones[1]
                    if self.CurrentRack >= 8 then
                        self.CurrentRack = 1
                    else
                        self.CurrentRack = self.CurrentRack + 1
                    end
					
                end,
                
                PlayFxRackReloadSequence = function(self)
                    for _, rotator in self.Rotators do
                        rotator:SetGoal(0)
                    end
                    for _, rotator in self.Rotators do
                        WaitFor(rotator)
                        rotator:Destroy()
                    end
                    self.Rotators = nil
					self.unit:SetWeaponEnabledByLabel('TargetPainter', true)

					LOG("Reload of CM Complete TargetPainter")
                end,
            },
			
		FrontTurret01 = Class(TDFGaussCannonWeapon) {},
        BackTurret02 = Class(TSAMLauncher) {
            FxMuzzleFlash = EffectTemplate.TAAMissileLaunchNoBackSmoke,
        },

        PhalanxGun01 = Class(TAMPhalanxWeapon) {
            PlayFxWeaponUnpackSequence = function(self)
                if not self.SpinManip then 
                    self.SpinManip = CreateRotator(self.unit, 'Center_Turret_Barrel', 'z', nil, 270, 180, 60)
                    self.SpinManip:SetPrecedence(10)
                    self.unit.Trash:Add(self.SpinManip)
                end
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(270)
                end
                TAMPhalanxWeapon.PlayFxWeaponUnpackSequence(self)
            end,

            PlayFxWeaponPackSequence = function(self)
                if self.SpinManip then
                    self.SpinManip:SetTargetSpeed(0)
                end
                TAMPhalanxWeapon.PlayFxWeaponPackSequence(self)
            end,
        },
        
    },


    RadarThread = function(self)
        local spinner = CreateRotator(self, 'Spinner04', 'x', nil, 0, 30, -45)
        while true do
            WaitFor(spinner)
            spinner:SetTargetSpeed(-45)
            WaitFor(spinner)
            spinner:SetTargetSpeed(45)
        end
    end,

    OnStopBeingBuilt = function(self, builder,layer)
        TSeaUnit.OnStopBeingBuilt(self, builder,layer)
        self:ForkThread(self.RadarThread)
        self.Trash:Add(CreateRotator(self, 'Spinner01', 'y', nil, 45, 0, 0))
        self.Trash:Add(CreateRotator(self, 'Spinner03', 'y', nil, -30, 0, 0))
    end,
	
}

TypeClass = UES0202