---@class CConstructionEggUnit : CStructureUnit
CConstructionEggUnit = ClassUnit(CStructureUnit) {

    ---@param self CConstructionEggUnit
    ---@param builder Unit
    ---@param layer Layer
    OnStopBeingBuilt = function(self, builder, layer)
        LandFactoryUnit.OnStopBeingBuilt(self, builder, layer)
        local bp = self:GetBlueprint()
        local buildUnit = bp.Economy.BuildUnit
        local pos = self:GetPosition()
        local aiBrain = self:GetAIBrain()
		local orientation = self:GetOrientation()

        self:ForkThread(function()
                WaitSeconds(2)
                self.OpenAnimManip = CreateAnimator(self)
                self.Trash:Add(self.OpenAnimManip)
                self.OpenAnimManip:PlayAnim(self:GetBlueprint().Display.AnimationOpen, false):SetRate(1)
                self:PlaySound(bp.Audio['EggOpen'])
                WaitSeconds(0.2)
				pos = self:GetPosition()
        self.Spawn = CreateUnitHPR(
            buildUnit,
            aiBrain.Name,
            pos[1], pos[2], pos[3],
            0, 0, 0
        )
		self.Spawn:SetOrientation(orientation, true)
                WaitFor(self.OpenAnimManip)

                self.EggSlider = CreateSlider(self, 0, 0, -20, 0, 25)
                self.Trash:Add(self.EggSlider)
                self:PlaySound(bp.Audio['EggSink'])

                WaitFor(self.EggSlider)

                self:Destroy()
            end
        )
    end,

    ---@param self CConstructionEggUnit
    ---@param instigator Unit
    ---@param type DamageType
    ---@param overkillRatio number
    OnKilled = function(self, instigator, type, overkillRatio)
        if self.Spawn then overkillRatio = 1.1 end
        CStructureUnit.OnKilled(self, instigator, type, overkillRatio)
    end,
}