-- Constants used by the game for entity depths etc.
-- Some extra added for convenience sake
local depths = {
    bgTerrain = 10000,
    bgMirrors = 9500,
    bgDecals = 9000,
    bgParticles = 8000,
    SolidsBelow = 5000,
    below = 2000,
    npcs = 1000,
    theoCrystal = 100,
    player = 0,
    dust = -50,
    pickups = -100,
    seeker = -200,
    particles = -8000,
    above = -8500,
    solids = -9000,
    fgTerrain = -10000,
    fgDecals = -10500,
    dreamBlocks = -11000,
    crystalSpinners = -11500,
    playerDreamDashing = -12000,
    enemy = -12500,
    fakeWalls = -13000,
    fgParticles = -50000,
    top = -1000000,
    formationSequences = -2000000,
    triggers = -math.huge
}

return depths