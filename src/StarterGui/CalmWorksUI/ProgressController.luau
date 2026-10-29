local UI =
    require(game:GetService("ReplicatedStorage"):WaitForChild("CalmWorksShared"):WaitForChild("EditableUI"))
-- Binds saved Studio GUI instances; no UI is created at runtime.
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Shared = game.ReplicatedStorage.CalmWorksShared
local Calendar = require(Shared.ProgressCalendar)
local Feedback = require(Shared.ActionFeedback)
local Controller = {}
function Controller.Bind(gui, render)
    local panel = gui.AccuracyPanel
    local scroll = panel.ContentScroll
    local card = scroll.ProgressSliderCard
    local radar = scroll.SkillsTrackerCard
    local practiceButton, practiceInfo = radar.PracticeButton, radar.PracticeInfo
    local track = card.SliderTrack
    local dateLabel, modeButton = card.DateLabel, card.CadenceButton
    local savedLayout = UI.CaptureLayout({ card.Title, dateLabel, modeButton })
    local fillY, thumbY = track.Fill.Size.Y, track.Thumb.Position.Y
    local remotes = game.ReplicatedStorage.CalmWorksRemotes
    local live, meta, practice
    local mode, selectedDay = "Daily", nil
    local steps, index = {}, 1
    local dragging, previousScroll, dragInput = false, true, nil
    local requestSerial = 0
    local practiceBusy = false
    local displayedDay, displayedMode
    local requestSelection
    local function message(text)
        card.StatusLabel.Text = text
    end
    local function nearest(day)
        local best, distance = 1, math.huge
        for i, value in ipairs(steps) do
            if math.abs(value - day) < distance then
                best, distance = i, math.abs(value - day)
            end
        end
        return best
    end
    local function draw()
        local fraction = #steps > 1 and (index - 1) / (#steps - 1) or 1
        track.Fill.Size = UDim2.new(fraction, 0, fillY.Scale, fillY.Offset)
        track.Thumb.Position = UDim2.new(fraction, 0, thumbY.Scale, thumbY.Offset)
        if not meta then
            return
        end
        selectedDay = steps[index]
        dateLabel.Text = Calendar.Label(selectedDay)
        modeButton.Text = mode == "Weekly" and UI.T("Progress", "Weekly") or UI.T("Progress", "Daily")
        card.StartLabel.Text = Calendar.Label(meta.FirstDay)
        card.EndLabel.Text = Calendar.Label(meta.LastDay)
        card.PreviousButton.Interactable = index > 1
        card.NextButton.Interactable = index < #steps
        track.Selectable = #steps > 1
        card:SetAttribute("SelectedDay", selectedDay)
        card:SetAttribute("Cadence", mode)
    end
    local function updatePractice(data)
        if type(data) ~= "table" then
            return
        end
        practice = data
        local targets = type(data.Targets) == "table" and data.Targets or {}
        practiceButton.Visible = data.Enabled or #targets > 0
        practiceInfo.Visible = practiceButton.Visible
        practiceButton.Text = data.Enabled and UI.T("Progress", "PracticeOn")
            or UI.T("Progress", "PracticeOff")
        practiceButton.Interactable = not practiceBusy
        local names = {}
        for _, t in ipairs(targets) do
            table.insert(names, t.Name .. (t.Unmeasured and UI.T("Progress", "FreshSample") or ""))
        end
        practiceInfo.Text = (data.Enabled and UI.T("Progress", "Practicing") or UI.T("Progress", "Targets"))
            .. table.concat(names, ", ")
            .. UI.T("Progress", "CurrentOnly")
            .. (data.Note or "")
    end
    local function show(data)
        displayedDay, displayedMode = selectedDay, mode
        render(data)
        updatePractice(data.Practice or practice)
        if not data.Historical then
            message(UI.T("Progress", "Live"))
        elseif not data.HasData then
            message(UI.T("Progress", "NoData"))
        elseif data.IsWeekly then
            message(
                Calendar.Label(data.PeriodStart)
                    .. " – "
                    .. Calendar.Label(data.PeriodEnd)
                    .. UI.T(
                        "Progress",
                        "WeeklySummary",
                        data.SavedDays,
                        data.PeriodDays,
                        data.PeriodDays < 7 and UI.T("Progress", "PartialWeek") or ""
                    )
            )
        else
            message(UI.T("Progress", "Captured", Calendar.CaptureLabel(data.CapturedAt)))
        end
    end
    requestSelection = function()
        if not live or not meta then
            return
        end
        requestSerial += 1
        local serial = requestSerial
        local day, wantedMode = selectedDay, mode
        if wantedMode == "Daily" and day == meta.Today then
            show(live)
            return
        end
        message(UI.T("Progress", "Loading"))
        -- Coalesce held keys/clicks; dragging fetches only when the player releases.
        task.delay(0.16, function()
            if serial ~= requestSerial or not panel.Visible then
                return
            end
            local ok, data = pcall(function()
                return remotes.GetProgressView:InvokeServer({ Day = day, Mode = wantedMode })
            end)
            if serial ~= requestSerial or not panel.Visible then
                return
            end
            if not ok or type(data) ~= "table" or data.Error then
                -- Never leave an old chart labeled with a failed/new date.
                if displayedDay then
                    mode = displayedMode
                    steps = Calendar.Steps(meta.FirstDay, meta.LastDay, mode == "Weekly")
                    index = nearest(displayedDay)
                    draw()
                end
                Feedback.Error()
                message(type(data) == "table" and data.Error or UI.T("Progress", "Unavailable"))
                return
            end
            show(data)
        end)
    end
    local function moveTo(newIndex, commit)
        if #steps == 0 then
            return
        end
        index = math.clamp(newIndex, 1, #steps)
        draw()
        if commit then
            requestSelection()
        end
    end
    local function dragAt(x)
        local inset = gui.IgnoreGuiInset and 0 or GuiService:GetGuiInset().X
        local ratio =
            math.clamp((x - inset - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        moveTo(math.floor(ratio * math.max(0, #steps - 1) + 0.5) + 1, false)
        message(UI.T("Progress", "Preview", Calendar.Label(selectedDay)))
    end
    track.InputBegan:Connect(function(input)
        if not panel.Visible or #steps < 2 then
            return
        end
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging, dragInput = true, input
            previousScroll = scroll.ScrollingEnabled
            scroll.ScrollingEnabled = false
            requestSerial += 1
            dragAt(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            dragAt(input.Position.X)
        end
    end)
    local function endDrag(commit)
        if not dragging then
            return
        end
        dragging, dragInput = false, nil
        scroll.ScrollingEnabled = previousScroll
        if commit then
            requestSelection()
        end
    end
    UIS.InputEnded:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
            endDrag(true)
        end
    end)
    UIS.InputBegan:Connect(function(input, processed)
        if not panel.Visible or UIS:GetFocusedTextBox() or GuiService.SelectedObject ~= track then
            return
        end
        if input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.DPadLeft then
            moveTo(index - 1, true)
        elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.DPadRight then
            moveTo(index + 1, true)
        elseif input.KeyCode == Enum.KeyCode.Home then
            moveTo(1, true)
        elseif input.KeyCode == Enum.KeyCode.End then
            moveTo(#steps, true)
        end
    end)
    card.PreviousButton.Activated:Connect(function()
        moveTo(index - 1, true)
    end)
    card.NextButton.Activated:Connect(function()
        moveTo(index + 1, true)
    end)
    card.LatestButton.Activated:Connect(function()
        if not meta then
            return
        end
        mode = "Daily"
        steps = Calendar.Steps(meta.FirstDay, meta.LastDay, false)
        moveTo(#steps, true)
    end)
    modeButton.Activated:Connect(function()
        if not meta or not meta.WeeklyAvailable then
            Feedback.Error()
            message(UI.T("Progress", "WeeklyLocked"))
            return
        end
        mode = mode == "Daily" and "Weekly" or "Daily"
        steps = Calendar.Steps(meta.FirstDay, meta.LastDay, mode == "Weekly")
        Feedback.AcceptedClick()
        moveTo(nearest(selectedDay), true)
    end)
    practiceButton.Activated:Connect(function()
        if practiceBusy or not practice then
            return
        end
        practiceBusy = true
        practiceButton.Interactable = false
        local ok, result = pcall(function()
            return remotes.SetPracticeMode:InvokeServer(not practice.Enabled)
        end)
        practiceBusy = false
        practiceButton.Interactable = true
        if not ok or type(result) ~= "table" or result.Error then
            Feedback.Error()
            practiceInfo.Text = type(result) == "table" and result.Error or UI.T("Progress", "PracticeFailed")
            return
        end
        Feedback.AcceptedClick()
        live = result
        updatePractice(result.Practice)
        if mode == "Daily" and meta and selectedDay == meta.Today then
            show(live)
        end
    end)
    panel:GetPropertyChangedSignal("Visible"):Connect(function()
        if not panel.Visible then
            requestSerial += 1
            endDrag(false)
        end
    end)
    local function responsive()
        if card:GetAttribute("AutoLayoutEnabled") == false then
            return
        end
        local narrow = card.AbsoluteSize.X < (card:GetAttribute("CompactBreakpoint") or 410)
        if not narrow then
            UI.RestoreLayout(savedLayout)
            return
        end
        card.Title.Size = UDim2.new(narrow and 0.48 or 0.5, -18, 0, 28)
        card.Title.TextSize = narrow and 15 or 19
        dateLabel.TextSize = narrow and 11 or 13
        modeButton.Size = UDim2.new(0, narrow and 128 or 154, 0, 32)
        modeButton.Position = UDim2.new(1, -(18 + (narrow and 128 or 154) / 2), 0, 59)
    end
    card:GetPropertyChangedSignal("AbsoluteSize"):Connect(responsive)
    responsive()
    return function(data)
        if type(data) ~= "table" then
            return
        end
        local followedToday = not meta or (mode == "Daily" and selectedDay == meta.Today)
        live = data
        meta = data.Progress or meta
        updatePractice(data.Practice)
        if not meta then
            render(data)
            return
        end
        if dragging then
            return
        end
        if mode == "Weekly" and not meta.WeeklyAvailable then
            mode = "Daily"
        end
        steps = Calendar.Steps(meta.FirstDay, meta.LastDay, mode == "Weekly")
        index = followedToday and #steps or nearest(selectedDay or meta.Today)
        draw()
        if not dragging then
            requestSelection()
        end
    end
end
return Controller
