local enums = require("consts.celeste_enums")

local everestChangeInventory = {}

everestChangeInventory.name = "everest/changeInventoryTrigger"
everestChangeInventory.associatedMods = {"Everest"}
everestChangeInventory.fieldInformation = {
    inventory = {
        options = enums.inventories
    }
}
everestChangeInventory.placements = {
    name = "change_inventory",
    data = {
        inventory = "Default"
    }
}

return everestChangeInventory