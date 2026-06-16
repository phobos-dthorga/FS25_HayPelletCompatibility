HayPelletCompatibility = {
    MOD_NAME = g_currentModName or "FS25_HayPelletCompatibility",
    CONVERTER_NAME = "HAY_PELLETS_TO_HAY",
    SOURCE_FILL_TYPE_NAME = "HAY_PELLETS",
    TARGET_FILL_TYPE_NAME = "DRYGRASS_WINDROW",
    CONVERSION_FACTOR = 4,
    converterRegistered = false
}

local HPC = HayPelletCompatibility

function HPC:getFillTypeIndex(name)
    if g_fillTypeManager ~= nil then
        return g_fillTypeManager:getFillTypeIndexByName(name)
    end

    if FillType ~= nil then
        return FillType[name]
    end

    return nil
end

function HPC:getConversionFillTypes()
    local sourceFillType = self:getFillTypeIndex(self.SOURCE_FILL_TYPE_NAME)
    local targetFillType = self:getFillTypeIndex(self.TARGET_FILL_TYPE_NAME)

    if sourceFillType == nil or targetFillType == nil then
        return nil, nil
    end

    return sourceFillType, targetFillType
end

function HPC:hasRawFillUnitSupport(vehicle, fillUnitIndex, fillTypeIndex)
    local spec = vehicle.spec_fillUnit
    if spec == nil or spec.fillUnits == nil then
        return false
    end

    local fillUnit = spec.fillUnits[fillUnitIndex]
    if fillUnit == nil or fillUnit.supportedFillTypes == nil then
        return false
    end

    return fillUnit.supportedFillTypes[fillTypeIndex] ~= nil
end

function HPC:hasMixerIngredient(vehicle, fillUnitIndex, fillTypeIndex)
    local spec = vehicle.spec_mixerWagon
    if spec == nil or spec.fillUnitIndex ~= fillUnitIndex or spec.fillTypeToMixerWagonFillType == nil then
        return false
    end

    return spec.fillTypeToMixerWagonFillType[fillTypeIndex] ~= nil
end

function HPC:vehicleShouldConvert(vehicle, fillUnitIndex)
    local sourceFillType, targetFillType = self:getConversionFillTypes()
    if sourceFillType == nil then
        return false
    end

    local supportsSource = self:hasRawFillUnitSupport(vehicle, fillUnitIndex, sourceFillType) or self:hasMixerIngredient(vehicle, fillUnitIndex, sourceFillType)
    if supportsSource then
        return false
    end

    return self:hasRawFillUnitSupport(vehicle, fillUnitIndex, targetFillType) or self:hasMixerIngredient(vehicle, fillUnitIndex, targetFillType)
end

function HPC:getFillUnitSupportsFillType(superFunc, fillUnitIndex, fillTypeIndex)
    local sourceFillType = HPC:getFillTypeIndex(HPC.SOURCE_FILL_TYPE_NAME)
    if fillTypeIndex == sourceFillType and HPC:vehicleShouldConvert(self, fillUnitIndex) then
        return true
    end

    return superFunc(self, fillUnitIndex, fillTypeIndex)
end

function HPC:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillTypeIndex)
    local sourceFillType, targetFillType = HPC:getConversionFillTypes()
    if fillTypeIndex == sourceFillType and HPC:vehicleShouldConvert(self, fillUnitIndex) then
        return superFunc(self, fillUnitIndex, targetFillType)
    end

    return superFunc(self, fillUnitIndex, fillTypeIndex)
end

function HPC:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    local sourceFillType, targetFillType = HPC:getConversionFillTypes()
    if type(fillLevelDelta) == "number" and fillLevelDelta > 0 and fillTypeIndex == sourceFillType and HPC:vehicleShouldConvert(self, fillUnitIndex) then
        local appliedTarget = superFunc(self, farmId, fillUnitIndex, fillLevelDelta * HPC.CONVERSION_FACTOR, targetFillType, toolType, fillPositionData)
        return (appliedTarget or 0) / HPC.CONVERSION_FACTOR
    end

    return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end

function HPC:addMixerWagonFillUnitFillLevel(mixerWagonFunc, superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
    local sourceFillType, targetFillType = HPC:getConversionFillTypes()
    if type(fillLevelDelta) == "number" and fillLevelDelta > 0 and fillTypeIndex == sourceFillType and HPC:vehicleShouldConvert(self, fillUnitIndex) then
        local appliedTarget = mixerWagonFunc(self, superFunc, farmId, fillUnitIndex, fillLevelDelta * HPC.CONVERSION_FACTOR, targetFillType, toolType, fillPositionData)
        return (appliedTarget or 0) / HPC.CONVERSION_FACTOR
    end

    return mixerWagonFunc(self, superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end

function HPC:configureHusbandryFeedingTrough(feedingTrough)
    local sourceFillType, targetFillType = self:getConversionFillTypes()
    if sourceFillType == nil or feedingTrough == nil or feedingTrough.fillTypeConversions == nil then
        return
    end

    if feedingTrough.fillTypeConversions[sourceFillType] ~= nil then
        return
    end

    if feedingTrough.fillTypes ~= nil and feedingTrough.fillTypes[targetFillType] == nil then
        return
    end

    feedingTrough.fillTypeConversions[sourceFillType] = {
        outgoingFillType = targetFillType,
        ratio = self.CONVERSION_FACTOR
    }

    if feedingTrough.fillTypes ~= nil then
        feedingTrough.fillTypes[sourceFillType] = true
    end
end

function HPC:configureHusbandryFood(placeable)
    local spec = placeable.spec_husbandryFood
    local sourceFillType, targetFillType = self:getConversionFillTypes()

    if sourceFillType == nil or spec == nil or spec.supportedFillTypes == nil then
        return
    end

    if spec.supportedFillTypes[targetFillType] == nil or spec.supportedFillTypes[sourceFillType] ~= nil then
        return
    end

    if spec.feedingTroughs ~= nil then
        for _, feedingTrough in ipairs(spec.feedingTroughs) do
            self:configureHusbandryFeedingTrough(feedingTrough)
        end
    end
end

function HPC:addFood(superFunc, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
    local sourceFillType, targetFillType = HPC:getConversionFillTypes()
    local spec = self.spec_husbandryFood

    if type(deltaFillLevel) == "number" and deltaFillLevel > 0 and fillTypeIndex == sourceFillType and spec ~= nil and spec.supportedFillTypes ~= nil then
        if spec.supportedFillTypes[targetFillType] ~= nil and spec.supportedFillTypes[sourceFillType] == nil then
            local appliedTarget = superFunc(self, farmId, deltaFillLevel * HPC.CONVERSION_FACTOR, targetFillType, fillPositionData, toolType, extraAttributes)
            return (appliedTarget or 0) / HPC.CONVERSION_FACTOR
        end
    end

    return superFunc(self, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
end

function HPC:registerFillTypeConverter()
    if self.converterRegistered or g_fillTypeManager == nil then
        return
    end

    local sourceFillType, targetFillType = self:getConversionFillTypes()
    if sourceFillType == nil then
        return
    end

    local converter = g_fillTypeManager:addFillTypeConverter(self.CONVERTER_NAME, false)
    if converter ~= nil then
        g_fillTypeManager:addFillTypeConversion(converter, sourceFillType, targetFillType, self.CONVERSION_FACTOR)
        self.converterRegistered = true
        Logging.info("%s: registered %s (%s -> %s, factor %.2f)", self.MOD_NAME, self.CONVERTER_NAME, self.SOURCE_FILL_TYPE_NAME, self.TARGET_FILL_TYPE_NAME, self.CONVERSION_FACTOR)
    end
end

FillTypeManager.loadModFillTypes = Utils.appendedFunction(FillTypeManager.loadModFillTypes, function()
    HPC:registerFillTypeConverter()
end)

Mission00.load = Utils.appendedFunction(Mission00.load, function()
    HPC:registerFillTypeConverter()
end)

FillUnit.getFillUnitSupportsFillType = Utils.overwrittenFunction(FillUnit.getFillUnitSupportsFillType, HPC.getFillUnitSupportsFillType)
FillUnit.getFillUnitAllowsFillType = Utils.overwrittenFunction(FillUnit.getFillUnitAllowsFillType, HPC.getFillUnitAllowsFillType)
FillUnit.addFillUnitFillLevel = Utils.overwrittenFunction(FillUnit.addFillUnitFillLevel, HPC.addFillUnitFillLevel)

if MixerWagon ~= nil then
    MixerWagon.addFillUnitFillLevel = Utils.overwrittenFunction(MixerWagon.addFillUnitFillLevel, HPC.addMixerWagonFillUnitFillLevel)
end

if PlaceableHusbandryFood ~= nil then
    PlaceableHusbandryFood.onPostLoad = Utils.appendedFunction(PlaceableHusbandryFood.onPostLoad, function(placeable)
        HPC:configureHusbandryFood(placeable)
    end)

    PlaceableHusbandryFood.addFood = Utils.overwrittenFunction(PlaceableHusbandryFood.addFood, HPC.addFood)
end
