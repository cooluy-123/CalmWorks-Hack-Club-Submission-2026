local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
-- CalmWorks radar: every visible GUI object is prebuilt in StarterGui.
-- This module changes data-dependent geometry/text only; it never creates or destroys UI.
local Radar = {}

local MAX_AXES = 20
local FILL_COLUMNS = 106
local FILL_BANDS = 5

local function percent(value)
    if type(value) ~= "number" then
        return "—"
    end
    return tostring(math.floor(math.clamp(value, 0, 1) * 100 + 0.5)) .. "%"
end

local function numberAttribute(instance, name, fallback)
    local value = instance:GetAttribute(name)
    return type(value) == "number" and value or fallback
end

local function stringAttribute(instance, name, fallback)
    local value = instance:GetAttribute(name)
    return type(value) == "string" and value ~= "" and value or fallback
end

local function setStyle(part, sample)
    if part:GetAttribute("UseSharedStyle") == false then
        return
    end
    part.BackgroundColor3 = sample.BackgroundColor3
    part.BackgroundTransparency = sample.BackgroundTransparency
end

local function drawSegment(part, a, b, sample)
    local delta = b - a
    local length = delta.Magnitude
    if length < 0.5 then
        part.Visible = false
        return
    end
    setStyle(part, sample)
    local thickness = part:GetAttribute("UseSharedStyle") == false and part.Size.Y.Offset
        or sample.Size.Y.Offset
    part.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
    part.Size = UDim2.fromOffset(length, thickness)
    part.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    part.Visible = true
end

local function collectNamed(group, pattern, amount)
    local result = {}
    for index = 1, amount do
        local part = group:FindFirstChild(string.format(pattern, index))
        assert(
            part and part:IsA("GuiObject"),
            "Missing editable radar part: " .. string.format(pattern, index)
        )
        result[index] = part
    end
    return result
end

function Radar.Bind(card)
    local plot = card:WaitForChild("RadarPlot")
    local canvas = plot:WaitForChild("ChartCanvas")
    local styles = card:WaitForChild("EditableChartStyles")
    local gridStyle = styles:WaitForChild("Grid")
    local outlineStyle = styles:WaitForChild("Outline")
    local markerStyle = styles:WaitForChild("Marker")
    local fillStyle = styles:WaitForChild("Fill")
    local axisNormal = styles:WaitForChild("AxisNormal")
    local axisSelected = styles:WaitForChild("AxisSelected")
    local subtitle = card:WaitForChild("Subtitle")
    local detail = card:WaitForChild("SelectionDetail")
    local recommendation = card:WaitForChild("RecommendationLabel")
    local practiceButton = card:WaitForChild("PracticeButton")
    local practiceInfo = card:WaitForChild("PracticeInfo")

    local fillGroup = canvas:WaitForChild("FillStrips")
    local gridGroup = canvas:WaitForChild("GridLines")
    local outlineGroup = canvas:WaitForChild("ScoreOutline")
    local markerGroup = canvas:WaitForChild("ScoreMarkers")
    local axisGroup = canvas:WaitForChild("AxisLabels")
    local rings = {}
    for ring = 1, 4 do
        rings[ring] = collectNamed(gridGroup, "Ring" .. ring .. "_Edge%02d", MAX_AXES)
    end
    local spokes = collectNamed(gridGroup, "Spoke%02d", MAX_AXES)
    local outlines = collectNamed(outlineGroup, "Edge%02d", MAX_AXES)
    local markers = collectNamed(markerGroup, "Marker%02d", MAX_AXES)
    local axes = collectNamed(axisGroup, "Axis%02d", MAX_AXES)
    local fill = {}
    for column = 1, FILL_COLUMNS do
        fill[column] = {}
        for band = 1, FILL_BANDS do
            local name = string.format("Slice_%03d_%d", column, band)
            local part = fillGroup:FindFirstChild(name)
            assert(part and part:IsA("Frame"), "Missing editable radar part: " .. name)
            fill[column][band] = part
        end
    end

    local snapshot
    local selectedCode
    local categoryForAxis = {}
    local rendering = false

    local function updateDetail()
        if not snapshot or type(snapshot.Categories) ~= "table" then
            return
        end
        local picked
        for _, category in ipairs(snapshot.Categories) do
            if category.Code == selectedCode then
                picked = category
                break
            end
        end
        if not picked then
            detail.Text = stringAttribute(
                card,
                "EmptyDetailText",
                "Select a category on the chart to see your recent results."
            )
            return
        end
        local attempts = math.max(0, tonumber(picked.Total) or 0)
        if snapshot.IsWeekly then
            detail.Text =
                UI.T("Radar", "DetailWeekly", picked.Name, percent(picked.Accuracy), picked.MeasuredDays or 0)
        elseif snapshot.HasData == false then
            detail.Text = UI.T("Radar", "MissingDetail", picked.Name)
        elseif attempts == 0 then
            local unmeasured =
                stringAttribute(card, "UnmeasuredText", "Not measured in your last {window} answers")
            detail.Text = picked.Name
                .. "  •  "
                .. unmeasured:gsub("{window}", tostring(snapshot.WindowSize or 50))
        else
            detail.Text = UI.T(
                "Radar",
                "DetailDaily",
                picked.Name,
                percent(picked.Accuracy),
                picked.Correct or 0,
                attempts
            )
        end
    end

    local function render()
        if rendering or not snapshot or type(snapshot.Categories) ~= "table" then
            return
        end
        rendering = true
        local categories = snapshot.Categories
        local count = math.min(#categories, MAX_AXES)
        local side = math.min(plot.AbsoluteSize.X, plot.AbsoluteSize.Y)
        if #categories > MAX_AXES then
            warn("Skills radar has more categories than its editable 20-axis capacity")
        end
        if count < 3 or side < 100 then
            rendering = false
            return
        end
        local center = Vector2.new(side / 2, side / 2)
        local radius = side * math.clamp(numberAttribute(plot, "RadiusScale", 0.315), 0.05, 0.43)
        local labelRadius = side * math.clamp(numberAttribute(plot, "LabelRadiusScale", 0.445), 0.08, 0.49)
        local startAngle = math.rad(numberAttribute(plot, "StartAngleDegrees", -90))
        local compact = side < numberAttribute(plot, "CompactBreakpoint", 290)
        local outer, values, angles = {}, {}, {}
        local measured = 0
        for index = 1, count do
            local category = categories[index]
            local angle = startAngle + (index - 1) * 2 * math.pi / count
            local direction = Vector2.new(math.cos(angle), math.sin(angle))
            angles[index] = direction
            outer[index] = center + direction * radius
            local accuracy = type(category.Accuracy) == "number" and math.clamp(category.Accuracy, 0, 1) or 0
            values[index] = center + direction * radius * accuracy
            if (tonumber(category.Total) or 0) > 0 then
                measured += 1
            end
        end

        for column = 1, FILL_COLUMNS do
            local x = (column - 1) * side / FILL_COLUMNS
            -- Slight overlap prevents subpixel rounding from showing seams on phones.
            local width = side / FILL_COLUMNS + 1.5
            local intersections = {}
            if measured > 0 then
                for index = 1, count do
                    local a, b = values[index], values[index % count + 1]
                    if (a.X <= x and x < b.X) or (b.X <= x and x < a.X) then
                        table.insert(intersections, a.Y + (x - a.X) * (b.Y - a.Y) / (b.X - a.X))
                    end
                end
                table.sort(intersections)
            end
            for band = 1, FILL_BANDS do
                local part = fill[column][band]
                local top, bottom = intersections[2 * band - 1], intersections[2 * band]
                if top and bottom and bottom > top then
                    setStyle(part, fillStyle)
                    part.Position = UDim2.fromOffset(x, top)
                    part.Size = UDim2.fromOffset(width, bottom - top)
                    part.Visible = true
                else
                    part.Visible = false
                end
            end
        end

        for ring = 1, 4 do
            for index = 1, MAX_AXES do
                local part = rings[ring][index]
                if index <= count then
                    local nextIndex = index % count + 1
                    local a = center + (outer[index] - center) * ring / 4
                    local b = center + (outer[nextIndex] - center) * ring / 4
                    drawSegment(part, a, b, gridStyle)
                else
                    part.Visible = false
                end
            end
        end
        for index = 1, MAX_AXES do
            if index <= count then
                drawSegment(spokes[index], center, outer[index], gridStyle)
                drawSegment(outlines[index], values[index], values[index % count + 1], outlineStyle)
                local marker = markers[index]
                setStyle(marker, markerStyle)
                marker.Position = UDim2.fromOffset(values[index].X, values[index].Y)
                marker.Visible = true
            else
                spokes[index].Visible = false
                outlines[index].Visible = false
                markers[index].Visible = false
            end
        end

        table.clear(categoryForAxis)
        local assigned = {}
        for index = 1, count do
            local category = categories[index]
            local axis
            for _, candidate in ipairs(axes) do
                if candidate:GetAttribute("CategoryCode") == category.Code and not assigned[candidate] then
                    axis = candidate
                    break
                end
            end
            if not axis then
                for _, candidate in ipairs(axes) do
                    if not assigned[candidate] then
                        axis = candidate
                        break
                    end
                end
            end
            assigned[axis] = true
            categoryForAxis[axis] = category
            local source = selectedCode == category.Code and axisSelected or axisNormal
            if axis:GetAttribute("UseSharedStyle") ~= false then
                axis.TextColor3 = source.TextColor3
                axis.Font = source.Font
            end
            local name = compact and stringAttribute(axis, "CompactName", category.Code)
                or stringAttribute(axis, "ShortName", category.Name)
            axis.Text = name
                .. (axis:GetAttribute("ShowPercent") == false and "" or "\n" .. percent(category.Accuracy))
            if axis:GetAttribute("AutoLayoutEnabled") ~= false then
                axis.Size = UDim2.fromOffset(
                    numberAttribute(axis, compact and "CompactWidth" or "DesktopWidth", compact and 58 or 86),
                    numberAttribute(
                        axis,
                        compact and "CompactHeight" or "DesktopHeight",
                        compact and 28 or 36
                    )
                )
                axis.TextSize = numberAttribute(
                    axis,
                    compact and "CompactTextSize" or "DesktopTextSize",
                    compact and 10 or 11
                )
                local offset = axis:GetAttribute("PositionOffset")
                if typeof(offset) ~= "Vector2" then
                    offset = Vector2.zero
                end
                local point = center + angles[index] * labelRadius + offset
                axis.Position = UDim2.fromOffset(point.X, point.Y)
            end
            axis.Visible = true
        end
        for _, axis in ipairs(axes) do
            if not assigned[axis] then
                axis.Visible = false
            end
        end
        rendering = false
    end

    for _, axis in ipairs(axes) do
        axis.Activated:Connect(function()
            local category = categoryForAxis[axis]
            if not category then
                return
            end
            selectedCode = category.Code
            updateDetail()
            render()
        end)
    end

    local resizing = false
    local function resize()
        if card:GetAttribute("AutoLayoutEnabled") == false then
            render()
            return
        end
        if resizing then
            return
        end
        resizing = true
        local available = math.max(100, card.Parent.AbsoluteSize.X)
        local side = math.clamp(
            available - numberAttribute(card, "ChartSidePadding", 88),
            math.min(numberAttribute(card, "MinChartSize", 180), math.max(60, available - 88)),
            numberAttribute(card, "MaxChartSize", 420)
        )
        plot.Position = UDim2.new(0.5, 0, 0, numberAttribute(card, "PlotTop", 79))
        plot.Size = UDim2.fromOffset(side, side)
        detail.Position = UDim2.new(0, 18, 0, side + numberAttribute(card, "DetailTopOffset", 93))
        recommendation.Position =
            UDim2.new(0, 18, 0, side + numberAttribute(card, "RecommendationTopOffset", 141))
        local scale, ancestor = 1, recommendation
        while ancestor and not ancestor:IsA("ScreenGui") do
            local uiScale = ancestor:FindFirstChildOfClass("UIScale")
            if uiScale then
                scale *= math.max(0.01, uiScale.Scale)
            end
            ancestor = ancestor.Parent
        end
        local recommendationHeight = math.max(
            numberAttribute(card, "RecommendationMinHeight", 66),
            recommendation.AbsoluteSize.Y / scale
        )
        local recommendationBottom = side
            + numberAttribute(card, "RecommendationTopOffset", 141)
            + recommendationHeight
            + numberAttribute(card, "RecommendationBottomPadding", 18)
        local buttonHeight = practiceButton.AbsoluteSize.Y / scale
        practiceButton.Position =
            UDim2.new(0.5, 0, 0, recommendationBottom + buttonHeight * practiceButton.AnchorPoint.Y)
        practiceInfo.Position = UDim2.new(
            practiceInfo.Position.X.Scale,
            practiceInfo.Position.X.Offset,
            0,
            recommendationBottom + buttonHeight + 8
        )
        if practiceButton.Visible then
            recommendationBottom += buttonHeight + 18 + practiceInfo.AbsoluteSize.Y / scale
        end
        card.Size = UDim2.new(
            1,
            -8,
            0,
            math.max(side + numberAttribute(card, "CardBottomOffset", 226), recommendationBottom)
        )
        render()
        resizing = false
    end

    card.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    plot:GetPropertyChangedSignal("AbsoluteSize"):Connect(render)
    recommendation:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    practiceButton:GetPropertyChangedSignal("Visible"):Connect(resize)
    practiceInfo:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
    resize()

    return function(data)
        snapshot = data
        if type(data) ~= "table" then
            return
        end
        local total = math.max(0, tonumber(data.TotalAnswers) or 0)
        local template = stringAttribute(
            card,
            "SubtitleTemplate",
            "Recent accuracy by category  •  {answered}/{window} answers recorded"
        )
        subtitle.Text =
            template:gsub("{answered}", tostring(total)):gsub("{window}", tostring(data.WindowSize or 50))
        if data.IsWeekly then
            subtitle.Text = UI.T("Radar", "WeeklySubtitle", tostring(data.SavedDays or 0))
        elseif data.Historical then
            subtitle.Text = data.HasData == false and UI.T("Radar", "MissingSubtitle")
                or UI.T("Radar", "HistoricalSubtitle", tostring(data.WindowSize or 50))
        end
        recommendation.Text = type(data.Recommendation) == "string" and data.Recommendation
            or stringAttribute(card, "DefaultRecommendationText", "Continue practicing and improving!")
        local targeted = type(data.RecommendationCategoryCode) == "string"
        local background = card:GetAttribute(
            targeted and "TargetRecommendationBackground" or "DefaultRecommendationBackground"
        )
        local foreground =
            card:GetAttribute(targeted and "TargetRecommendationText" or "DefaultRecommendationText")
        if typeof(background) == "Color3" then
            recommendation.BackgroundColor3 = background
        end
        if typeof(foreground) == "Color3" then
            recommendation.TextColor3 = foreground
        end
        if not selectedCode then
            selectedCode = data.RecommendationCategoryCode
            if not selectedCode and type(data.Categories) == "table" then
                for _, category in ipairs(data.Categories) do
                    if (tonumber(category.Total) or 0) > 0 then
                        selectedCode = category.Code
                        break
                    end
                end
            end
        end
        updateDetail()
        task.defer(resize)
        render()
    end
end

return Radar
