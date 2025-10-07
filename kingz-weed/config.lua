Config = {}

Config.Debug = true -- Set to false in production

-- Weed plant settings
Config.Plants = {
    ['cannabis_seed'] = {
        label = 'Cannabis Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60}, -- 1 minute for testing
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0} -- Final stage
        },
        yield = {
            {item = 'weed', amount = {min = 3, max = 6}, chance = 100},
            {item = 'cannabis_seed', amount = {min = 1, max = 3}, chance = 70}
        },
        thcContent = 5, -- THC percentage (affects potency)
        cbdContent = 2  -- CBD percentage (affects medicinal properties)
    },
    ['purple_haze_seed'] = {
        label = 'Purple Haze Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'purple_haze', amount = {min = 3, max = 6}, chance = 100},
            {item = 'purple_haze_seed', amount = {min = 1, max = 2}, chance = 50}
        },
        thcContent = 12,
        cbdContent = 1
    },
    ['skunk_seed'] = {
        label = 'Skunk Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'skunk', amount = {min = 4, max = 8}, chance = 100},
            {item = 'skunk_seed', amount = {min = 1, max = 2}, chance = 40}
        },
        thcContent = 15,
        cbdContent = 0.5
    },
    ['og_kush_seed'] = {
        label = 'OG Kush Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'og_kush', amount = {min = 5, max = 10}, chance = 100},
            {item = 'og_kush_seed', amount = {min = 1, max = 2}, chance = 30}
        },
        thcContent = 20,
        cbdContent = 0.3
    },
    ['amnesia_seed'] = {
        label = 'Amnesia Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'amnesia', amount = {min = 4, max = 7}, chance = 100},
            {item = 'amnesia_seed', amount = {min = 1, max = 2}, chance = 35}
        },
        thcContent = 18,
        cbdContent = 1
    },
    ['northern_lights_seed'] = {
        label = 'Northern Lights Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'northern_lights', amount = {min = 5, max = 9}, chance = 100},
            {item = 'northern_lights_seed', amount = {min = 1, max = 2}, chance = 30}
        },
        thcContent = 16,
        cbdContent = 3
    },
    ['white_widow_seed'] = {
        label = 'White Widow Plant',
        prop = 'prop_weed_01',
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 60},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 120},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 180},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'white_widow', amount = {min = 6, max = 10}, chance = 100},
            {item = 'white_widow_seed', amount = {min = 1, max = 2}, chance = 25}
        },
        thcContent = 22,
        cbdContent = 0.2
    }
}

-- Hybrid strains from breeding
Config.HybridStrains = {
    ["purple_skunk_seed"] = {
        label = "Purple Skunk",
        parents = {"purple_haze", "skunk"},
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 55}, -- Slightly faster growth
            [2] = {model = `bkr_prop_weed_med_01a`, time = 110},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 165},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'purple_skunk', amount = {min = 5, max = 9}, chance = 100},
            {item = 'purple_skunk_seed', amount = {min = 1, max = 2}, chance = 40}
        },
        thcContent = 18, -- Average of parents + bonus
        cbdContent = 0.8,
        effects = {
            duration = 150,
            movementSpeed = 1.25,
            stressReduction = 25,
            healthIncrease = 12
        }
    },
    ["kush_haze_seed"] = {
        label = "Kush Haze",
        parents = {"og_kush", "purple_haze"},
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 55},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 110},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 165},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'kush_haze', amount = {min = 6, max = 10}, chance = 100},
            {item = 'kush_haze_seed', amount = {min = 1, max = 2}, chance = 35}
        },
        thcContent = 21,
        cbdContent = 0.7,
        effects = {
            duration = 180,
            movementSpeed = 1.35,
            stressReduction = 30,
            healthIncrease = 15
        }
    },
    ["widow_lights_seed"] = {
        label = "Widow Lights",
        parents = {"white_widow", "northern_lights"},
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 50},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 100},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 150},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'widow_lights', amount = {min = 7, max = 12}, chance = 100},
            {item = 'widow_lights_seed', amount = {min = 1, max = 2}, chance = 30}
        },
        thcContent = 24,
        cbdContent = 1.6,
        effects = {
            duration = 210,
            movementSpeed = 1.4,
            stressReduction = 35,
            healthIncrease = 20
        }
    },
    ["amnesia_kush_seed"] = {
        label = "Amnesia Kush",
        parents = {"amnesia", "og_kush"},
        stages = {
            [1] = {model = `bkr_prop_weed_01_small_01a`, time = 55},
            [2] = {model = `bkr_prop_weed_med_01a`, time = 110},
            [3] = {model = `bkr_prop_weed_lrg_01a`, time = 165},
            [4] = {model = `bkr_prop_weed_lrg_01b`, time = 0}
        },
        yield = {
            {item = 'amnesia_kush', amount = {min = 6, max = 11}, chance = 100},
            {item = 'amnesia_kush_seed', amount = {min = 1, max = 2}, chance = 30}
        },
        thcContent = 23,
        cbdContent = 0.7,
        effects = {
            duration = 200,
            movementSpeed = 1.45,
            stressReduction = 32,
            healthIncrease = 18
        }
    }
}

-- Breeding settings
Config.Breeding = {
    crossBreedChance = 30, -- 30% chance to get a hybrid seed
    hybridYieldBonus = 0.2, -- 20% more yield from hybrid plants
    crossBreedingTime = 10000, -- 10 seconds to attempt cross-breeding
    maxBreedingAttempts = 3, -- Max attempts per day per player
    breedingCooldown = 8 -- Hours between breeding attempts
}

-- Harvesting settings
Config.Harvesting = {
    requiredLeaves = 5, -- Number of leaves to harvest
    harvestTime = 2000, -- Time in ms to harvest each leaf
    leafModel = `bkr_prop_weed_leaf_01a`, -- Model for the leaves
    bonusItems = {
        {item = 'weed_nutrition', chance = 5}, -- 5% chance to get nutrition booster
        {item = 'weed_brick', chance = 1}, -- 1% chance to get a brick of weed (rare find)
        {item = 'rolling_paper', chance = 20} -- 20% chance to get rolling papers
    }
}

-- Plant care settings
Config.PlantCare = {
    waterInterval = 300, -- Seconds until plant needs water (5 minutes)
    fertilizeInterval = 600, -- Seconds until plant needs fertilizer (10 minutes)
    waterDecay = 0.5, -- Health decay per minute when very thirsty
    fertilizeDecay = 0.3, -- Health decay per minute when very hungry
    maxHealth = 100.0, -- Maximum plant health
    bugInfestationChance = 5, -- 5% chance per minute for bugs to appear
    bugDamage = 0.8, -- Health decay per minute from bugs
    pesticideProtectionTime = 1800, -- 30 minutes of protection after spraying
    diseaseChance = 2, -- 2% chance per day for plant disease
    diseaseDamage = 1.2, -- Health decay per minute from disease
    cureChance = 70, -- 70% chance to cure disease with medicine
    soilQualityEffect = 0.2 -- 20% effect on growth from soil quality
}

-- Quality system
Config.QualityFactors = {
    waterImpact = 0.25,     -- 25% of quality comes from proper watering
    fertilizerImpact = 0.25, -- 25% of quality comes from proper fertilizing
    heatLampImpact = 0.15,  -- 15% of quality comes from using heat lamps
    pestImpact = 0.15,      -- 15% of quality comes from pest management
    diseaseImpact = 0.10,   -- 10% of quality comes from disease management
    soilImpact = 0.10       -- 10% of quality comes from soil quality
}

Config.QualityLevels = {
    {min = 0, max = 30, name = "Poor", priceMultiplier = 0.6, effectMultiplier = 0.7},
    {min = 31, max = 60, name = "Standard", priceMultiplier = 1.0, effectMultiplier = 1.0},
    {min = 61, max = 85, name = "Premium", priceMultiplier = 1.5, effectMultiplier = 1.3},
    {min = 86, max = 100, name = "Exotic", priceMultiplier = 2.5, effectMultiplier = 1.6}
}

-- Heat lamp settings
Config.HeatLamps = {
    model = `prop_studio_light_02`, -- Model to use for heat lamps
    range = 2.0, -- Range in which heat lamps affect plants
    effects = {
        growthSpeedBonus = 0.25, -- 25% faster growth
        waterConsumptionIncrease = 0.2, -- 20% more water consumption
        maxHealthBonus = 10.0 -- +10 max health for plants under heat lamps
    },
    price = 1500, -- Price to purchase a heat lamp
    electricityCost = 10, -- Cost per hour to run a heat lamp
    maxLampsPerPlayer = 5 -- Maximum number of heat lamps a player can place
}

-- Processing settings
Config.Processing = {
    dryingTime = 60, -- Seconds to dry weed (1 minute)
    rollTime = 30, -- Seconds to roll a joint (30 seconds)
    baggieTime = 20, -- Seconds to bag weed (20 seconds)
    grindTime = 15, -- Seconds to grind weed (15 seconds)
    bongTime = 10, -- Seconds to pack a bong (10 seconds)
    extractTime = 120, -- Seconds to extract concentrates (2 minutes)
    edibleTime = 90, -- Seconds to make edibles (1.5 minutes)
    concentrateYield = 0.5, -- Get 0.5 concentrate from 1 weed
    edibleYield = 3 -- Get 3 edibles from 1 weed
}

-- Drug effects
Config.DrugEffects = {
    ['weed'] = {
        duration = 60, -- Effect duration in seconds
        effects = {
            screenEffect = 'DrugsMichaelAliensFight',
            movementSpeed = 1.1, -- 10% speed increase
            stressReduction = 10, -- Stress reduction amount
            healthIncrease = 5 -- Health increase amount
        }
    },
    ['purple_haze'] = {
        duration = 90,
        effects = {
            screenEffect = 'DrugsTrevorClownsFight',
            movementSpeed = 1.2,
            stressReduction = 15,
            healthIncrease = 8
        }
    },
    ['skunk'] = {
        duration = 120,
        effects = {
            screenEffect = 'DrugsDrivingIn',
            movementSpeed = 1.3,
            stressReduction = 20,
            healthIncrease = 10
        }
    },
    ['og_kush'] = {
        duration = 150,
        effects = {
            screenEffect = 'DrugsMichaelAliensFightIn',
            movementSpeed = 1.4,
            stressReduction = 25,
            healthIncrease = 15
        }
    },
    ['amnesia'] = {
        duration = 180,
        effects = {
            screenEffect = 'DrugsTrevorClownsFightOut',
            movementSpeed = 1.5,
            stressReduction = 30,
            healthIncrease = 20
        }
    },
    ['northern_lights'] = {
        duration = 160,
        effects = {
            screenEffect = 'DrugsMichaelAliensFightIn',
            movementSpeed = 1.3,
            stressReduction = 35,
            healthIncrease = 18
        }
    },
    ['white_widow'] = {
        duration = 200,
        effects = {
            screenEffect = 'DrugsTrevorClownsFightOut',
            movementSpeed = 1.6,
            stressReduction = 40,
            healthIncrease = 25
        }
    },
    ['bong_hit'] = {
        duration = 240,
        effects = {
            screenEffect = 'DrugsMichaelAliensFightIn',
            movementSpeed = 0.8, -- Slows you down
            stressReduction = 40,
            healthIncrease = 25
        }
    },
    ['weed_brownie'] = {
        duration = 300, -- Longer duration for edibles
        effects = {
            screenEffect = 'DrugsMichaelAliensFight',
            movementSpeed = 0.9,
            stressReduction = 50,
            healthIncrease = 30
        }
    },
    ['weed_concentrate'] = {
        duration = 180,
        effects = {
            screenEffect = 'DrugsTrevorClownsFightOut',
            movementSpeed = 1.7,
            stressReduction = 45,
            healthIncrease = 20
        }
    }
}

-- Dealer settings
Config.Dealers = {
    {
        name = "Weed Dealer",
        model = "a_m_y_hipster_01",
        coords = vector4(1240.34, -1578.56, 38.32, 120.0),
        prices = {
            ['weed'] = {min = 50, max = 80},
            ['purple_haze'] = {min = 80, max = 120},
            ['skunk'] = {min = 100, max = 150},
            ['og_kush'] = {min = 120, max = 180},
            ['amnesia'] = {min = 150, max = 200},
            ['northern_lights'] = {min = 140, max = 190},
            ['white_widow'] = {min = 180, max = 250},
            ['joint'] = {min = 70, max = 100},
            ['purple_haze_joint'] = {min = 100, max = 140},
            ['skunk_joint'] = {min = 120, max = 170},
            ['og_kush_joint'] = {min = 150, max = 200},
            ['amnesia_joint'] = {min = 180, max = 250},
            ['northern_lights_joint'] = {min = 170, max = 230},
            ['white_widow_joint'] = {min = 200, max = 280},
            ['packaged_weed'] = {min = 80, max = 120},
            ['packaged_purple_haze'] = {min = 120, max = 180},
            ['packaged_skunk'] = {min = 150, max = 220},
            ['packaged_og_kush'] = {min = 180, max = 250},
            ['packaged_amnesia'] = {min = 220, max = 300},
            ['packaged_northern_lights'] = {min = 200, max = 280},
            ['packaged_white_widow'] = {min = 250, max = 350},
            ['weed_concentrate'] = {min = 300, max = 450},
            ['weed_brownie'] = {min = 150, max = 250}
        },
        hours = {
            open = 18, -- 6 PM
            close = 4  -- 4 AM
        },
        reputation = true -- This dealer uses the reputation system
    },
    {
        name = "High-End Dealer",
        model = "s_m_m_highsec_01",
        coords = vector4(1112.34, -1298.56, 33.32, 90.0),
        prices = {
            ['purple_haze'] = {min = 100, max = 150},
            ['og_kush'] = {min = 150, max = 220},
            ['amnesia'] = {min = 180, max = 250},
            ['white_widow'] = {min = 220, max = 300},
            ['purple_skunk'] = {min = 200, max = 280},
            ['kush_haze'] = {min = 250, max = 350},
            ['widow_lights'] = {min = 300, max = 400},
            ['amnesia_kush'] = {min = 280, max = 380},
            ['weed_concentrate'] = {min = 350, max = 500}
        },
        hours = {
            open = 22, -- 10 PM
            close = 6  -- 6 AM
        },
        reputation = true,
        minReputation = 5000 -- Need 5000 reputation points to access this dealer
    },
    {
        name = "Medical Supplier",
        model = "s_m_m_doctor_01",
        coords = vector4(356.34, -1420.56, 32.32, 45.0),
        prices = {
            ['northern_lights'] = {min = 180, max = 250}, -- Higher prices for medical strains
            ['weed_brownie'] = {min = 200, max = 300},
            ['weed_medicine'] = {min = 300, max = 450}
        },
        hours = {
            open = 9, -- 9 AM
            close = 17 -- 5 PM
        },
        reputation = false, -- No reputation system for medical supplier
        requiresLicense = true -- Requires medical license
    }
}

-- Buyer mission settings
Config.BuyerMissions = {
    cooldown = 600, -- 10 minutes between missions
    locations = {
        vector4(1247.08, -1601.64, 53.28, 28.54),
        vector4(1230.23, -1590.57, 53.77, 30.11),
        vector4(1245.24, -1626.29, 53.28, 26.89),
        vector4(1258.45, -1632.25, 53.26, 300.94),
        vector4(1260.98, -1610.55, 54.74, 205.54),
        -- Add more locations for variety
        vector4(1125.45, -1555.25, 34.26, 270.94),
        vector4(980.98, -1490.55, 30.74, 180.54),
        vector4(856.45, -1632.25, 29.26, 90.94),
        vector4(1050.98, -1700.55, 33.74, 0.54),
        vector4(1325.45, -1450.25, 36.26, 45.94)
    },
    rewards = {
        cash = {min = 500, max = 2000},
        items = {
            {item = 'cannabis_seed', amount = {min = 1, max = 3}, chance = 30},
            {item = 'purple_haze_seed', amount = {min = 1, max = 2}, chance = 20},
            {item = 'skunk_seed', amount = {min = 1, max = 2}, chance = 15},
            {item = 'og_kush_seed', amount = {min = 1, max = 1}, chance = 10},
            {item = 'amnesia_seed', amount = {min = 1, max = 1}, chance = 5},
            {item = 'northern_lights_seed', amount = {min = 1, max = 1}, chance = 5},
            {item = 'white_widow_seed', amount = {min = 1, max = 1}, chance = 3},
            {item = 'weed_nutrition', amount = {min = 1, max = 1}, chance = 15},
            {item = 'premium_soil', amount = {min = 1, max = 1}, chance = 10}
        }
    },
    policeAlertChance = 10, -- 10% chance to alert police
    timeLimit = 600, -- 10 minutes to complete the mission
    missionTypes = {
        "delivery", -- Standard delivery
        "highRisk", -- Higher reward but higher police alert chance
        "multiDrop" -- Multiple delivery locations
    },
    vehicleRewards = {
        {vehicle = "panto", chance = 1}, -- 1% chance to win a Panto
        {vehicle = "faggio", chance = 5}  -- 5% chance to win a Faggio
    }
}

-- Shop settings
Config.Shop = {
    location = vector4(1242.63, -1578.96, 38.32, 305.0),
    items = {
        {item = 'cannabis_seed', price = 100, label = 'Cannabis Seed'},
        {item = 'purple_haze_seed', price = 200, label = 'Purple Haze Seed'},
        {item = 'skunk_seed', price = 300, label = 'Skunk Seed'},
        {item = 'og_kush_seed', price = 500, label = 'OG Kush Seed'},
        {item = 'amnesia_seed', price = 750, label = 'Amnesia Seed'},
        {item = 'northern_lights_seed', price = 650, label = 'Northern Lights Seed'},
        {item = 'white_widow_seed', price = 1000, label = 'White Widow Seed'},
        {item = 'water_bottle', price = 10, label = 'Water Bottle'},
        {item = 'fertilizer', price = 20, label = 'Fertilizer'},
        {item = 'pesticide', price = 50, label = 'Pesticide'},
        {item = 'rolling_paper', price = 2, label = 'Rolling Paper'},
        {item = 'empty_baggie', price = 1, label = 'Empty Baggie'},
        {item = 'grinder', price = 150, label = 'Grinder'},
        {item = 'bong', price = 250, label = 'Bong'},
        {item = 'heat_lamp', price = 1500, label = 'Heat Lamp'},
        {item = 'weed_medicine', price = 100, label = 'Plant Medicine'},
        {item = 'premium_soil', price = 75, label = 'Premium Soil'},
        {item = 'weed_nutrition', price = 120, label = 'Plant Nutrition Booster'},
        {item = 'extraction_kit', price = 500, label = 'Concentrate Extraction Kit'},
        {item = 'brownie_mix', price = 50, label = 'Brownie Mix'},
        {item = 'hydroponic_kit', price = 2500, label = 'Hydroponic Growing Kit'}
    }
}

-- Shop reputation system
Config.ShopReputation = {
    levels = {
        {min = 0, max = 999, name = "Newcomer", discount = 0},
        {min = 1000, max = 2999, name = "Regular", discount = 0.05},
        {min = 3000, max = 5999, name = "Trusted", discount = 0.10},
        {min = 6000, max = 9999, name = "VIP", discount = 0.15},
        {min = 10000, max = 999999, name = "Partner", discount = 0.25}
    },
    pointsPerPurchase = 10,
    pointsPerSale = 5,
    specialItems = { -- Items that unlock at certain reputation levels
        {item = 'rare_seed_pack', rep = 2000, price = 1500},
        {item = 'advanced_growing_kit', rep = 5000, price = 3000},
        {item = 'master_grower_handbook', rep = 8000, price = 5000}
    }
}

-- Competitions
Config.Competitions = {
    enabled = true,
    intervalHours = 24, -- Competition every 24 hours
    durationHours = 12, -- Competition lasts 12 hours
    entryFee = 1000,    -- $1000 to enter
    prizes = {
        {place = 1, cash = 10000, reputation = 1000, item = 'trophy_gold'},
        {place = 2, cash = 5000, reputation = 500, item = 'trophy_silver'},
        {place = 3, cash = 2500, reputation = 250, item = 'trophy_bronze'}
    },
    categories = {
        "Highest THC Content",
        "Best Quality",
        "Most Exotic Strain",
        "Best Hybrid"
    }
}

-- Seasonal effects
Config.Seasons = {
    spring = {
        growthBonus = 0.2,    -- 20% faster growth
        waterDecayIncrease = 0.1, -- 10% faster water consumption
        bugChanceMultiplier = 1.5 -- 50% more bugs in spring
    },
    summer = {
        growthBonus = 0.1,    -- 10% faster growth
        waterDecayIncrease = 0.3, -- 30% faster water consumption
        bugChanceMultiplier = 1.2 -- 20% more bugs in summer
    },
    fall = {
        growthBonus = 0,      -- Normal growth
        waterDecayIncrease = 0, -- Normal water consumption
        bugChanceMultiplier = 1.0 -- Normal bugs in fall
    },
    winter = {
        growthBonus = -0.2,   -- 20% slower growth
        waterDecayIncrease = -0.1, -- 10% slower water consumption
        bugChanceMultiplier = 0.5 -- 50% fewer bugs in winter
    }
}

-- Function to get current season
function GetCurrentSeason()
    local month = tonumber(os.date("%m"))
    
    if month >= 3 and month <= 5 then
        return "spring"
    elseif month >= 6 and month <= 8 then
        return "summer"
    elseif month >= 9 and month <= 11 then
        return "fall"
    else
        return "winter"
    end
end

-- Hydroponics system
Config.Hydroponics = {
    enabled = true,
    growthBonus = 0.5, -- 50% faster growth with hydroponics
    yieldBonus = 0.3, -- 30% more yield
    qualityBonus = 15, -- +15 quality points
    setupCost = 2500, -- Cost to set up a hydroponic system
    maintenanceCost = 100, -- Daily maintenance cost
    waterSavings = 0.7, -- 70% less water consumption
    maxSystemsPerPlayer = 3, -- Maximum number of hydroponic systems per player
    model = `bkr_prop_weed_01_small_01c`, -- Model for hydroponic plants
    requiresElectricity = true -- Requires electricity to function
}

-- Indoor growing locations
Config.IndoorLocations = {
    {
        name = "Small Grow House",
        price = 25000,
        capacity = 10, -- Max plants
        coords = vector4(1060.0, -3095.0, -39.0, 90.0),
        interior = true,
        hydroponicsReady = false,
        securityLevel = 1, -- 1-3, affects raid chance
        electricityCost = 50 -- Daily cost
    },
    {
        name = "Medium Grow House",
        price = 50000,
        capacity = 20,
        coords = vector4(1066.0, -3183.0, -39.0, 90.0),
        interior = true,
        hydroponicsReady = true,
        securityLevel = 2,
        electricityCost = 100
    },
    {
        name = "Large Grow Operation",
        price = 100000,
        capacity = 40,
        coords = vector4(1088.0, -3195.0, -39.0, 90.0),
        interior = true,
        hydroponicsReady = true,
        securityLevel = 3,
        electricityCost = 200
    }
}

-- Police raid settings
Config.PoliceRaids = {
    enabled = true,
    minCopsRequired = 3,
    chancePerPlant = 0.5, -- 0.5% chance per plant of getting raided
    maxChance = 30, -- Maximum 30% chance regardless of plant count
    securityEffectiveness = {
        [1] = 0.8, -- Level 1 security reduces raid chance by 20%
        [2] = 0.6, -- Level 2 security reduces raid chance by 40%
        [3] = 0.4  -- Level 3 security reduces raid chance by 60%
    },
    cooldown = 24, -- Hours between possible raids
    reputationLoss = 500, -- Reputation points lost if raided
    evidenceItems = { -- Items that can be found as evidence
        "weed",
        "purple_haze",
        "skunk",
        "og_kush",
        "amnesia",
        "northern_lights",
        "white_widow"
    }
}

-- Weed business settings
Config.Business = {
    enabled = true,
    licenseCost = 25000, -- Cost for a business license
    taxRate = 0.15, -- 15% tax on sales through legitimate business
    locations = {
        {
            name = "Green Therapeutics",
            price = 150000,
            coords = vector4(374.0, -828.0, 29.0, 90.0),
            blip = {
                sprite = 140,
                color = 2,
                scale = 0.8
            },
            employees = 3, -- Max employees
            dailyExpenses = 500, -- Daily running costs
            customerFrequency = 10, -- Customers per hour
            inventoryLimit = 500 -- Max inventory
        },
        {
            name = "Herbal Essentials",
            price = 250000,
            coords = vector4(198.0, -240.0, 54.0, 0.0),
            blip = {
                sprite = 140,
                color = 2,
                scale = 0.8
            },
            employees = 5,
            dailyExpenses = 800,
            customerFrequency = 15,
            inventoryLimit = 1000
        }
    },
    upgrades = {
        {name = "Security System", price = 15000, securityBonus = 1},
        {name = "Marketing Campaign", price = 10000, customerBonus = 5},
        {name = "Staff Training", price = 8000, efficiencyBonus = 0.1},
        {name = "Inventory Expansion", price = 20000, inventoryBonus = 200}
    }
}

-- Research and development
Config.Research = {
    enabled = true,
    researchPoints = {
        perHarvest = 5, -- Points earned per harvest
        perSale = 2, -- Points earned per sale
        perCompetition = 50 -- Points earned per competition
    },
    upgrades = {
        {
            name = "Growth Acceleration",
            levels = 3,
            pointsRequired = {100, 300, 600},
            effects = {
                growthBonus = {0.1, 0.2, 0.3} -- 10%, 20%, 30% faster growth
            }
        },
        {
            name = "Yield Enhancement",
            levels = 3,
            pointsRequired = {150, 350, 700},
            effects = {
                yieldBonus = {0.1, 0.2, 0.3} -- 10%, 20%, 30% more yield
            }
        },
        {
            name = "Quality Control",
            levels = 3,
            pointsRequired = {200, 400, 800},
            effects = {
                qualityBonus = {5, 10, 15} -- +5, +10, +15 quality points
            }
        },
        {
            name = "Resource Efficiency",
            levels = 3,
            pointsRequired = {120, 320, 650},
            effects = {
                waterSavings = {0.1, 0.2, 0.3}, -- 10%, 20%, 30% less water consumption
                fertilizerSavings = {0.1, 0.2, 0.3} -- 10%, 20%, 30% less fertilizer consumption
            }
        },
        {
            name = "Pest Resistance",
            levels = 3,
            pointsRequired = {130, 330, 680},
            effects = {
                bugResistance = {0.2, 0.4, 0.6} -- 20%, 40%, 60% less bug infestations
            }
        }
    }
}

-- Achievements
Config.Achievements = {
    {
        id = "first_harvest",
        name = "Green Thumb",
        description = "Harvest your first plant",
        reward = {
            item = "achievement_badge",
            amount = 1,
            reputation = 100
        }
    },
    {
        id = "harvest_100",
        name = "Master Grower",
        description = "Harvest 100 plants",
        reward = {
            item = "master_grower_badge",
            amount = 1,
            reputation = 500
        }
    },
    {
        id = "sell_10000",
        name = "Drug Kingpin",
        description = "Sell $10,000 worth of weed",
        reward = {
            item = "kingpin_chain",
            amount = 1,
            reputation = 1000
        }
    },
    {
        id = "breed_hybrid",
        name = "Genetic Engineer",
        description = "Successfully breed a hybrid strain",
        reward = {
            item = "rare_seed_pack",
            amount = 1,
            reputation = 300
        }
    },
    {
        id = "win_competition",
        name = "Award Winner",
        description = "Win a weed competition",
        reward = {
            item = "golden_grinder",
            amount = 1,
            reputation = 800
        }
    },
    {
        id = "max_quality",
        name = "Quality Control",
        description = "Grow a plant with 100% quality",
        reward = {
            item = "quality_badge",
            amount = 1,
            reputation = 400
        }
    }
}

-- Phone app integration
Config.PhoneApp = {
    enabled = true,
    features = {
        plantTracking = true, -- Track plant growth on phone
        notifications = true, -- Get notifications about plants
        shopOrdering = true, -- Order supplies from phone
        businessManagement = true, -- Manage business from phone
        competitionRegistration = true -- Register for competitions from phone
    }
}

-- Debug print function
function DebugPrint(...)
    if Config.Debug then
        print('[kingz-weed]', ...)
    end
end
