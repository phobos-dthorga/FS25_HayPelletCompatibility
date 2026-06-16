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
    if fillLevelDelta > 0 and fillTypeIndex == sourceFillType and HPC:vehicleShouldConvert(self, fillUnitIndex) then
        local appliedTarget = superFunc(self, farmId, fillUnitIndex, fillLevelDelta * HPC.CONVERSION_FACTOR, targetFillType, toolType, fillPositionData)
        return appliedTarget / HPC.CONVERSION_FACTOR
    end

    return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end

function HPC:targetAllowsFillType(target, fillTypeIndex, extraAttributes)
    if target ~= nil and target.getIsFillTypeAllowed ~= nil then
        return target:getIsFillTypeAllowed(fillTypeIndex, extraAttributes) == true
    end

    return false
end

function HPC:configureUnloadTrigger(unloadTrigger)
    local sourceFillType, targetFillType = self:getConversionFillTypes()
    if sourceFillType == nil or unloadTrigger == nil or unloadTrigger.fillTypeConversions == nil then
        return
    end

    if unloadTrigger.fillTypeConversions[sourceFillType] ~= nil then
        return
    end

    if not self:targetAllowsFillType(unloadTrigger.target, targetFillType, unloadTrigger.extraAttributes) then
        return
    end

    if self:targetAllowsFillType(unloadTrigger.target, sourceFillType, unloadTrigger.extraAttributes) then
        return
    end

    unloadTrigger.fillTypeConversions[sourceFillType] = {
        outgoingFillType = targetFillType,
        ratio = self.CONVERSION_FACTOR
    }

    if unloadTrigger.fillTypes ~= nil and unloadTrigger.fillTypes[targetFillType] ~= nil then
        unloadTrigger.fillTypes[sourceFillType] = true
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
            self:configureUnloadTrigger(feedingTrough)
        end
    end
end

function HPC:addFood(superFunc, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
    local sourceFillType, targetFillType = HPC:getConversionFillTypes()
    local spec = self.spec_husbandryFood

    if deltaFillLevel > 0 and fillTypeIndex == sourceFillType and spec ~= nil and spec.supportedFillTypes ~= nil then
        if spec.supportedFillTypes[targetFillType] ~= nil and spec.supportedFillTypes[sourceFillType] == nil then
            local appliedTarget = superFunc(self, farmId, deltaFillLevel * HPC.CONVERSION_FACTOR, targetFillType, fillPositionData, toolType, extraAttributes)
            return appliedTarget / HPC.CONVERSION_FACTOR
        end
    end

    return superFunc(self, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
end

function HPC:stationShouldConvert(station)
    local sourceFillType, targetFillType = self:getConversionFillTypes()
    if sourceFillType == nil or station == nil or station.supportedFillTypes == nil then
        return false
    end

    return station.supportedFillTypes[targetFillType] ~= nil and station.supportedFillTypes[sourceFillType] == nil
end

function HPC:addFillLevelFromTool(superFunc, farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
    local sourceFillType, targetFillType = HPC:getConversionFillTypes()
    if deltaFillLevel > 0 and fillTypeIndex == sourceFillType and HPC:stationShouldConvert(self) then
        local appliedTarget = superFunc(self, farmId, deltaFillLevel * HPC.CONVERSION_FACTOR, targetFillType, fillPositionData, toolType, extraAttributes)
        return appliedTarget / HPC.CONVERSION_FACTOR
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
    MixerWagon.addFillUnitFillLevel = Utils.overwrittenFunction(MixerWagon.addFillUnitFillLevel, HPC.addFillUnitFillLevel)
end

if UnloadTrigger ~= nil then
    UnloadTrigger.load = Utils.appendedFunction(UnloadTrigger.load, function(unloadTrigger)
        HPC:configureUnloadTrigger(unloadTrigger)
    end)

    UnloadTrigger.loadFillTypes = Utils.appendedFunction(UnloadTrigger.loadFillTypes, function(unloadTrigger)
        HPC:configureUnloadTrigger(unloadTrigger)
    end)

    UnloadTrigger.setTarget = Utils.appendedFunction(UnloadTrigger.setTarget, function(unloadTrigger)
        HPC:configureUnloadTrigger(unloadTrigger)
    end)
end

if PlaceableHusbandryFood ~= nil then
    PlaceableHusbandryFood.onPostLoad = Utils.appendedFunction(PlaceableHusbandryFood.onPostLoad, function(placeable)
        HPC:configureHusbandryFood(placeable)
    end)

    PlaceableHusbandryFood.addFood = Utils.overwrittenFunction(PlaceableHusbandryFood.addFood, HPC.addFood)
end

if UnloadingStation ~= nil and UnloadingStation.addFillLevelFromTool ~= nil then
    UnloadingStation.addFillLevelFromTool = Utils.overwrittenFunction(UnloadingStation.addFillLevelFromTool, HPC.addFillLevelFromTool)
end
