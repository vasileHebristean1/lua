SkylineYarder = {};
SkylineYarder.confDir = getUserProfileAppPath().. "modsSettings/SkylineYarder/";
SkylineYarder.modDirectory  = g_currentModDirectory
SkylineYarder.yarders = {}
SkylineYarder.numOfYarders = 0
SkylineYarder.selectedYarderId = nil
local modName = g_currentModName

function SkylineYarder.prerequisitesPresent(specializations)
    return true
end

function SkylineYarder.registerOverwrittenFunctions(vehicleType)
	if SkylineYarder.syPlayer == nil then
		Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, SkylineYarder.registerActionEventsPlayer);
		SkylineYarder.syPlayer = true
	end
end

function SkylineYarder.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "saveToXmlYarder", SkylineYarder.saveToXmlYarder)
	SpecializationUtil.registerFunction(vehicleType, "loadFromXmlYarder", SkylineYarder.loadFromXmlYarder)
	SpecializationUtil.registerFunction(vehicleType, "toggleYarder", SkylineYarder.toggleYarder)
	SpecializationUtil.registerFunction(vehicleType, "createPlayerShape", SkylineYarder.createPlayerShape)
	SpecializationUtil.registerFunction(vehicleType, "findTreeForYarder", SkylineYarder.findTreeForYarder)
	SpecializationUtil.registerFunction(vehicleType, "attachYarderRope", SkylineYarder.attachYarderRope)
	SpecializationUtil.registerFunction(vehicleType, "detachYarderRope", SkylineYarder.detachYarderRope)
	SpecializationUtil.registerFunction(vehicleType, "playerInRange", SkylineYarder.playerInRange)
	SpecializationUtil.registerFunction(vehicleType, "switchToNextYarder", SkylineYarder.switchToNextYarder)
	SpecializationUtil.registerFunction(vehicleType, "getIsTurnedOn", SkylineYarder.getIsTurnedOn)
	SpecializationUtil.registerFunction(vehicleType, "syUpdatePhysics", SkylineYarder.syUpdatePhysics)
	SpecializationUtil.registerFunction(vehicleType, "syUpdateValues", SkylineYarder.syUpdateValues)
end

function SkylineYarder:registerActionEventsPlayer()
	if g_dedicatedServerInfo ~= nil then
		return
	end
	if SkylineYarder.event_IDsPlayer == nil then
		SkylineYarder.event_IDsPlayer = {}
	end
	local actions_RC1 = { InputAction.SKYLINEYARDER_ATTACH, InputAction.SKYLINEYARDER_SWITCH, InputAction.SKYLINEYARDER_TOGGLE_ROPEHEIGHT, InputAction.SKYLINEYARDER_TOGGLE_SHOWROPE  }

	for _,actionName in pairs(actions_RC1) do
		local __, eventID = InputBinding.registerActionEvent(g_inputBinding, actionName, self, SkylineYarder.actionCallbackPlayer ,true ,true ,false ,false)
		SkylineYarder.event_IDsPlayer[actionName] = eventID
		if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventID] ~= nil then
			if actionName == InputAction.AUTOLOADWOOD2_TOGGLE_HELP then
				g_inputBinding:setActionEventTextVisibility(eventID, true)
			else
				g_inputBinding:setActionEventTextVisibility(eventID, SkylineYarder.showHelp)
			end
		end
	end
end

function SkylineYarder:onRegisterActionEvents(isSelected, isOnActiveVehicle)
	local spec = self.spec_skylineYarder
	if g_dedicatedServerInfo ~= nil then
		return
	end
	if spec.event_IDs == nil then
		spec.event_IDs = {}
	end
	if isOnActiveVehicle then
		local actions_RC1 = { InputAction.SKYLINEYARDER_ACTIVATE, InputAction.SKYLINEYARDER_TOGGLE_SPEED, InputAction.SKYLINEYARDER_TOGGLE_DISPLAY, InputAction.SKYLINEYARDER_MOVE_HUD_LEFT,
							InputAction.SKYLINEYARDER_MOVE_HUD_RIGHT, InputAction.SKYLINEYARDER_MOVE_HUD_UP, InputAction.SKYLINEYARDER_MOVE_HUD_DOWN, InputAction.SKYLINEYARDER_TOGGLE_EXIT }

		for _,actionName in pairs(actions_RC1) do
			local always = (actionName == InputAction.SKYLINEYARDER_MOVE_HUD_LEFT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_RIGHT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_UP or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_DOWN) and true or false
			local _, eventID = g_inputBinding:registerActionEvent(actionName, self, SkylineYarder.actionCallback, true, true, always, true)
			spec.event_IDs[actionName] = eventID
			if g_inputBinding ~= nil and g_inputBinding.events ~= nil and g_inputBinding.events[eventID] ~= nil then
				if actionName == InputAction.SKYLINEYARDER_MOVE_HUD_LEFT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_RIGHT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_UP or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_DOWN then
					g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_NORMAL)
				else
					g_inputBinding:setActionEventTextPriority(eventID, GS_PRIO_VERY_HIGH)
				end
				if actionName == InputAction.SKYLINEYARDER_TOGGLE_HELP then
					g_inputBinding:setActionEventTextVisibility(eventID, true)
				elseif actionName == InputAction.SKYLINEYARDER_MOVE_HUD_LEFT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_RIGHT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_UP or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_DOWN then
					g_inputBinding:setActionEventTextVisibility(eventID, true)
				else
					g_inputBinding:setActionEventTextVisibility(eventID, SkylineYarder.showHelp)
				end
			end
		end
	end
end

function SkylineYarder.registerEventListeners(vehicleType)
	for _,n in pairs( { "onLoad","onPostLoad","saveToXMLFile", "onPreDelete", "onUpdate","onDraw","onRegisterActionEvents","registerActionEventsPlayer","saveToXmlYarder","loadFromXmlYarder","onReadStream","onWriteStream","onEnterVehicle" } ) do
		SpecializationUtil.registerEventListener(vehicleType, n, SkylineYarder)
	end
end

function SkylineYarder:onLoad(savegame)
	self.spec_skylineYarder = {}
	local spec = self.spec_skylineYarder
	spec.event_IDs = {}
end

function SkylineYarder:onPostLoad(savegame)
	local spec = self.spec_skylineYarder
	
	local xmlFile = self.xmlFile
	if spec.event_IDs == nil then
		spec.event_IDs = {}
	end
	
	spec.ui = g_gameSettings.uiScale
	spec.yarderOverlay = createImageOverlay(SkylineYarder.modDirectory .. "Info_hud.dds")
    setOverlayColor(spec.yarderOverlay, 0, 0, 0, 0.75)
	spec.yarderOverlayWidth = 0.16 * spec.ui;
	spec.yarderOverlayHeight = 0.105 * spec.ui;
	SkylineYarder.yarderOverlayPosX = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterX - 0.1
    SkylineYarder.yarderOverlayPosY = g_currentMission.inGameMenu.hud.speedMeter.gaugeCenterY + 0.13
	spec.yarderInfo1 = ""
	spec.yarderInfo2 = ""
	
	spec.attacherNode = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder#attacherNode"));
	spec.skyline = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder#skyline"));
	spec.craneHook = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder#craneHook"));
	spec.boom = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder#boom"));
	spec.grab = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#grab"));
	spec.grabJoint = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#grabJoint"));
	spec.claw2 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#claw2"));
	spec.claw1 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#claw1"));
	spec.claw2Joint = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#claw2Joint"));
	spec.claw2GroundRef = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#claw2GroundRef"));
	spec.claw1GroundRef = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#claw1GroundRef"));
	spec.claw2JointGroundRef = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.claws#claw2JointGroundRef"));
	spec.rope = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.ropes#rope"));
	spec.rope2 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.ropes#rope2"));
	spec.rope3 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.ropes#rope3"));
	spec.rope4 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.ropes#rope4"));
	spec.rope5 = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.ropes#rope5"));
	spec.rope2RefPoint = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder.ropes#rope2RefPoint"));
	spec.entranceOrig = self.spec_enterable.enterReferenceNode 
	spec.entranceGrapple = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder#entranceGrapple"));
	spec.exitOrig = self.spec_enterable.exitPoint 
	spec.exitGrapple = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, "vehicle.skylineYarder#exitGrapple"));
	
	spec.yarderActive = false
	spec.yarderId = #SkylineYarder.yarders + 1
	if self.selectionObject.vehicle.isVehicleSaved then
		SkylineYarder.yarders[spec.yarderId] = self
		SkylineYarder.updateNumOfYarders()
	end
	spec.massRoot = 0
	spec.massRootOrig = getMass(self.rootNode)
	spec.massGrabOrig = getMass(spec.grab)
	spec.suspTravelOrig = self.spec_wheels.wheels[1].suspTravel
	spec.springOrig = self.spec_wheels.wheels[1].spring
	spec.massWheelOrig = self.spec_wheels.wheels[1].mass
	spec.brakeForceOrig = self.spec_motorized.motor.brakeForce
	spec.massRootActive = 400
	spec.massGrabActive = 4
	spec.suspTravelActive = 0.326
	spec.springActive = 30000 * 10
	spec.massWheelActive = 300
	spec.brakeForceActive = 300 * 2
	spec.addMass = 0
	spec.addSuspTravel = 0
	spec.addSpring = 0
	spec.distanceTemp = 0
	self.spec_cylindered.movingTools[3].transMinOrig = self.spec_cylindered.movingTools[3].transMin
	self.spec_cylindered.movingTools[5].transSpeedOrig = self.spec_cylindered.movingTools[5].transSpeed
	self.spec_cylindered.movingTools[5].transMaxOrig = self.spec_cylindered.movingTools[5].transMax
	self.spec_cylindered.movingTools[5].transMax = self.spec_cylindered.movingTools[5].transMin
	spec.fastOn = false
	spec.isMoving = false
	spec.rootNode = self.rootNode
	spec.timerPhysics = 0
	spec.timerDirty = 0
	spec.timerDircection = 0
	spec.timerAdvance = 0
	spec.timerHud = 0
	spec.firstRun = true
	spec.skylineOrigRot = {getRotation(spec.skyline)}
	spec.secExit = false
	for k,v in pairs(self.spec_wheels.wheels) do
		self.spec_wheels.wheels[k].rotMaxOrig = self.spec_wheels.wheels[k].rotMax
		self.spec_wheels.wheels[k].rotMinOrig = self.spec_wheels.wheels[k].rotMin
	end
	SkylineYarder.showHelp = true
	SkylineYarder.maxRange = Utils.getNoNil(getXMLFloat(xmlFile, "vehicle.yarder#maxRange"), 500)
	SkylineYarder.ropeHeight = 0
	SkylineYarder.ropeHeightMax = 9
	SkylineYarder.showRope = false
	SkylineYarder.displayMode = 1
	if SkylineYarder.selectedYarderId == nil then
		SkylineYarder.selectedYarderId = spec.yarderId
	end
	
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key = savegame.key.."."..modName..".SkylineYarder"
		local yarderActive = Utils.getNoNil(getXMLBool(xmlFile, key.."#yarderActive"), spec.yarderActive);
		if yarderActive then
			self:toggleYarder(yarderActive, spec.fastOn, true)
		end
		local tX = getXMLFloat(xmlFile, key.."#tX")
		local tY = getXMLFloat(xmlFile, key.."#tY")
		local tZ = getXMLFloat(xmlFile, key.."#tZ")
		local rX = getXMLFloat(xmlFile, key.."#rX")
		local rY = getXMLFloat(xmlFile, key.."#rY")
		local rZ = getXMLFloat(xmlFile, key.."#rZ")
		local ropeHeight = getXMLInt(xmlFile, key.."#ropeHeight")
		spec.dirX = getXMLFloat(xmlFile, key.."#dirX")
		spec.dirY = getXMLFloat(xmlFile, key.."#dirY")
		spec.dirZ = getXMLFloat(xmlFile, key.."#dirZ")
		if tX ~= nil and spec.dirX ~= nil then
			setDirection(spec.skyline, spec.dirX, spec.dirY, spec.dirZ, 0,1,0)
			self:findTreeForYarder(tX, tY, tZ, rX, rY, rZ, ropeHeight, false, true);
		end
	end
	
	if self.isClient and g_dedicatedServerInfo == nil then
		local configFile = SkylineYarder.confDir .. "SkylineYarderConfig.xml";
		if fileExists(configFile) then
			self:loadFromXmlYarder();
		else
			createFolder(getUserProfileAppPath().. "modsSettings/");
			createFolder(SkylineYarder.confDir);
			SkylineYarder.configXml = createXMLFile("SkylineYarder_XML", configFile, "SkylineYarderConfig");
			self:saveToXmlYarder();
			saveXMLFile(SkylineYarder.configXml);
		end
	end
end

function SkylineYarder:saveToXMLFile(xmlFile, key)
	local spec = self.spec_skylineYarder
	
	setXMLBool(xmlFile, key.."#yarderActive", spec.yarderActive)
	
	if spec.attachedSplit ~= nil then
		setXMLFloat(xmlFile, key.."#tX", spec.tX)
		setXMLFloat(xmlFile, key.."#tY", spec.tY)
		setXMLFloat(xmlFile, key.."#tZ", spec.tZ)
		setXMLFloat(xmlFile, key.."#rX", spec.rX)
		setXMLFloat(xmlFile, key.."#rY", spec.rY)
		setXMLFloat(xmlFile, key.."#rZ", spec.rZ)
		setXMLFloat(xmlFile, key.."#dirX", spec.dirX)
		setXMLFloat(xmlFile, key.."#dirY", spec.dirY)
		setXMLFloat(xmlFile, key.."#dirZ", spec.dirZ)
		setXMLInt(xmlFile, key.."#ropeHeight", spec.ropeHeight)
	end
end

function SkylineYarder:onPreDelete()
	local spec = self.spec_skylineYarder
	
	if self.selectionObject.vehicle.isVehicleSaved then
		SkylineYarder.detachYarderRope(self)
		SkylineYarder.yarders[spec.yarderId] = nil
		SkylineYarder.updateNumOfYarders()
		
		if SkylineYarder.selectedYarderId == spec.yarderId then
			for k,v in pairs(SkylineYarder.yarders) do
				if v ~= nil then
					SkylineYarder.selectedYarderId = k
					break
				end
			end
		end
	end
end

function SkylineYarder:loadFromXmlYarder()
	local spec = self.spec_skylineYarder
	
	local configFile = SkylineYarder.confDir .. "SkylineYarderConfig.xml";
    if self.isClient and g_dedicatedServerInfo == nil and fileExists(configFile) then
		SkylineYarder.configXml = loadXMLFile("SkylineYarder_XML", configFile);
		if getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.maxRange") ~= nil then
			SkylineYarder.maxRange = getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.maxRange")
		end
		if getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.ropeHeight") ~= nil then
			SkylineYarder.ropeHeight = getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.ropeHeight")
		end
		if getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.ropeHeightMax") ~= nil then
			SkylineYarder.ropeHeightMax = getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.ropeHeightMax")
		end
		if getXMLBool(SkylineYarder.configXml, "SkylineYarderConfig.showRope") ~= nil then
			SkylineYarder.showRope = getXMLBool(SkylineYarder.configXml, "SkylineYarderConfig.showRope")
		end
		if getXMLInt(SkylineYarder.configXml, "SkylineYarderConfig.displayMode") ~= nil then
			SkylineYarder.displayMode = getXMLInt(SkylineYarder.configXml, "SkylineYarderConfig.displayMode")
		end
		if getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.yarderOverlayPosX") ~= nil then
			SkylineYarder.yarderOverlayPosX = getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.yarderOverlayPosX")
		end
		if getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.yarderOverlayPosY") ~= nil then
			SkylineYarder.yarderOverlayPosY = getXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.yarderOverlayPosY")
		end
	end
end

function SkylineYarder:saveToXmlYarder()
	local spec = self.spec_skylineYarder
    if self.isClient and SkylineYarder.configXml ~= nil and g_dedicatedServerInfo == nil then
		setXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.maxRange", SkylineYarder.maxRange);
		setXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.ropeHeight", SkylineYarder.ropeHeight);
		setXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.ropeHeightMax", SkylineYarder.ropeHeightMax);
		setXMLBool(SkylineYarder.configXml, "SkylineYarderConfig.showRope", SkylineYarder.showRope);
		setXMLInt(SkylineYarder.configXml, "SkylineYarderConfig.displayMode", SkylineYarder.displayMode);
		setXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.yarderOverlayPosX", SkylineYarder.yarderOverlayPosX);
		setXMLFloat(SkylineYarder.configXml, "SkylineYarderConfig.yarderOverlayPosY", SkylineYarder.yarderOverlayPosY);
		saveXMLFile(SkylineYarder.configXml);
	end
end

function SkylineYarder:updateNumOfYarders()
	SkylineYarder.numOfYarders = 0
	for k,v in pairs(SkylineYarder.yarders) do
		if v ~= nil then
			SkylineYarder.numOfYarders = SkylineYarder.numOfYarders + 1
		end
	end
end

function SkylineYarder:switchToNextYarder()
	local currentFound = false
	local firstKey = nil
	local newKey = nil
	
	local anyYarderActive = false
	local activeYardersCount = 0
	for k,v in pairs(SkylineYarder.yarders) do
		if v.spec_skylineYarder.yarderActive then
			anyYarderActive = true
			activeYardersCount = activeYardersCount + 1
		end
	end
	if activeYardersCount == 1 and SkylineYarder.yarders[SkylineYarder.selectedYarderId].spec_skylineYarder.yarderActive then
		newKey = SkylineYarder.selectedYarderId
	elseif activeYardersCount == 0 then
		newKey = 1
	else
		for k,v in pairs(SkylineYarder.yarders) do
			if firstKey == nil then
				firstKey = k
			end
			if currentFound and v.spec_skylineYarder.yarderActive then
				newKey = k
				break
			end
			if k == SkylineYarder.selectedYarderId then
				currentFound = true
			end
		end
		if newKey == nil then
			newKey = firstKey
		end
	end
	SkylineYarder.selectedYarderId = newKey
	SkylineYarder.yarders[newKey]:raiseActive()
end

function SkylineYarder:toggleYarder(state, fastOn, noEventSend)
    local spec = self.spec_skylineYarder
	local distance = math.abs(self.spec_cylindered.movingTools[5].curTrans[3] - (self.spec_cylindered.movingTools[5].transMin - 0.00001))
	
	SkylineYarderToggleEvent.sendEvent(self, state, fastOn, noEventSend)
	
	if fastOn ~= spec.fastOn then
		spec.fastOn = fastOn
		if fastOn then
			self.spec_cylindered.movingTools[5].transSpeed = self.spec_cylindered.movingTools[5].transSpeedOrig * 3
		else
			self.spec_cylindered.movingTools[5].transSpeed = self.spec_cylindered.movingTools[5].transSpeedOrig
		end
	end
	if state ~= spec.yarderActive then
		spec.yarderActive = state
		if state == true then
			if not SkylineYarder.yarders[SkylineYarder.selectedYarderId].spec_skylineYarder.yarderActive then
				SkylineYarder.selectedYarderId = spec.yarderId
			end
			self:raiseActive()
			if self:getIsControlled() then
				SkylineYarder.selectedYarderId = spec.yarderId
			end
			self:syUpdateValues(distance, true)
		elseif state == false then
			if SkylineYarder.selectedYarderId == spec.yarderId then
				SkylineYarder.switchToNextYarder()
			end
			spec.addMass = 0
			spec.addSuspTravel = 0
			spec.addSpring = 0
			self:syUpdateValues(distance, true)
		end
    end
end

function SkylineYarder:onEnterVehicle()
	local spec = self.spec_skylineYarder
	
	if spec.yarderActive then
		SkylineYarder.selectedYarderId = spec.yarderId
	end
	self:loadFromXmlYarder();
end

function SkylineYarder:getIsTurnedOn()
	local spec = self.spec_skylineYarder
	
    return spec.yarderActive
end

function SkylineYarder:createPlayerShape(centerNode)
	local spec = self.spec_skylineYarder
	
    local planePoint = createTransformGroup("planePoint");
    link(centerNode, planePoint);
    setRotation(planePoint, math.rad(225), math.rad(0), math.rad(90));
    setTranslation(planePoint, 0, 0, 0.7);
    local dir1 = createTransformGroup("dir1");
    local dir2 = createTransformGroup("dir2");
    link(planePoint, dir1);
    link(planePoint, dir2);
    setTranslation(dir1, 1, 0, 0);
    setTranslation(dir2, 0, 1, 0);
    return planePoint, dir1, dir2;
end

function SkylineYarder:findTreeForYarder(tX, tY, tZ, rX, rY, rZ, ropeHeight, isLocal, noEventSend)
	local spec = self.spec_skylineYarder
	
    spec.syUpdated = true;
    if not isLocal then
        local center = createTransformGroup("local_center");
        link(getRootNode(), center);
        setTranslation(center, tX, tY, tZ);
        setRotation(center, rX, rY, rZ);
        local planePoint, dir1, dir2 = self:createPlayerShape(center);
        local pX, pY, pZ = getWorldTranslation(planePoint);
        local dir1X, dir1Y, dir1Z = getWorldTranslation(dir1);
        local dir2X, dir2Y, dir2Z = getWorldTranslation(dir2);
        local nx, ny, nz, yx, yy, yz = dir1X-pX, dir1Y-pY, dir1Z-pZ, dir2X-pX, dir2Y-pY, dir2Z-pZ;    
        local shape, minY, maxY, minZ, maxZ = findSplitShape(pX,pY,pZ, nx, ny, nz, yx, yy, yz, 20, 20);    
        if shape == nil or shape == 0 then
            print("ERROR: skylineYarder.lua - No shape found at given position!");
        else
            spec.foundLocalSplit = shape;
            self:attachYarderRope(tX, tY, tZ, rX, rY, rZ, ropeHeight);
        end;
        delete(center);
    else 
        self:attachYarderRope(tX, tY, tZ, rX, rY, rZ, ropeHeight);
        SkylineYarderAttachTreeEvent.sendEvent(self, tX, tY, tZ, rX, rY, rZ, ropeHeight, noEventSend);
    end;
	spec.tX = tX
	spec.tY = tY
	spec.tZ = tZ
	spec.rX = rX
	spec.rY = rY
	spec.rZ = rZ
	spec.ropeHeight = ropeHeight
end

function SkylineYarder:attachYarderRope(tX, tY, tZ, rX, rY, rZ, ropeHeight)
	local spec = self.spec_skylineYarder
    
    local split = Utils.getNoNil(spec.foundLocalSplit, spec.currentLocalSplit);
    spec.localSplitAttacherRef = createTransformGroup("attacherReference");
    link(split, spec.localSplitAttacherRef);        
    local lx, ly, lz = worldToLocal(spec.localSplitAttacherRef, tX, tY + ropeHeight, tZ);
    setTranslation(spec.localSplitAttacherRef, lx, ly, lz);
    spec.attachedSplit = split;
	self.spec_cylindered.movingTools[5].transMax = self.spec_cylindered.movingTools[5].transMaxOrig
	Cylindered.setDirty(self, self.spec_cylindered.movingTools[6])
	spec.parent = getParent(split)
	spec.splitX, spec.splitY, spec.splitZ = getWorldTranslation(spec.localSplitAttacherRef)
end

function SkylineYarder:detachYarderRope(noEventSend)
	local spec = self.spec_skylineYarder

    spec.attachedSplit = nil;
    spec.localSplitAttacherRef = nil;
    spec.foundLocalSplit = nil;
    spec.syUpdated = true;
	self.spec_cylindered.movingTools[5].transMax = self.spec_cylindered.movingTools[5].transMin
	setRotation(spec.skyline, unpack(spec.skylineOrigRot))
	Cylindered.setDirty(self, self.spec_cylindered.movingTools[6]);
    SkylineYarderDetachTreeEvent.sendEvent(self, noEventSend);
end

function SkylineYarder:onUpdate(dt, vehicle)
	local spec = self.spec_skylineYarder
	
	if spec.attachedSplit ~= nil and not entityExists(spec.attachedSplit) then
		local tree = createTransformGroup("tree")
		local x,y,z = worldToLocal(tree, spec.splitX, spec.splitY, spec.splitZ);
		setTranslation(tree, x,y,z)
		spec.localSplitAttacherRef = tree
		spec.attachedSplit = tree
	end
	
	local treeInRange = false
	local yarderIsSelected = (SkylineYarder.selectedYarderId == spec.yarderId)
	local distance = math.abs(self.spec_cylindered.movingTools[5].curTrans[3] - (self.spec_cylindered.movingTools[5].transMin - 0.00001))
	if self:getIsActive() then
		if self.spec_cylindered.movingTools[5].move ~= 0 and spec.attachedSplit == nil then
			g_currentMission:showBlinkingWarning("Attach rope to tree to use this movingTool!", 2000);
		end
	end
	if spec.yarderActive then
		local massRoot
		if spec.massRoot ~= 0 then massRoot = spec.massRoot else massRoot = spec.massRootActive end
		if math.floor(massRoot) ~= math.floor(getMass(spec.rootNode)) then
			setMass(spec.rootNode, massRoot)
		end
		self:raiseActive()
		if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
			local x,y,z = getWorldTranslation(g_currentMission.player.rootNode);
			local a,b,c = getWorldTranslation(self.rootNode)
			local distance = MathUtil.vector3Length(x-a, y-b, z-c);
			if distance < 1500 then
				g_currentMission:addExtraPrintText("Distance to yarder "..spec.yarderId..": "..string.format("%.1f",distance) .. " m "..(spec.attachedSplit and "(Rope attached" or "(Rope not attached")..(yarderIsSelected and ", Selected)" or ")"))
				if spec.firstTimeActive == nil then
					spec.searchNodes = {};
					spec.searchNodes.center = createTransformGroup("centerNode");
					link(g_currentMission.player.lightNode, spec.searchNodes.center);
					setTranslation(spec.searchNodes.center, 0, 0, -1);
					local planePoint, dir1, dir2 = self:createPlayerShape(spec.searchNodes.center);
					spec.searchNodes.planePoint = planePoint;
					spec.searchNodes.dir1 = dir1;
					spec.searchNodes.dir2 = dir2;
					spec.firstTimeActive = true;
				end
				local pX, pY, pZ = getWorldTranslation(spec.searchNodes.planePoint);
				local dir1X, dir1Y, dir1Z = getWorldTranslation(spec.searchNodes.dir1);
				local dir2X, dir2Y, dir2Z = getWorldTranslation(spec.searchNodes.dir2);
				local nx, ny, nz, yx, yy, yz = dir1X-pX, dir1Y-pY, dir1Z-pZ, dir2X-pX, dir2Y-pY, dir2Z-pZ;
				local shape, minY, maxY, minZ, maxZ = findSplitShape(pX,pY,pZ, nx, ny, nz, yx, yy, yz, 1, 1);
				if shape ~= nil and shape ~= 0 then
					spec.currentLocalSplit = shape;
					if spec.attachedSplit == nil then
						treeInRange = true
						if spec.syUpdated == nil and SkylineYarder.inputAttach and yarderIsSelected then
							SkylineYarder.inputAttach = false
							if distance <= SkylineYarder.maxRange then
								local tX, tY, tZ = getWorldTranslation(spec.searchNodes.center);
								local rX, rY, rZ = getWorldRotation(spec.searchNodes.center);
								self:findTreeForYarder(tX, tY, tZ, rX, rY, rZ, SkylineYarder.ropeHeight, true, nil);
							else
								g_currentMission:showBlinkingWarning("Selected yarder is out of range (max. "..SkylineYarder.maxRange.."m)!", 2000);
							end
						end;
					end;
				else    
					spec.currentLocalSplit = nil;
				end;
				if spec.attachedSplit ~= nil then
					if SkylineYarder.playerInRange(self, spec.localSplitAttacherRef, 5) then
						treeInRange = true
						if spec.syUpdated == nil and SkylineYarder.inputAttach and yarderIsSelected then
							SkylineYarder.inputAttach = false
							if self.spec_cylindered.movingTools[5].curTrans[3] == self.spec_cylindered.movingTools[5].transMin then
								self:detachYarderRope();
							else
								g_currentMission:showBlinkingWarning("Move your grapple to start position first!", 2000);
							end
						end;
					end;
				elseif spec.attachedSplit == nil then
					if yarderIsSelected and SkylineYarder.showRope then
						local x, y, z = getWorldTranslation(spec.searchNodes.center);
						local a, b, c = getWorldTranslation(spec.rope);
						local dirX, dirY, dirZ = worldDirectionToLocal(getParent(spec.attacherNode), x-a, y-b, z-c);
						local upx, upy, upz = 0,1,0;
						setDirection(spec.rope, dirX, dirY, dirZ, upx, upy, upz);
						local distance = MathUtil.vector3Length(x-a, y-b, z-c);
						setScale(spec.rope, 1, 1, distance);
						setVisibility(spec.rope, true);
						local x,_,z,w = getShaderParameter(getChildAt(spec.rope,0), "uvScale")
						setShaderParameter(getChildAt(spec.rope,0), "uvScale", x, distance, z, w, false)
					else
						setVisibility(spec.rope, false);
					end
				end;
			end;
		end
		
        if spec.attachedSplit ~= nil then
            local x, y, z = getWorldTranslation(spec.localSplitAttacherRef);
            local a, b, c = getWorldTranslation(spec.rope);
            local dirX, dirY, dirZ = worldDirectionToLocal(getParent(spec.attacherNode), x-a, y-b, z-c);
            local a, b, c = getWorldTranslation(spec.skyline);
            local upx, upy, upz = 0,1,0;
            setDirection(spec.rope, dirX, dirY, dirZ, upx, upy, upz);
			local dirX, dirY, dirZ = worldDirectionToLocal(getParent(spec.skyline), x-a, y-b, z-c);
			spec.dirX, spec.dirY, spec.dirZ = dirX, dirY, dirZ
			if spec.dirXTemp == nil then spec.dirXTemp,spec.dirYTemp,spec.dirZTemp = 0,0,0 end
			spec.timerDircection = spec.timerDircection + dt
			local t1 = distance > 200 and distance * 0 or (distance > 150 and distance * 0 or (distance > 100 and distance * 0 or (distance > 50 and distance * 0 or distance * 0)))
			if ((spec.firstRun == true and spec.timerDircection > t1) or (spec.firstRun == false and spec.timerDircection > 1)) then
				spec.firstRun = false
				spec.timerDircection = 0
				setDirection(spec.skyline, dirX, dirY, dirZ, upx, upy, upz);
			end
			local xY, yY, zY = getWorldTranslation(spec.attacherNode);
			local distance = MathUtil.vector3Length(xY-x, yY-y, zY-z);
			self.spec_cylindered.movingTools[5].transMax = distance - 3
			setScale(spec.rope, 1, 1, distance);
			setVisibility(spec.rope, true);
			local x,_,z,w = getShaderParameter(getChildAt(spec.rope,0), "uvScale")
			setShaderParameter(getChildAt(spec.rope,0), "uvScale", x, distance, z, w, false)
			local x,y,z = getWorldTranslation(spec.rope2);
			local a,b,c = getWorldTranslation(spec.rope2RefPoint);
			local distance = MathUtil.vector3Length(a-x, b-y, c-z);
			local x,_,z,w = getShaderParameter(spec.rope2, "uvScale")
			setShaderParameter(spec.rope2, "uvScale", x, distance*2, z, w, false)
			local x,_,z,w = getShaderParameter(spec.rope3, "uvScale")
			x,_,z,w = getShaderParameter(spec.rope3, "offsetUV")
			local offset = distance / 7
			setShaderParameter(spec.rope3, "offsetUV", x, (offset) % 1, z, w, false)
			x,_,z,w = getShaderParameter(spec.rope4, "offsetUV")
			offset = distance / 10
			setShaderParameter(spec.rope4, "offsetUV", 0, (-offset) % 1, z, w, false)
		end
		local t3 = 100
		if spec.syUpdated then
			spec.timerDirty = spec.timerDirty + dt
			if spec.timerDirty < t3 then
				Cylindered.setDirty(self, self.spec_cylindered.movingTools[6]);
			else
				spec.timerDirty = 0
				spec.syUpdated = nil;
			end
		end
	end
	
	local x, y, z = getWorldTranslation(spec.craneHook);
	local a, b, c = getWorldTranslation(spec.grabJoint);
	local distanceRope5 = MathUtil.vector3Length(a-x, b-y, c-z);
	local x,_,z,w = getShaderParameter(spec.rope5, "uvScale")
	setShaderParameter(spec.rope5, "uvScale", x, distanceRope5 * 1.9, z, w, false)
	
	if not g_currentMission.controlPlayer and spec.attachedSplit == nil then
		local x, y, z = getWorldTranslation(getChildAt(spec.craneHook,13));
		local a, b, c = getWorldTranslation(spec.rope);
		local dirX, dirY, dirZ = worldDirectionToLocal(getParent(spec.attacherNode), x-a, y-b, z-c);
		local upx, upy, upz = 0,1,0;
		local distance = MathUtil.vector3Length(a-x, b-y, c-z);
		setDirection(spec.rope, dirX, dirY, dirZ, upx, upy, upz);
		setScale(spec.rope, 1, 1, distance);
		setVisibility(spec.rope, true);
	end
	
	if self.movingDirection ~= 0 then
		Cylindered.setDirty(self, self.spec_cylindered.movingTools[6]);
	end
	
	self:syUpdateValues(distance, false, dt)
	
	local x,y,z = getWorldTranslation(spec.claw2GroundRef);
	local a,b,c = getWorldTranslation(spec.claw1GroundRef);
	local terrainY2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x,y,z);
	local terrainY1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, a,b,c);
	local grappleHeight2 = y - terrainY2 - 0.3
	local grappleHeight1 = b - terrainY1- 0.3
	if math.min(grappleHeight2, grappleHeight1) < 0.1 then
		self.spec_cylindered.movingTools[3].transMin = self.spec_cylindered.movingTools[3].curTrans[2]
	else
		self.spec_cylindered.movingTools[3].transMin = self.spec_cylindered.movingTools[3].transMinOrig
	end
	
	if self.isClient then
		if self:getIsActive() then
			if spec.event_IDs ~= nil and g_dedicatedServerInfo == nil then
				if spec.yarderActive then
					g_inputBinding:setActionEventText(spec.event_IDs['SKYLINEYARDER_ACTIVATE'], g_i18n:getText('SKYLINEYARDER_DEACTIVATE'))
				else
					g_inputBinding:setActionEventText(spec.event_IDs['SKYLINEYARDER_ACTIVATE'], g_i18n:getText('SKYLINEYARDER_ACTIVATE'))
				end
				for actionName,eventID in pairs(spec.event_IDs) do
					if actionName ~= InputAction.SKYLINEYARDER_ACTIVATE then
						if actionName == InputAction.SKYLINEYARDER_MOVE_HUD_LEFT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_RIGHT or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_UP or actionName == InputAction.SKYLINEYARDER_MOVE_HUD_DOWN then
							g_inputBinding:setActionEventActive(eventID, spec.yarderActive and (SkylineYarder.displayMode == 1 or SkylineYarder.displayMode == 3))
						else
							g_inputBinding:setActionEventActive(eventID, spec.yarderActive)
						end
					end
				end
				g_inputBinding:setActionEventText(spec.event_IDs['SKYLINEYARDER_TOGGLE_SPEED'], g_i18n:getText('input_SKYLINEYARDER_TOGGLE_SPEED')..' : '..(spec.fastOn and 'fast' or 'normal'))
				g_inputBinding:setActionEventText(spec.event_IDs['SKYLINEYARDER_TOGGLE_DISPLAY'], g_i18n:getText('input_SKYLINEYARDER_TOGGLE_DISPLAY')..' : '..(SkylineYarder.displayMode))
				g_inputBinding:setActionEventText(spec.event_IDs['SKYLINEYARDER_TOGGLE_EXIT'], spec.secExit and g_i18n:getText('SKYLINEYARDER_EXIT_VEHICLE') or g_i18n:getText('SKYLINEYARDER_EXIT_GRAPPLE'))
			end
		end
		if SkylineYarder.event_IDsPlayer ~= nil then
			local anyYarderActive = false
			for k,v in pairs(SkylineYarder.yarders) do
				if v.spec_skylineYarder.yarderActive then
					anyYarderActive = true
				end
			end
			g_inputBinding:setActionEventActive(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_SWITCH'], anyYarderActive)
			if yarderIsSelected and spec.yarderActive then
				g_inputBinding:setActionEventActive(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_ATTACH'], treeInRange)
				g_inputBinding:setActionEventActive(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_TOGGLE_ROPEHEIGHT'], treeInRange and spec.attachedSplit == nil and true or false)
				g_inputBinding:setActionEventActive(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_TOGGLE_SHOWROPE'], spec.attachedSplit == nil and true or false)
				
				g_inputBinding:setActionEventText(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_TOGGLE_ROPEHEIGHT'], g_i18n:getText('input_SKYLINEYARDER_TOGGLE_ROPEHEIGHT')..' : '..(SkylineYarder.ropeHeight+1)..' m')
				if spec.attachedSplit ~= nil then
					g_inputBinding:setActionEventText(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_ATTACH'], g_i18n:getText('SKYLINEYARDER_DETACH_ROPE'))
				else
					g_inputBinding:setActionEventText(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_ATTACH'], g_i18n:getText('SKYLINEYARDER_ATTACH_ROPE'))
				end
				if SkylineYarder.showRope then
					g_inputBinding:setActionEventText(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_TOGGLE_SHOWROPE'], g_i18n:getText('SKYLINEYARDER_HIDE_ROPE'))
				else
					g_inputBinding:setActionEventText(SkylineYarder.event_IDsPlayer['SKYLINEYARDER_TOGGLE_SHOWROPE'], g_i18n:getText('SKYLINEYARDER_SHOW_ROPE'))
				end	
			end
		end
		if spec.inputLeft or spec.inputRight or spec.inputUp or spec.inputDown then
			spec.timerHud = spec.timerHud + dt
			if spec.inputLeft then
				if spec.timerHud > 1500 then
					SkylineYarder.yarderOverlayPosX = SkylineYarder.yarderOverlayPosX - 0.001
				else
					SkylineYarder.yarderOverlayPosX = SkylineYarder.yarderOverlayPosX - 0.0001
				end
			end
			if spec.inputRight then
				if spec.timerHud > 1500 then
					SkylineYarder.yarderOverlayPosX = SkylineYarder.yarderOverlayPosX + 0.001
				else
					SkylineYarder.yarderOverlayPosX = SkylineYarder.yarderOverlayPosX + 0.0001
				end
			end
			if spec.inputUp then
				if spec.timerHud > 1500 then
					SkylineYarder.yarderOverlayPosY = SkylineYarder.yarderOverlayPosY + 0.001
				else
					SkylineYarder.yarderOverlayPosY = SkylineYarder.yarderOverlayPosY + 0.0001
				end
			end
			if spec.inputDown then
				if spec.timerHud > 1500 then
					SkylineYarder.yarderOverlayPosY = SkylineYarder.yarderOverlayPosY - 0.001
				else
					SkylineYarder.yarderOverlayPosY = SkylineYarder.yarderOverlayPosY - 0.0001
				end
			end
		else
			spec.timerHud = 0
		end
	end
end

function SkylineYarder:onDraw()
	local spec = self.spec_skylineYarder
	
	if self.isClient and self:getIsControlled() and spec.yarderActive then
		local x,y,z = getWorldTranslation(spec.claw2JointGroundRef)
		local a,b,c = getWorldTranslation(spec.claw2GroundRef)
		local clawDiff = MathUtil.vector3Length(a-x, b-y, c-z);
		local x2,y2,z2 = getRotation(spec.claw2Joint);
		local closed
		local power = ""
		if math.deg(z2) >= 0 then
			closed = 69 - math.deg(z2)
		else
			closed = 69 + math.deg(math.abs(z2))
		end
		closed = (closed * 100) / math.deg((math.abs(self.spec_cylindered.movingTools[7].rotMin) + math.abs(self.spec_cylindered.movingTools[7].rotMax)))
		power = (clawDiff > (0.4) and (clawDiff > (0.7) and 'red' or 'orange') or 'green')
		spec.yarderInfo3 = '  '..string.format("%.0f",closed)..' %'
		if spec.attachedSplit ~= nil then
			local distance = math.abs(self.spec_cylindered.movingTools[5].curTrans[3] - (self.spec_cylindered.movingTools[5].transMin - 0.00001))
			local x, y, z = getWorldTranslation(spec.localSplitAttacherRef);
			local a, b, c = getWorldTranslation(spec.craneHook);
			local grappleToTreeDistance = MathUtil.vector3Length(a-x, b-y, c-z);
			local a, b, c = getWorldTranslation(spec.skyline)
			local l,m,n = getWorldTranslation(spec.boom)
			local sideA = MathUtil.vector2Length(a-x, c-z)
			local sideB = MathUtil.vector2Length(a-l, c-n)
			local sideC = MathUtil.vector2Length(l-x, n-z)
			local angle = math.deg(math.acos(((sideB*sideB) + (sideC*sideC) - (sideA*sideA)) / (2*sideB*sideC)))
			local x,y,z = getWorldTranslation(spec.claw2GroundRef);
			local a,b,c = getWorldTranslation(spec.claw1GroundRef);
			local terrainY2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x,y,z);
			local terrainY1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, a,b,c);
			local grappleHeight2 = y - terrainY2 - 0.3
			local grappleHeight1 = b - terrainY1- 0.3
			if SkylineYarder.displayMode == 1 or SkylineYarder.displayMode == 4 then
				spec.yarderInfo1 = spec.yarderInfo1 .. 'Claws closed\n'
				spec.yarderInfo1 = spec.yarderInfo1 .. 'Grapple to tree distance\n'
				spec.yarderInfo1 = spec.yarderInfo1 .. 'Grapple height\n'
				spec.yarderInfo1 = spec.yarderInfo1 .. 'Yarder to grapple distance\n'
				spec.yarderInfo1 = spec.yarderInfo1 .. 'Yarder to tree angle\n'
				spec.yarderInfo2 = spec.yarderInfo2 .. ':\n'
				spec.yarderInfo2 = spec.yarderInfo2 .. ': '..(grappleToTreeDistance ~= nil and string.format("%.1f",grappleToTreeDistance) or '---')..'\n'
				spec.yarderInfo2 = spec.yarderInfo2 .. ': '..string.format("%.1f",math.min(grappleHeight2, grappleHeight1))..'\n'
				spec.yarderInfo2 = spec.yarderInfo2 .. ': '..string.format("%.1f",distance)..'\n'
				spec.yarderInfo2 = spec.yarderInfo2 .. ': '..string.format("%.1f",angle)..' °\n'
			end
			if SkylineYarder.displayMode == 2 or SkylineYarder.displayMode == 4 then
				g_currentMission:addExtraPrintText("Grapple to tree distance : "..string.format("%.1f",grappleToTreeDistance).." m")
				g_currentMission:addExtraPrintText("Grapple height : "..string.format("%.1f",math.min(grappleHeight2, grappleHeight1)).." m")
				g_currentMission:addExtraPrintText("Yarder to grapple distance : "..string.format("%.1f",distance).." m")
				g_currentMission:addExtraPrintText("Yarder to tree angle : "..string.format("%.1f",angle).." °")
			end
		else
			if SkylineYarder.displayMode == 1 or SkylineYarder.displayMode == 4 then
				spec.yarderInfo1 = spec.yarderInfo1 .. 'Claws closed\n'
				spec.yarderInfo1 = spec.yarderInfo1 .. '\n      Attach yarder to some tree\n'
				spec.yarderInfo1 = spec.yarderInfo1 .. '              to show this HUD\n'
			end
		end
		if SkylineYarder.displayMode == 1 or SkylineYarder.displayMode == 4 then
			renderOverlay(spec.yarderOverlay, SkylineYarder.yarderOverlayPosX, SkylineYarder.yarderOverlayPosY, spec.yarderOverlayWidth, spec.yarderOverlayHeight)
			setTextBold(false);
			setTextAlignment(RenderText.ALIGN_LEFT);
			if power == 'red' then
				setTextColor(1, 0, 0, 1)
			elseif power == 'orange' then
				setTextColor(1, 0.8, 0, 1)
		    else
				setTextColor(0, 1, 0, 1)
			end
			renderText(SkylineYarder.yarderOverlayPosX+0.127, SkylineYarder.yarderOverlayPosY+0.083, 0.017*spec.ui, spec.yarderInfo3);
			setTextColor(1,1,1,1);
			setTextBold(false);
			renderText(SkylineYarder.yarderOverlayPosX+0.004, SkylineYarder.yarderOverlayPosY+0.083, 0.017*spec.ui, spec.yarderInfo1);
			renderText(SkylineYarder.yarderOverlayPosX+0.127, SkylineYarder.yarderOverlayPosY+0.083, 0.017*spec.ui, spec.yarderInfo2);
		end
		spec.yarderInfo1 = "";
		spec.yarderInfo2 = "";
		spec.yarderInfo3 = "";
	end
end

function SkylineYarder:syUpdateValues(distance, forced, dt)
	local spec = self.spec_skylineYarder
	
	local spring = 0
	local suspTravel = 0
	if distance < 10 then
		spec.massRoot = (spec.yarderActive and spec.massRootActive or spec.massRootOrig) + (distance * 50) + spec.addMass
		spring = (spec.yarderActive and spec.springActive or spec.springOrig) + (distance * 2000000) + spec.addSpring
		suspTravel = (spec.yarderActive and spec.suspTravelActive or spec.suspTravelOrig) + (distance * 0) + spec.addSuspTravel
	elseif distance < 100 then
		spec.massRoot = (spec.yarderActive and spec.massRootActive or spec.massRootOrig) + (distance * 200) + spec.addMass
		spring = (spec.yarderActive and spec.springActive or spec.springOrig) + (distance * 4500000) + spec.addSpring
		suspTravel = (spec.yarderActive and spec.suspTravelActive or spec.suspTravelOrig) + (distance * 0) + spec.addSuspTravel
	elseif distance < 150 then
		spec.massRoot = (spec.yarderActive and spec.massRootActive or spec.massRootOrig) + (distance * 200) + spec.addMass
		spring = (spec.yarderActive and spec.springActive or spec.springOrig) + (distance * 4500000) + spec.addSpring
		suspTravel = (spec.yarderActive and spec.suspTravelActive or spec.suspTravelOrig) + (distance * 0) + spec.addSuspTravel
	elseif distance < 200 then
		spec.massRoot = (spec.yarderActive and spec.massRootActive or spec.massRootOrig) + (distance * 200) + spec.addMass
		spring = (spec.yarderActive and spec.springActive or spec.springOrig) + (distance * 4500000) + spec.addSpring
		suspTravel = (spec.yarderActive and spec.suspTravelActive or spec.suspTravelOrig) + (distance * 0) + spec.addSuspTravel
	elseif distance < 250 then
		spec.massRoot = (spec.yarderActive and spec.massRootActive or spec.massRootOrig) + (distance * 200) + spec.addMass
		spring = (spec.yarderActive and spec.springActive or spec.springOrig) + (distance * 4500000) + spec.addSpring
		suspTravel = (spec.yarderActive and spec.suspTravelActive or spec.suspTravelOrig) + (distance * 0) + spec.addSuspTravel
	else
		spec.massRoot = (spec.yarderActive and spec.massRootActive or spec.massRootOrig) + (distance * 200) + spec.addMass
		spring = (spec.yarderActive and spec.springActive or spec.springOrig) + (distance * 4500000) + spec.addSpring
		suspTravel = (spec.yarderActive and spec.suspTravelActive or spec.suspTravelOrig) + (distance * 0) + spec.addSuspTravel
	end
	if (distance > 0.001 and distance < 1 and math.floor(distance*1000) ~= math.floor(spec.distanceTemp*1000)) or (distance > 1 and math.floor(distance) ~= math.floor(spec.distanceTemp)) or forced then
		if dt ~= nil then
			spec.timerPhysics = spec.timerPhysics + dt
		end
		if spec.timerPhysics > 50 or forced then
			spec.timerPhysics = 0
			spec.distanceTemp = distance
			self:syUpdatePhysics(spec.massRoot, spring, suspTravel, distance, spec.yarderActive and spec.massGrabActive or spec.massGrabOrig, spec.yarderActive and spec.massWheelActive or spec.massWheelOrig)
		end
	end
end

function SkylineYarder:syUpdatePhysics(massRoot, spring, suspTravel, distance, massGrab, massWheel, noEventSend)
	local spec = self.spec_skylineYarder

	local springSet = 0
	local suspTravelSet = 0
	springSet = spring
	suspTravelSet = suspTravel
	if massGrab ~= nil then
		setMass(spec.grab, massGrab)
		setMass(spec.claw2, massGrab)
		setMass(spec.claw1, massGrab)
	end
	setMass(spec.rootNode, massRoot)
	for k,v in pairs(self.spec_wheels.wheels) do
		self.spec_wheels.wheels[k].spring = springSet
		self.spec_wheels.wheels[k].suspTravel = suspTravelSet
		self.spec_wheels.wheels[k].mass = massWheel
		if distance > 100 then
			self.spec_wheels.wheels[k].rotMax = 0
			self.spec_wheels.wheels[k].rotMin = 0
		else
			self.spec_wheels.wheels[k].rotMax = self.spec_wheels.wheels[k].rotMaxOrig
			self.spec_wheels.wheels[k].rotMin = self.spec_wheels.wheels[k].rotMinOrig
		end
		self:updateWheelBase(self.spec_wheels.wheels[k])
	end
	self.spec_motorized.motor.brakeForce = spec.yarderActive and spec.brakeForceActive or spec.brakeForceOrig
end

function SkylineYarder:playerInRange(target, dist)
	local inRange = false
	local source
	if g_currentMission.controlPlayer and g_currentMission.player ~= nil then
		source = g_currentMission.player.rootNode
	end
	if source ~= nil then
		local x,y,z = getWorldTranslation(target)
		local a,b,c = getWorldTranslation(source)
		local distance = MathUtil.vector2Length(x-a, z-c);
		if distance < dist then
			inRange = true
		end
	end
	return inRange
end
function SkylineYarder:actionCallback(actionName, keyStatus, arg4, arg5, arg6)
	local spec = self.spec_skylineYarder
	
	if keyStatus > 0 then
		if actionName == 'SKYLINEYARDER_ACTIVATE' then
			if spec.attachedSplit == nil then
                self:toggleYarder(not spec.yarderActive, spec.fastOn);
			else
				g_currentMission:showBlinkingWarning("Detach rope from tree first!", 2000);
            end
		elseif actionName == 'SKYLINEYARDER_TOGGLE_SPEED' then
			self:toggleYarder(spec.yarderActive, not spec.fastOn);
		elseif actionName == 'SKYLINEYARDER_TOGGLE_DISPLAY' then
			local mode = {'Yarder HUD', 'F1 menu', 'None'}
			if SkylineYarder.displayMode + 1 <= 3 then
				SkylineYarder.displayMode = SkylineYarder.displayMode + 1
			else
				SkylineYarder.displayMode = 1
			end
			g_currentMission:showBlinkingWarning("Yarder display mode set to : "..SkylineYarder.displayMode.." ("..mode[SkylineYarder.displayMode]..")", 2000);
			SkylineYarder.saveToXmlYarder(self);
		elseif actionName == 'SKYLINEYARDER_TOGGLE_EXIT' then
			spec.secExit = not spec.secExit
			if spec.secExit then
				self.spec_enterable.enterReferenceNode = spec.entranceGrapple
				self.spec_enterable.exitPoint = spec.exitGrapple
			else
				self.spec_enterable.enterReferenceNode = spec.entranceOrig
				self.spec_enterable.exitPoint = spec.exitOrig
			end
		end
	end
	if actionName == 'SKYLINEYARDER_MOVE_HUD_LEFT' then
		spec.inputLeft = keyStatus > 0
		if keyStatus == 0 then self:saveToXmlYarder() end
	elseif actionName == 'SKYLINEYARDER_MOVE_HUD_RIGHT' then
		spec.inputRight = keyStatus > 0
		if keyStatus == 0 then self:saveToXmlYarder() end
	elseif actionName == 'SKYLINEYARDER_MOVE_HUD_UP' then
		spec.inputUp = keyStatus > 0
		if keyStatus == 0 then self:saveToXmlYarder() end
	elseif actionName == 'SKYLINEYARDER_MOVE_HUD_DOWN' then
		spec.inputDown = keyStatus > 0
		if keyStatus == 0 then self:saveToXmlYarder() end
	end
end
function SkylineYarder:actionCallbackPlayer(actionName, keyStatus, arg4, arg5, arg6)
	if keyStatus > 0 then
		if actionName == 'SKYLINEYARDER_ATTACH' then
			SkylineYarder.inputAttach = true
		elseif actionName == 'SKYLINEYARDER_SWITCH' then
			SkylineYarder.switchToNextYarder()
		elseif actionName == 'SKYLINEYARDER_TOGGLE_ROPEHEIGHT' then
			if SkylineYarder.ropeHeight + 1 <= 9 then
				SkylineYarder.ropeHeight = SkylineYarder.ropeHeight + 1
			else
				SkylineYarder.ropeHeight = 0
			end
			SkylineYarder.saveToXmlYarder(self);
		elseif actionName == 'SKYLINEYARDER_TOGGLE_SHOWROPE' then
			SkylineYarder.showRope = not SkylineYarder.showRope
			SkylineYarder.saveToXmlYarder(self);
		end
	end
end
function SkylineYarder:onReadStream(streamId, connection)
	local spec = self.spec_skylineYarder
	
	local yarderActive = streamReadBool(streamId);
	local fastOn = streamReadBool(streamId);
	local treeAttached = streamReadBool(streamId);
	
	if yarderActive == true then
		self:toggleYarder(yarderActive, fastOn, true)
	end
	if treeAttached then
		local tX = streamReadFloat32(streamId);
		local tY = streamReadFloat32(streamId);
		local tZ = streamReadFloat32(streamId);
		local rX = streamReadFloat32(streamId);
		local rY = streamReadFloat32(streamId);
		local rZ = streamReadFloat32(streamId);
		local dirX = streamReadFloat32(streamId);
		local dirY = streamReadFloat32(streamId);
		local dirZ = streamReadFloat32(streamId);
		local ropeHeight = streamReadInt8(streamId);
		if tX ~= nil and tY ~= nil and tZ ~= nil and rX ~= nil and rY ~= nil and rZ ~= nil and dirX ~= nil and dirY ~= nil and dirZ ~= nil and ropeHeight ~= nil  then
			--setDirection(spec.skyline, dirX, dirY, dirZ, 0,1,0)
			self:findTreeForYarder(tX, tY, tZ, rX, rY, rZ, ropeHeight, false, true);
		end
	end
end;
function SkylineYarder:onWriteStream(streamId, connection)
	local spec = self.spec_skylineYarder
	
	streamWriteBool(streamId, spec.yarderActive);
	streamWriteBool(streamId, spec.fastOn);
	if spec.attachedSplit ~= nil then
		streamWriteBool(streamId, true);
		streamWriteFloat32(streamId, spec.tX);
		streamWriteFloat32(streamId, spec.tY);
		streamWriteFloat32(streamId, spec.tZ);
		streamWriteFloat32(streamId, spec.rX);
		streamWriteFloat32(streamId, spec.rY);
		streamWriteFloat32(streamId, spec.rZ);
		streamWriteFloat32(streamId, spec.dirX);
		streamWriteFloat32(streamId, spec.dirY);
		streamWriteFloat32(streamId, spec.dirZ);
		streamWriteInt8(streamId, spec.ropeHeight);
	else
		streamWriteBool(streamId, false);
	end
end;

--- Events ---

SkylineYarderToggleEvent = {};
SkylineYarderToggleEvent_mt = Class(SkylineYarderToggleEvent, Event);

InitEventClass(SkylineYarderToggleEvent, "SkylineYarderToggleEvent");

function SkylineYarderToggleEvent:emptyNew()
    local self = Event:new(SkylineYarderToggleEvent_mt);
    return self;
end;
    
function SkylineYarderToggleEvent:new(object, state, fastOn)
	local self = SkylineYarderToggleEvent:emptyNew()
	self.object = object;
	self.state = state;
	self.fastOn = fastOn;
	return self;
end;

function SkylineYarderToggleEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.state = streamReadBool(streamId);
	self.fastOn = streamReadBool(streamId);
	self:run(connection);
end;

function SkylineYarderToggleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteBool(streamId, self.state);
	streamWriteBool(streamId, self.fastOn);
end;

function SkylineYarderToggleEvent:run(connection)
	if self.object ~= nil then
		self.object:toggleYarder(self.state, self.fastOn, true);
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SkylineYarderToggleEvent:new(self.object, self.state, self.fastOn), nil, connection, self.object);
	end;
end;

function SkylineYarderToggleEvent.sendEvent(vehicle, state, fastOn,  noEventSend)
	if state ~= vehicle.state or fastOn ~= vehicle.fastOn then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(SkylineYarderToggleEvent:new(vehicle, state, fastOn), nil, nil, vehicle);
			else
				g_client:getServerConnection():sendEvent(SkylineYarderToggleEvent:new(vehicle, state, fastOn));
			end;
		end;
	end;
end

SkylineYarderAttachTreeEvent = {};
SkylineYarderAttachTreeEvent_mt = Class(SkylineYarderAttachTreeEvent, Event);

InitEventClass(SkylineYarderAttachTreeEvent, "SkylineYarderAttachTreeEvent");

function SkylineYarderAttachTreeEvent:emptyNew()
    local self = Event:new(SkylineYarderAttachTreeEvent_mt);
    return self;
end;
    
function SkylineYarderAttachTreeEvent:new(object, tX, tY, tZ, rX, rY, rZ, ropeHeight)
	local self = SkylineYarderAttachTreeEvent:emptyNew()
	self.object = object;
	self.tX = tX;
	self.tY = tY;
	self.tZ = tZ;
	self.rX = rX;
	self.rY = rY;
	self.rZ = rZ;
	self.ropeHeight = ropeHeight;
	return self;
end;

function SkylineYarderAttachTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self.tX = streamReadFloat32(streamId);
	self.tY = streamReadFloat32(streamId);
	self.tZ = streamReadFloat32(streamId);
	self.rX = streamReadFloat32(streamId);
	self.rY = streamReadFloat32(streamId);
	self.rZ = streamReadFloat32(streamId);
	self.ropeHeight = streamReadInt32(streamId);
	self:run(connection);
end;

function SkylineYarderAttachTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
	streamWriteFloat32(streamId, self.tX);
	streamWriteFloat32(streamId, self.tY);
	streamWriteFloat32(streamId, self.tZ);
	streamWriteFloat32(streamId, self.rX);
	streamWriteFloat32(streamId, self.rY);	
	streamWriteFloat32(streamId, self.rZ);
	streamWriteInt32(streamId, self.ropeHeight);
end;

function SkylineYarderAttachTreeEvent:run(connection)
	if self.object ~= nil then
		self.object:findTreeForYarder(self.tX, self.tY, self.tZ, self.rX, self.rY, self.rZ, self.ropeHeight, false, true);
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SkylineYarderAttachTreeEvent:new(self.object, self.tX, self.tY, self.tZ, self.rX, self.rY, self.rZ, self.ropeHeight), nil, connection, self.object);
	end;
end;

function SkylineYarderAttachTreeEvent.sendEvent(vehicle, tX, tY, tZ, rX, rY, rZ, ropeHeight, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SkylineYarderAttachTreeEvent:new(vehicle, tX, tY, tZ, rX, rY, rZ, ropeHeight), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(SkylineYarderAttachTreeEvent:new(vehicle, tX, tY, tZ, rX, rY, rZ, ropeHeight));
		end;
	end;
end;

SkylineYarderDetachTreeEvent = {};
SkylineYarderDetachTreeEvent_mt = Class(SkylineYarderDetachTreeEvent, Event);

InitEventClass(SkylineYarderDetachTreeEvent, "SkylineYarderDetachTreeEvent");

function SkylineYarderDetachTreeEvent:emptyNew()
    local self = Event:new(SkylineYarderDetachTreeEvent_mt);
    return self;
end;
    
function SkylineYarderDetachTreeEvent:new(object)
	local self = SkylineYarderDetachTreeEvent:emptyNew()
	self.object = object;
	return self;
end;

function SkylineYarderDetachTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId);
	self:run(connection);
end;

function SkylineYarderDetachTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object);
end;

function SkylineYarderDetachTreeEvent:run(connection)
	if self.object ~= nil then
		self.object:detachYarderRope(true);
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(SkylineYarderDetachTreeEvent:new(self.object), nil, connection, self.object);
	end;
end;

function SkylineYarderDetachTreeEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SkylineYarderDetachTreeEvent:new(vehicle), nil, nil, vehicle);
		else
			g_client:getServerConnection():sendEvent(SkylineYarderDetachTreeEvent:new(vehicle));
		end;
	end;
end;