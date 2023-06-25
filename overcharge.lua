
-- All functions in this file (inside /lua/shared) should be:
-- - pure: they should only use the arguments provided, do not touch any global state.
-- - sim / ui proof: they should work for both sim code and ui code.

--- Formula to compute the damage of an overcharge.
EnergyAsDamage = function(energy)
    return 500 * math.pow((1 + 0.000226772201039838), energy - 5000)
end

--- Formula to compute the energy drain of an overcharge.
DamageAsEnergy = function(damage)
    return 5000 * math.pow((1 + 0.0000956110781111796), damage - 500)
end

--- Formula to compute the rate of fire of an overcharge.
DamageAsRateOfFire = function(damage)
    return 4 * math.pow((1 + 0.0000478043964253771), damage - 500)
end	