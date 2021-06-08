function MaNGOS_Print(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('|cffe1761b[MaNGOS Model Viewer Error] [|cff0070de' .. time() .. ']:|r Attempted to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cffe1761b[MaNGOS Model Viewer]:|r " .. a)
end

local mv = CreateFrame("Frame")
mv:RegisterEvent("CHAT_MSG_SYSTEM")
mv:RegisterEvent("ADDON_LOADED")

mv.cats = {}

local gModel = nil

mv:SetScript('OnEvent', function(self, event, ...) 
    self[event](self, ...) 
    if event == 'CHAT_MSG_SYSTEM' then

        -- Searching for system message related to the addition of a game object.
        if string.find(..., 'Add Game Object', 1, true) then
            local ex = string.split(..., 'GUID:')
            local ex2 = string.split(ex[2], '\) ')
            local coords = string.split(ex2[2], ' ')
            local x = coords[3]
            x = tonumber(string.sub(x, 2, string.len(x)))
            local y = tonumber(coords[4])
            local z = coords[5]
            z = tonumber(string.sub(z, 1, string.len(z) - 2))

            mv.currentGO = {
                guid = ex2[1],
                x = x,
                y = y,
                z = z
            }

            getglobal('MaNGOSMVGOGUIDText'):SetText('GUID: ' .. mv.currentGO.guid)

            getglobal('MaNGOSMV'):Hide()
            getglobal('MaNGOSMVGO'):Show()
        end

        -- Searching for system message related to the number of nearby game objects.
        if string.find(..., 'Found near gameobjects', 1, true) then
            ModelsList_Update()

            getglobal('MaNGOSMVAddGOButton'):SetText('Manage')
            getglobal('MaNGOSMVGOCount'):SetText(table.getn(mv.near))
        end

        -- Searching for system message related to the name and coordinates of the game object when scanning nearby.
        if string.find(..., ', Entry ', 1, true) and string.find(..., 'MapId:') then
            local ex = string.split(..., ' ')
            local guid = string.sub(ex[1], 1, string.len(ex[1]) - 1)
            local coords = string.split(..., 'X:')
            local x = coords[2]
            local cex = string.split(x, ' ')
            x = tonumber(cex[1])
            local y = string.sub(cex[2], 3, string.len(cex[2]))
            local z = string.sub(cex[3], 3, string.len(cex[3]))

            local modelName = string.split(..., '\[')
            modelName = string.split(modelName[2], ' X:')
            modelName = modelName[1]

            local filename = 'filename'
            local short = 'short'

            for cat, data in next, mv.cats do
                for index, model in next, data do
                    if string.lower(modelName) == string.lower(model.short) then
                        filename = model.filename
                        short = model.short
                    end
                end
            end

            table.insert(mv.near, {
                guid = guid,
                id = guid,
                x = x,
                y = y,
                z = z,
                filename = filename,
                short = short
            })
        end
    
    elseif event == 'ADDON_LOADED' and ...== "MaNGOS_Model_Viewer" then
        getglobal('MaNGOSMVAddGOButton'):Disable()

        gModel = getglobal('mvmodel')
        gModel:SetModel("World\\Azeroth\\Elwynn\\PassiveDoodads\\jugs\\jug02.mdx")

        gModel:SetScript('OnMouseUp', function(self)
            gModel:SetScript('OnUpdate', nil)
        end)

        gModel:SetScript('OnMouseWheel', function(self, wheelSpin)
            local Z, X, Y = gModel:GetPosition()

            Z = (wheelSpin > 0 and Z + 1 or Z - 1)

            gModel:SetPosition(Z, X, Y)
        end)

        gModel:SetScript('OnMouseDown', function(self, mouseButton)
            local StartX, StartY = GetCursorPosition()

            local EndX, EndY, Z, X, Y
            if mouseButton == 'RightButton' then
                gModel:SetScript('OnUpdate', function(self)
                    EndX, EndY = GetCursorPosition()

                    gModel.rotation = (EndX - StartX) / 34 + gModel:GetFacing()

                    gModel:SetFacing(gModel.rotation)

                    StartX, StartY = GetCursorPosition()
                end)
            elseif mouseButton == 'LeftButton' then
                gModel:SetScript('OnUpdate', function(self)
                    EndX, EndY = GetCursorPosition()

                    Z, X, Y = gModel:GetPosition(Z, X, Y)
                    X = (EndX - StartX) / 45 + X
                    Y = (EndY - StartY) / 45 + Y

                    gModel:SetPosition(Z, X, Y)
                    StartX, StartY = GetCursorPosition()
                end)
            end
        end)

        for _, data in next, m1data do
            if tonumber(data.id) >= 0 then
                local ex = string.split(data.filename, '\\')

                local key = ex[table.getn(ex) - 1]

                if mv.cats[key] == nil then
                    mv.cats[key] = {}
                end

                table.insert(mv.cats[key], data);
            end
        end

        local models = 0

        for _, data in next, mv.cats do
            for _, _ in next, data do
                models = models + 1
            end
        end

        getglobal('MaNGOSMVGOCount'):SetText(models)

        CatsList_Update()
    end
end)

function mv:CHAT_MSG_SYSTEM(...)
    -- MaNGOS_Print("CHAT_MSG_SYSTEM detected");
end

function mv:ADDON_LOADED(...)
    -- MaNGOS_Print("ADDON_LOADED detected");
end

mv.catsFrames = {}

local scrollItems = 17

function CatsList_Update()
    local itemOffset = FauxScrollFrame_GetOffset(getglobal("MVCatsScrollFrame"));
    local totalItems = mvSize(mv.cats)

    for index in next, mv.catsFrames do
        mv.catsFrames[index]:Hide()
    end

    if totalItems > 0 then

        local index = 0
        for cat, _ in next, mv.cats do

            index = index + 1

            if index > itemOffset and index <= itemOffset + scrollItems then

                if not mv.catsFrames[index] then
                    mv.catsFrames[index] = CreateFrame('Frame', 'Cat' .. index, getglobal("MaNGOSMV"), 'CatButtonTemplate')
                end

                mv.catsFrames[index]:SetPoint("TOPLEFT", getglobal("MaNGOSMV"), "TOPLEFT", 10, -22 - 22 * (index - itemOffset) - 55)
                mv.catsFrames[index]:Show()

                getglobal("Cat" .. index .. 'LoadButton'):SetText(string.sub(cat, 0, 23))
            end
        end
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(getglobal("MVCatsScrollFrame"), totalItems, scrollItems, 22);

end

mv.fromSearch = false
mv.fromNear = false
mv.searchResults = {}

function SearchBox_OnEnterPressed(q)
    mv.fromSearch = true
    mv.fromNear = false
    getglobal('MaNGOSMVAddGOButton'):SetText('Add GO')
    mv.searchResults = {}

    for _, data in next, mv.cats do
        for _, model in next, data do
            if string.find(string.lower(model.short), string.lower(q), 1, true) or
                    string.find(string.lower(model.filename), string.lower(q), 1, true) then
                table.insert(mv.searchResults, model)
            end
        end
    end

    getglobal('MaNGOSMVGOCount'):SetText(table.getn(mv.searchResults))
    getglobal('MaNGOSMVModelsTitle'):SetText('Results')

    ModelsList_Update()
end

-- Working as expected.
function MaNGOS_ToggleMainWindow()
    if getglobal('MaNGOSMV'):IsVisible() == 1 then
        getglobal('MaNGOSMV'):Hide()
    else
        getglobal('MaNGOSMV'):Show()
    end
    CatsList_Update()
end

function CatButton_OnClick(catName)
    mv.catName = catName
    mv.fromSearch = false
    mv.fromNear = false

    getglobal('MaNGOSMVModelsTitle'):SetText('Models')
    getglobal('MaNGOSMVAddGOButton'):SetText('Add GO')
    getglobal('MaNGOSMVAddGOButton'):Disable()
    ModelsList_Update()
end

mv.modelsFrames = {}
mv.catName = ''

function ModelsList_Update()
    local catName = mv.catName

    local itemOffset = FauxScrollFrame_GetOffset(getglobal("MVModelsScrollFrame"));

    local models = {}

    if mv.fromSearch then
        models = mv.searchResults
    elseif mv.fromNear then
        models = mv.near
    else
        for cat, data in next, mv.cats do
            if cat == catName then
                models = data
            end
        end

        getglobal('MaNGOSMVGOCount'):SetText(table.getn(models))

    end

    local totalItems = mvSize(models)

    for index in next, mv.modelsFrames do
        mv.modelsFrames[index]:Hide()
    end

    if totalItems > 0 then

        local index = 0
        for i, model in next, models do

            index = index + 1

            if index > itemOffset and index <= itemOffset + scrollItems then

                if not mv.modelsFrames[index] then
                    mv.modelsFrames[index] = CreateFrame('Frame', 'ModelFrame' .. index, getglobal("MaNGOSMV"), 'ModelButtonTemplate')
                end

                mv.modelsFrames[index]:SetPoint("TOPLEFT", getglobal("MaNGOSMV"), "TOPLEFT", 230, -22 - 22 * (index - itemOffset) - 55)
                mv.modelsFrames[index]:Show()

                getglobal("ModelFrame" .. index .. 'LoadButton'):SetText(string.sub(model.short, 0, 20))
                getglobal("ModelFrame" .. index .. 'LoadButton'):SetID(tonumber(model.id))
            end
        end
    end

    -- ScrollFrame update
    FauxScrollFrame_Update(getglobal("MVModelsScrollFrame"), totalItems, scrollItems, 22);

end

mv.currentModel = 0
mv.currentGO = {
    guid = 0,
    x = 0,
    y = 0,
    z = 0
}

function LoadModelButton_OnClick(d)
    if mv.fromNear then
        for i, model in next, mv.near do
            if tonumber(model.guid) == tonumber(d) then
                mv.currentGO = {
                    guid = model.guid,
                    x = model.x,
                    y = model.y,
                    z = model.z
                }
                gModel:SetModel(model.filename)
                mv.currentModel = model.id
            end
        end
    else
        for cat, data in next, mv.cats do
            for index, model in next, data do
                if tonumber(d) == tonumber(model.id) then
                    gModel:SetModel(model.filename)
                    mv.currentModel = model.id
                end
            end
        end
    end

    gModel:SetPosition(0, 0, 0)
    gModel:SetFacing(0)

    getglobal('MaNGOSMVAddGOButton'):Enable()
end

function AddGoButton_OnClick()
    if mv.fromNear then
        getglobal('MaNGOSMVGOGUIDText'):SetText('GUID: ' .. mv.currentGO.guid)

        getglobal('MaNGOSMV'):Hide()
        getglobal('MaNGOSMVGO'):Show()
        return true
    end

    if mv.currentModel == 0 then
        MaNGOS_Print('please select an object');
    else
        SendChatMessage('.gobject add ' .. mv.currentModel)
    end
end

function DeleteGO_OnClick()
    if mv.currentGO.guid == 0 then
        MaNGOS_Print('please select an object');
    else
        SendChatMessage('.gobject delete ' .. mv.currentGO.guid)
        mv.currentGO.guid = 0
        getglobal('MaNGOSMV'):Show()
        getglobal('MaNGOSMVGO'):Hide()
    end
end

mv.moveRate = 1

function MoveGoX_OnClick(dir)
    mv.currentGO.x = mv.currentGO.x + (dir * mv.moveRate)
    MaNGOS_Print("new mv.currentGO.x: " .. mv.currentGO.x);

    SendChatMessage('.gobject move ' .. mv.currentGO.guid .. ' ' .. mv.currentGO.x .. ' ' .. mv.currentGO.y .. ' ' .. mv.currentGO.z)
end

function MoveGoY_OnClick(dir)
    mv.currentGO.y = mv.currentGO.y + dir * mv.moveRate
    SendChatMessage('.gobject move ' .. mv.currentGO.guid .. ' ' .. mv.currentGO.x .. ' ' .. mv.currentGO.y .. ' ' .. mv.currentGO.z)
end

function MoveGoZ_OnClick(dir)
    mv.currentGO.z = mv.currentGO.z + dir * mv.moveRate
    SendChatMessage('.gobject move ' .. mv.currentGO.guid .. ' ' .. mv.currentGO.x .. ' ' .. mv.currentGO.y .. ' ' .. mv.currentGO.z)
end

function TurnGo_OnClick()
    SendChatMessage('.gobject turn ' .. mv.currentGO.guid)
end

function DoneGO_OnClick()
    getglobal('MaNGOSMV'):Show()
    getglobal('MaNGOSMVGO'):Hide()
end

mv.near = {}

function Near_OnClick()
    for index in next, mv.modelsFrames do
        mv.modelsFrames[index]:Hide()
    end
    SendChatMessage('.gobject near')
    getglobal('MaNGOSMVModelsTitle'):SetText('Near')
    getglobal('MaNGOSMVAddGOButton'):Disable()
    mv.fromNear = true
    mv.fromSearch = false
    mv.near = {}
end

mv.modelPos = {
    x = 0,
    y = 0,
    z = 0
}

function FactorChange_OnClick(dir)
    if dir == 1 then
        mv.moveRate = mv.moveRate + 0.2
    else
        mv.moveRate = mv.moveRate - 0.2
    end
    getglobal('MaNGOSMVGOFactorText'):SetText('Move factor:              ' .. mv.moveRate)

end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from, true)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from, true)
    end
    table.insert(result, string.sub(self, from))
    return result
end

function mvReplace(text, search, replace)
    if (search == replace) then
        return text;
    end
    local searchedtext = "";
    local textleft = text;
    while (strfind(textleft, search, 1)) do
        searchedtext = searchedtext .. strsub(textleft, 1, strfind(textleft, search, 1) - 1) .. replace;
        textleft = strsub(textleft, strfind(textleft, search, 1) + strlen(search));
    end
    if (strlen(textleft) > 0) then
        searchedtext = searchedtext .. textleft;
    end
    return searchedtext;
end

function mvSize(table)
    if type(table) ~= 'table' then
        MaNGOS_Print('attempt to get table size of a non table (' .. type(table) .. ')')
        MaNGOS_Print('not table = ' .. table)
        return 0
    end
    local len = 0
    for _ in next, table do
        len = len + 1
    end
    return len
end
