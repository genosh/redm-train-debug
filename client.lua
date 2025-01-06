local TestTrainEntities

-- MODE:
--loop: automatized loop train spawn to determine index and hash track from junction
--log: Log near track index and position
--spawn: Spawn a train on the most near tracks
local mode = "spawn"

CreateThread(function()
    --To edit for specific junction
    local trainStartCoord = vector3(627.8143, 689.8227, 115.1818) --Train spawn location (obtained by logs with mode = log)
    local expectedIndexResult = 2  --traintrack index expected to determinate id train has changed of way (obtained by logs with mode = log)
    local dirChange = 1  -- train direction

    --Don't touch if you don't know
    local trackModels = {
        'TRAINS3',
        'TRAINS_NB1',
        'TRAINS_OLD_WEST01',
        'TRAINS_OLD_WEST02', --New found
        'TRAINS_OLD_WEST03',
        'FREIGHT_GROUP',
        'BRAITHWAITES2_TRACK_CONFIG',
        'TRAINS_INTERSECTION1_ANN',
    }
    local mDelay = 2000
    local trainHash = joaat('engine_config')

    --Reset junction. Set all junctions to false (I guess is initial position for all?)
    for _, trainTrack in pairs(trackModels) do
        for i=0, 30, 1 do
            SetTrainTrackJunctionSwitch(joaat(trainTrack), i, false)
        end
    end

    --Start tests
    -- Spwan looping train to determine the index and tracktrackmodel for juncions
    if mode == "log" then
        while true do
            print("===========")
            local traintrackIndex = GetTrackIndexFromCoords(GetEntityCoords(PlayerPedId()))
            print("traintrackIndex: " .. traintrackIndex)
            local NearestTrainTrackPosition = GetNearestTrainTrackPosition(GetEntityCoords(PlayerPedId()))
            print("NearestTrainTrackPosition: " .. NearestTrainTrackPosition)
            print("-----")
            Wait(2000)
        end
    elseif mode == "loop" then
        for _, trainTrack in pairs(trackModels) do
            for i=0, 30, 1 do
                    SetTrainTrackJunctionSwitch(joaat(trainTrack), i, true)
                    Wait(1000)
                    LoadTrainCars(trainHash)
                    TestTrainEntities = Citizen.InvokeNative(0xc239dbd9a57d2a71, trainHash, trainStartCoord, dirChange, false, true, false) -- CreateMissionTrain
                    SetModelAsNoLongerNeeded(model)
                    -- Freeze Train on Spawn
                    Citizen.InvokeNative(0xDFBA6BBFF7CCAFBB, TestTrainEntities, 30.0) -- SetTrainSpeed

                    print("===========================")
                    print("trainTrack: " .. trainTrack)
                    print("index: " .. i)

                    Wait(mDelay)
                    local trainResult = GetTrackIndexOfTrain(TestTrainEntities)
                    print("trainResult: " .. trainResult)
                    if trainResult ~= expectedIndexResult then
                        return
                    end
                    DeleteEntity(TestTrainEntities)
                    SetTrainTrackJunctionSwitch(joaat(trainTrack), i, false)
            end
        end
    elseif mode == "spawn" then
        local NearestTrainTrackPosition = GetNearestTrainTrackPosition(GetEntityCoords(PlayerPedId()))
        LoadTrainCars(trainHash)
        TestTrainEntities = Citizen.InvokeNative(0xc239dbd9a57d2a71, trainHash, NearestTrainTrackPosition, math.random(0,1), false, true, false) -- CreateMissionTrain
        SetModelAsNoLongerNeeded(model)
        -- Freeze Train on Spawn
        Citizen.InvokeNative(0xDFBA6BBFF7CCAFBB, TestTrainEntities, 0.0) -- SetTrainSpeed
        Citizen.InvokeNative(0x01021EB2E96B793C, TestTrainEntities, 0.0) -- SetTrainCruiseSpeed
        Citizen.InvokeNative(0x9F29999DFDF2AEB8, TestTrainEntities, 60.0) -- SetTrainMaxSpeed
    end
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if TestTrainEntities then
        DeleteEntity(TestTrainEntities)
        TestTrainEntities = nil
        --SetAllJunctionsCleared()
    end
end)


function LoadTrainCars(trainHash)
    local cars = Citizen.InvokeNative(0x635423d55ca84fc8, trainHash) -- GetNumCarsFromTrainConfig
    for index = 0, cars - 1 do
        local model = Citizen.InvokeNative(0x8df5f6a19f99f0d5, trainHash, index) -- GetTrainModelFromTrainConfigByCarIndex
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end
    end
end
