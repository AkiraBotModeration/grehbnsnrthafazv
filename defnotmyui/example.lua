
local LIBRARY_FOLDER = "Robloxui"

local function Warn(Message)
	if warn then
		warn("[EnterSkin] " .. Message)
	else
		print("[EnterSkin] " .. Message)
	end
end

local function FileNameOnly(Path)
	return tostring(Path or ""):match("[^/\\]+$") or tostring(Path or "")
end

-- Unload any previously loaded copy so re-running never stacks two UIs.
-- BOTH globals are unloaded: an old build exported both, and leaving one alive
-- would leave a zombie library competing for input and rendering.
for _, Name in ipairs({ "Library", "EnterSkin" }) do
	local Previous = getgenv()[Name]

	if Previous and type(Previous.Unload) == "function" then
		pcall(function()
			Previous:Unload()
		end)
	end

	getgenv()[Name] = nil
end

local Library = (function()

	local HasList = type(listfiles) == "function"
	local HasRead = type(readfile) == "function"

	if not HasList or not HasRead then
		Warn("this executor has no readfile/listfiles, cannot load from a folder")
		return nil
	end

	local Compile = loadstring or load

	if type(Compile) ~= "function" then
		Warn("no loadstring/load available in this executor")
		return nil
	end

	local ok, entries = pcall(listfiles, LIBRARY_FOLDER)

	if not ok or type(entries) ~= "table" then
		Warn("folder '" .. LIBRARY_FOLDER .. "' could not be read (does it exist?)")

		if type(makefolder) == "function" then
			pcall(makefolder, LIBRARY_FOLDER)
			Warn("created it - put the library .lua in there and re-run this file")
		end

		return nil
	end

	local candidates = { }
	local seen = { }

	local function AddCandidate(Path)
		if not Path or Path == "" then
			return
		end

		Path = tostring(Path):gsub("\\", "/")

		if seen[Path] then
			return
		end

		seen[Path] = true

		candidates[#candidates + 1] = Path
	end

	for _, entry in ipairs(entries) do
		local name = FileNameOnly(entry)

		if name:match("%.lua$") and not name:lower():match("^example") then
			AddCandidate(entry)
			AddCandidate(LIBRARY_FOLDER .. "/" .. name)
		end
	end

	if #candidates == 0 then
		Warn("no .lua files found in '" .. LIBRARY_FOLDER .. "' (saw "
			.. #entries .. " entr" .. (#entries == 1 and "y" or "ies") .. ")")
		return nil
	end

	local failures = { }

	for _, path in ipairs(candidates) do
		local okRead, source = pcall(readfile, path)

		if okRead and type(source) == "string" and #source > 0 then
			local okLoad, chunk = pcall(Compile, source, "@" .. path)

			if okLoad and type(chunk) == "function" then
				local okRun, result = pcall(chunk)

				if okRun and getgenv().Library then
					return getgenv().Library
				end

				if okRun and type(result) == "table" and result.Window then
					return result
				end

				failures[#failures + 1] = path .. " -> " .. tostring(result):sub(1, 120)
			else
				failures[#failures + 1] = path .. " -> " .. tostring(chunk):sub(1, 120)
			end
		else
			failures[#failures + 1] = path .. " -> unreadable"
		end
	end

	Warn("found " .. #candidates .. " candidate(s) but none could be loaded:")
	for _, failure in ipairs(failures) do
		Warn("  " .. failure)
	end

	return nil
end)()

if not Library then
	return
end

local Window = Library:Create({
	Name = "EnterSkin",
	MenuKeybind = "RightControl",
	Open = true,
	Watermark = false,
	KeybindList = false,
	Settings = false,
	Blur = true,
	BlurSize = 24
})

local Watermark = Library:Watermark(Window.Name)
local KeybindList = Library:KeybindList()


local MobileButton = Library:MobileButton({
	Window = Window,
	Position = "MiddleLeft",
	SnapToEdge = true
})

Library:Notification("Loaded", "EnterSkin example is ready.", 5, "Success")

do
	local Page = Window:Page({ Name = "Main", Icon = "Home", Columns = 2 })

	do
		local Section = Page:Section({ Name = "Animated Text & FX", Side = 1 })

		Section:AnimatedText({
			Name = "Typewriter Text",
			Texts = {
				"EnterSkin v2.0 - Premium Luau UI Library",
				"Typewriter, Rainbow & Gradient Animations",
				"Custom Discord & Image Backgrounds",
				"UI Lock & Edge-Snapping Mobile Dock"
			},
			Type = "Typing",
			Speed = 1
		})

		Section:AnimatedText({
			Name = "Rainbow Chroma",
			Text = "Rainbow Chromatic Flowing Text",
			Type = "Rainbow",
			Speed = 1.2
		})

		Section:AnimatedText({
			Name = "Aurora Gradient",
			Text = "Cyber Aurora Shifting Gradient",
			Type = "Gradient",
			Speed = 1.4
		})
	end

	do
		local Section = Page:Section({ Name = "Booleans", Side = 1 })

		Section:Toggle({ Name = "Toggle", Flag = "Main_Toggle", Default = true })
		Section:Checkbox({ Name = "Checkbox", Flag = "Main_Checkbox", Default = true })
		Section:Segmented({ Name = "Segmented", Flag = "Main_Segmented", Items = { "One", "Two", "Three" }, Default = "Two" })
		Section:RadioList({ Name = "Radio list", Flag = "Main_Radio", Items = { "First", "Second", "Third" }, Default = "Second" })
	end

	do
		local Section = Page:Section({ Name = "Numbers", Side = 2 })

		Section:Slider({ Name = "Slider", Flag = "Main_Slider", Min = 0, Max = 100, Default = 50, Suffix = "%" })
		Section:RangeSlider({ Name = "Range slider", Flag = "Main_Range", Min = 0, Max = 100, Default = { Low = 25, High = 75 } })
		Section:NumberInput({ Name = "Number input", Flag = "Main_Number", Min = 0, Max = 100, Default = 25, Step = 5 })
	end

	do
		local Section = Page:Section({ Name = "Choices", Side = 1 })

		Section:Dropdown({ Name = "Dropdown", Flag = "Main_Dropdown", Items = { "Alpha", "Bravo", "Charlie" }, Default = "Bravo" })
		Section:Dropdown({ Name = "Searchable", Flag = "Main_DropdownSearch", Search = true, Items = { "Assault", "Sniper", "Shotgun", "SMG" }, Default = "Sniper" })
		Section:ToggleDropdown({ Name = "Multi select", Flag = "Main_Multi", Items = { "Head", "Torso", "Arms" }, Multi = true })
	end

	do
		local Section = Page:Section({ Name = "Text", Side = 2 })

		Section:Textbox({ Name = "Textbox", Flag = "Main_Textbox", Placeholder = "type here.." })
		Section:MultilineTextbox({ Name = "Multiline", Flag = "Main_Multiline", Placeholder = "multiple\nlines.." })
		Section:Label("Colour picker", "Left"):Colorpicker({ Name = "Colour picker", Flag = "Main_Colour", Default = Color3.fromRGB(59, 130, 246) })
		Section:Label("Gradient picker", "Left"):Colorpicker({
			Name = "Gradient picker",
			Flag = "Main_Gradient_Colour",
			Gradient = true,
			Default = Color3.fromRGB(59, 130, 246),
			Default2 = Color3.fromRGB(236, 72, 153),
			GradientRotation = 45
		})
		Section:Label("Keybind", "Left"):Keybind({ Name = "Keybind", Flag = "Main_Keybind", Default = Enum.KeyCode.End, Mode = "Toggle" })
	end

	do
		local Section = Page:Section({ Name = "Buttons", Side = 1 })

		local Btn = Section:Button({ Name = "Button" })
		Btn:Add("Click me", function()
			Library:Notification("Button Pressed", "Primary button action fired!", 2, "Info")
		end, false)
		Btn:Add("Reset", function()
			Library:Notification("Reset Confirmed", "Destructive action confirmed!", 2, "Warning")
		end, "Are you sure?")

		Section:HoldButton({
			Name = "Hold to Execute",
			Duration = 1.5,
			Callback = function()
				Library:Notification("Hold Completed", "Action executed after hold!", 2, "Success")
			end
		})
	end

	do
		local Section = Page:Section({ Name = "Display", Side = 2 })

		Section:Progress({ Name = "Progress", Flag = "Main_Progress", Max = 100, Default = 60, Suffix = "%" })
		Section:Listbox({
			Name = "Listbox",
			Flag = "Main_List",
			Rows = 4,
			Items = { "Player one", "Player two", "Player three", "Player four", "Player five" }
		})
	end

	do
		local Section = Page:Section({ Name = "Accordion", Side = 1 })

		local Accordion = Section:Accordion({ Name = "Open me", Default = true })

		Accordion:Toggle({ Name = "Inside", Flag = "Main_Acc_Toggle", Default = true })
		Accordion:Slider({ Name = "Also inside", Flag = "Main_Acc_Slider", Min = 0, Max = 100, Default = 40 })
	end

	do
		local Section = Page:Section({ Name = "Group", Side = 2 })

		local Group = Section:Group({ Name = "Grouped", Flag = "Main_Group", Default = true })

		Group:Checkbox({ Name = "Inside group", Flag = "Main_Group_Checkbox", Default = true })
		Group:Toggle({ Name = "Also inside", Flag = "Main_Group_Toggle", Default = false })
	end

	do
		local Section = Page:Section({ Name = "About", Side = 2 })

		Section:Label("One of every element, laid out as a plain gallery.", "Left")
	end

	do
		local Section = Page:CollapsibleSection({ Name = "Collapsible", Side = 1 })

		Section:Toggle({ Name = "Hidden until opened", Flag = "Main_Coll_Toggle" })
	end

	do
		local Sphere = Instance.new("Part")
		Sphere.Name = "Preview"
		Sphere.Shape = Enum.PartType.Ball
		Sphere.Size = Vector3.new(2, 2, 2)
		Sphere.Material = Enum.Material.SmoothPlastic
		Sphere.Color = Color3.fromRGB(59, 130, 246)
		Sphere.Anchored = true
		Sphere.Transparency = 1
		Sphere.CanCollide = false
		Sphere.Parent = workspace

		Page:ViewportSection({ Name = "Viewport", Side = 2, Part = Sphere })

		Sphere:Destroy()
	end
end

do
	local Page = Window:Page({ Name = "Combat", Icon = "Sword" })

	local AimbotTab = Page:SubTab({ Name = "Aimbot", Columns = 2 })
	do
		local Section1 = AimbotTab:Section({ Name = "Aimbot Settings", Side = 1 })
		local Toggle = Section1:Toggle({ Name = "Enable Aimbot", Flag = "Aimbot_Enabled", Default = true })
		Toggle:Keybind({ Name = "Keybind", Flag = "Aimbot_Key", Default = Enum.KeyCode.E, Mode = "Hold" })
		Toggle:Colorpicker({ Name = "FOV Color", Flag = "Aimbot_FOV_Color", Default = Color3.fromRGB(59, 130, 246) })
		Section1:Dropdown({ Name = "Target Part", Flag = "Aimbot_Part", Items = { "Head", "Torso", "HumanoidRootPart" }, Default = "Head" })
		Section1:Slider({ Name = "Smoothness", Flag = "Aimbot_Smooth", Min = 1, Max = 20, Default = 5 })
		Section1:Slider({ Name = "Field of View", Flag = "Aimbot_FOV", Min = 10, Max = 360, Default = 90 })

		local Section2 = AimbotTab:Section({ Name = "Prediction & Checks", Side = 2 })
		Section2:Toggle({ Name = "Prediction", Flag = "Aimbot_Pred", Default = true })
		Section2:Toggle({ Name = "Wall Check", Flag = "Aimbot_WallCheck", Default = true })
		Section2:Toggle({ Name = "Team Check", Flag = "Aimbot_TeamCheck", Default = false })
		Section2:Slider({ Name = "Prediction Factor", Flag = "Aimbot_PredFactor", Min = 0.01, Max = 0.5, Step = 0.01, Default = 0.13 })
	end

	local TriggerTab = Page:SubTab({ Name = "Triggerbot", Columns = 2 })
	do
		local Section1 = TriggerTab:Section({ Name = "Triggerbot Settings", Side = 1 })
		Section1:Toggle({ Name = "Enable Triggerbot", Flag = "Trigger_Enabled", Default = false })
		Section1:Slider({ Name = "Reaction Delay", Flag = "Trigger_Delay", Min = 0, Max = 500, Default = 50, Suffix = "ms" })
		Section1:ToggleDropdown({ Name = "Hitboxes", Flag = "Trigger_Hitboxes", Items = { "Head", "Torso", "Arms", "Legs" }, Multi = true })

		local Section2 = TriggerTab:Section({ Name = "Weapon Filters", Side = 2 })
		Section2:Checkbox({ Name = "Snipers Only", Flag = "Trigger_Snipers", Default = false })
		Section2:Checkbox({ Name = "Pistols", Flag = "Trigger_Pistols", Default = true })
	end

	local SilentTab = Page:SubTab({ Name = "Silent Aim", Columns = 2 })
	do
		local Section1 = SilentTab:Section({ Name = "Silent Aim Settings", Side = 1 })
		local Toggle = Section1:Toggle({ Name = "Enable Silent Aim", Flag = "Silent_Enabled", Default = true })
		Toggle:Colorpicker({ Name = "Tracer Color", Flag = "Silent_TracerColor", Default = Color3.fromRGB(255, 75, 75) })
		Section1:Slider({ Name = "Hit Chance", Flag = "Silent_HitChance", Min = 0, Max = 100, Default = 100, Suffix = "%" })
		Section1:Dropdown({ Name = "Target Mode", Flag = "Silent_Mode", Items = { "Closest to Crosshair", "Lowest Health", "Distance" }, Default = "Closest to Crosshair" })

		local Section2 = SilentTab:Section({ Name = "Visualizations", Side = 2 })
		Section2:Toggle({ Name = "Draw FOV", Flag = "Silent_DrawFOV", Default = true })
		Section2:Toggle({ Name = "Bullet Tracers", Flag = "Silent_Tracers", Default = true })
	end
end

do
	local Page = Window:Page({ Name = "Visuals", Icon = "Eye", Columns = 2 })

	local EspTab = Page:SubTab({ Name = "ESP", Columns = 2 })
	do
		local Section1 = EspTab:Section({ Name = "Player ESP", Side = 1 })
		local Box = Section1:Checkbox({ Name = "Boxes", Flag = "ESP_Boxes", Default = true })
		Box:Colorpicker({ Name = "Box Color", Flag = "ESP_Box_Color", Default = Color3.fromRGB(59, 130, 246) })
		local NameEsp = Section1:Checkbox({ Name = "Names", Flag = "ESP_Names", Default = true })
		NameEsp:Colorpicker({ Name = "Name Color", Flag = "ESP_Name_Color", Default = Color3.fromRGB(255, 255, 255) })
		Section1:Checkbox({ Name = "Health Bars", Flag = "ESP_Health", Default = true })
		Section1:Checkbox({ Name = "Distance", Flag = "ESP_Distance", Default = false })

		local Section2 = EspTab:Section({ Name = "Chams & Glow", Side = 2 })
		local Chams = Section2:Checkbox({ Name = "Player Chams", Flag = "ESP_Chams", Default = false })
		Chams:Colorpicker({
			Name = "Chams Color",
			Flag = "ESP_Chams_Color",
			Gradient = true,
			Default = Color3.fromRGB(139, 92, 246),
			Default2 = Color3.fromRGB(236, 72, 153)
		})
		Section2:Slider({ Name = "Glow Intensity", Flag = "ESP_Glow", Min = 0, Max = 100, Default = 50, Suffix = "%" })
	end

	local WorldTab = Page:SubTab({ Name = "World", Columns = 2 })
	do
		local Section1 = WorldTab:Section({ Name = "Lighting", Side = 1 })
		Section1:Checkbox({ Name = "Fullbright", Flag = "World_Fullbright", Default = false })
		Section1:Checkbox({ Name = "No Fog", Flag = "World_NoFog", Default = true })
		Section1:Slider({ Name = "Field of View", Flag = "World_FOV", Min = 70, Max = 120, Default = 90 })

		local Section2 = WorldTab:Section({ Name = "Ambience", Side = 2 })
		local Ambient = Section2:Checkbox({ Name = "Custom Ambient", Flag = "World_Ambient", Default = false })
		Ambient:Colorpicker({ Name = "Ambient Color", Flag = "World_Ambient_Color", Default = Color3.fromRGB(80, 80, 100) })
	end
end

do
	local Page = Window:Page({ Name = "Players", Icon = "Users", Columns = 2 })
	do
		local Section1 = Page:Section({ Name = "Player List", Side = 1 })
		Section1:Listbox({
			Name = "Online Players",
			Flag = "Players_Online",
			Rows = 6,
			Items = { "Astolfo (You)", "xX_Sniper_Xx", "ShadowNinja", "GhostRider", "CyberSamurai" }
		})
		local Actions = Section1:Button({ Name = "Actions" })
		Actions:Add("Teleport", function()
			Library:Notification("Teleport", "Teleporting to target...", 2, "Info")
		end, false)
		Actions:Add("Spectate", function()
			Library:Notification("Spectate", "Now spectating player", 2, "Info")
		end, false)

		local Section2 = Page:Section({ Name = "Player Actions", Side = 2 })
		Section2:Checkbox({ Name = "Loop Teleport", Flag = "Players_LoopTP", Default = false })
		Section2:Checkbox({ Name = "Attach to Player", Flag = "Players_Attach", Default = false })
		local DangerBtn = Section2:Button({ Name = "Danger" })
		DangerBtn:Add("Fling Target", function()
			Library:Notification("Fling", "Fling action initiated!", 2, "Warning")
		end, "Confirm fling?")
	end
end

Library:CreateSettingsPage(Window, Watermark, KeybindList)

-- ==========================================================================
-- TEST PAGE
-- Everything here exists to make regressions visible at a glance.
-- ==========================================================================
do
	local Page = Window:Page({ Name = "Tests", Icon = "Sliders", Columns = 2 })

	local function MakeItems(Count, Prefix)
		local Result = { }
		for Index = 1, Count do
			Result[Index] = (Prefix or "Option") .. " " .. Index
		end
		return Result
	end

	do
		local Section = Page:Section({ Name = "Dropdown: option counts", Side = 1 })
		Section:Label("Open each one. The long lists must scroll cleanly with no white blocks.", "Left")

		-- 3 / 8 / 20 / 40 options: the counts that previously exposed the
		-- FadeHolder off-screen branch that turned rows into opaque white bars.
		Section:Dropdown({ Name = "3 options",  Flag = "Test_D3",  Items = MakeItems(3),  Default = "Option 2" })
		Section:Dropdown({ Name = "8 options",  Flag = "Test_D8",  Items = MakeItems(8),  Default = "Option 5" })
		Section:Dropdown({ Name = "20 options", Flag = "Test_D20", Items = MakeItems(20), Default = "Option 14" })
		Section:Dropdown({ Name = "40 options", Flag = "Test_D40", Items = MakeItems(40), Default = "Option 31" })
		Section:Dropdown({ Name = "20 + search", Flag = "Test_D20S", Search = true, Items = MakeItems(20), Default = "Option 6" })
		Section:ToggleDropdown({ Name = "20 multi", Flag = "Test_D20M", Multi = true, Items = MakeItems(20) })
	end

	do
		local Section = Page:Section({ Name = "Dropdown: edge placement", Side = 2 })
		Section:Label("These sit at the top and bottom of the page to test on-screen flipping.", "Left")

		local Top = MakeItems(12, "Top")
		local Bottom = MakeItems(12, "Bottom")

		Section:Dropdown({ Name = "Upper half", Flag = "Test_DUp", Items = Top, Default = "Top 4" })
		local Filler = Section:Accordion({ Name = "Filler (pushes the next dropdown down)", Default = false })
		for Index = 1, 6 do
			Filler:Toggle({ Name = "Filler " .. Index, Flag = "Test_Fill" .. Index })
		end
		Section:Dropdown({ Name = "Lower half", Flag = "Test_DLow", Items = Bottom, Default = "Bottom 9" })
	end

	do
		local Section = Page:Section({ Name = "Sliders: every range shape", Side = 1 })
		Section:Label("Decimals should appear only where the range needs them.", "Left")

		Section:Slider({ Name = "0 to 1",     Flag = "Test_S01",  Min = 0, Max = 1, Default = 0.35 })
		Section:Slider({ Name = "0 to 100",   Flag = "Test_S100", Min = 0, Max = 100, Default = 42, Suffix = "%" })
		Section:Slider({ Name = "-1 to 1",    Flag = "Test_SN1",  Min = -1, Max = 1, Default = -0.45 })
		Section:Slider({ Name = "0.0 to 0.5", Flag = "Test_S005", Min = 0, Max = 0.5, Default = 0.125 })
		Section:Slider({ Name = "step 0.05",  Flag = "Test_SS",   Min = 0, Max = 1, Step = 0.05, Default = 0.35 })
		Section:Slider({ Name = "step 5",     Flag = "Test_S5",   Min = 0, Max = 100, Step = 5, Default = 40 })
		-- Inverted and zero-span used to throw "max must be >= min" / divide by zero.
		Section:Slider({ Name = "inverted",   Flag = "Test_SInv", Min = 1, Max = 0, Default = 0.75 })
		Section:Slider({ Name = "zero span",  Flag = "Test_SZero", Min = 5, Max = 5, Default = 0.5 })
		Section:NumberInput({ Name = "Number 0-1", Flag = "Test_N01", Min = 0, Max = 1, Default = 0.5 })
	end

	do
		local Section = Page:Section({ Name = "Configs", Side = 2 })
		Section:Label("Save, then reload the script: the values above should come back.", "Left")

		local NameBox = ""
		Section:Textbox({
			Name = "Config name",
			Flag = "Test_ConfigName",
			Placeholder = "my-profile",
			Callback = function(Value)
				NameBox = Value
			end
		})

		local Saved, Loaded = 0, 0

		Section:Button():Add("Save config", function()
			local Ok, Result = Library:SaveConfig(NameBox ~= "" and NameBox or "example")
			if Ok then
				Saved += 1
				Library:Notification("Config", "Saved (" .. tostring(Result) .. ")", 3, "Success")
			end
		end, false)

		Section:Button():Add("Load config", function()
			local Ok, Applied = Library:LoadConfig(NameBox ~= "" and NameBox or "example")
			if Ok then
				Loaded += 1
				Library:Notification("Config", "Loaded " .. tostring(Applied) .. " settings", 3, "Success")
			end
		end, false)

		Section:Button():Add("Auto load now", function()
			local Ok, Reason = Library:AutoLoadConfig()
			Library:Notification("Config", tostring(Ok) .. " / " .. tostring(Reason), 3, Ok and "Success" or "Warning")
		end, false)

		Section:Button():Add("Refresh list", function()
			local List = Library:RefreshConfigsList(nil, true)
			Library:Notification("Config", #List .. " config(s) on disk", 3, "Info")
		end, false)

		Section:Button():Add("Report", function()
			local Info = Library:GetStats()
			Library:Notification("Stats", string.format(
				"fps %s  framejob %sms  dropdowns %d  configs %d",
				tostring(Info.FPS), tostring(Info.FrameJobMs),
				#(Library.PopupFrames or {}), #Library:GetConfigList(true)
			), 6, "Info")
		end, false)
	end

	do
		local Section = Page:Section({ Name = "Toggles & booleans", Side = 1 })
		Section:Toggle({ Name = "Toggle",        Flag = "Test_T",    Default = true })
		Section:Toggle({ Name = "Toggle off",    Flag = "Test_T2",   Default = false })
		Section:Checkbox({ Name = "Checkbox",    Flag = "Test_C",    Default = true })
		Section:Segmented({ Name = "Segmented",   Flag = "Test_Seg",  Items = { "One", "Two", "Three" }, Default = "Two" })
		Section:RadioList({ Name = "Radio list",  Flag = "Test_Rad",  Items = { "First", "Second", "Third" }, Default = "Second" })
	end

	do
		local Section = Page:Section({ Name = "Colour & keybind", Side = 2 })
		local Swatches = { }
		for Index = 1, 24 do
			Swatches[Index] = string.format("#%02X%02X%02X", (Index * 11) % 256, (Index * 29) % 256, (Index * 47) % 256)
		end
		Section:Dropdown({ Name = "24 colours", Flag = "Test_Col", Items = Swatches, Default = Swatches[1] })
		Section:Label("Colour picker", "Left"):Colorpicker({ Name = "Colour picker", Flag = "Test_CP", Default = Color3.fromRGB(59, 130, 246) })
		Section:Label("Keybind", "Left"):Keybind({ Name = "Keybind", Flag = "Test_KB", Default = Enum.KeyCode.End, Mode = "Toggle" })
	end
end

do
	local Pages = Window.Pages
	local SettingsPage

	for _, Page in ipairs(Pages) do
		if Page.Name == "Settings" then
			SettingsPage = Page
		end
	end

	if SettingsPage then
		local Section = SettingsPage:Section({ Name = "Mobile button", Side = 1 })

		Section:Dropdown({
			Name = "Position",
			Flag = "MobileButtonPosition",
			Default = "MiddleLeft",
			Search = true,
			Items = { "TopLeft", "TopRight", "MiddleLeft", "Center", "MiddleRight", "BottomLeft", "BottomRight" },
			Callback = function(Value)
				MobileButton:SetPosition(Value)
			end
		})

		Section:Toggle({
			Name = "Locked",
			Flag = "MobileButtonLocked",
			Default = false,
			Callback = function(Value)
				MobileButton:SetLocked(Value)
			end
		})

		Section:Toggle({
			Name = "Visible",
			Flag = "MobileButtonVisible",
			Default = true,
			Callback = function(Value)
				MobileButton:SetVisible(Value)
			end
		})

		Section:Toggle({
			Name = "Snap to edge",
			Flag = "MobileButtonSnap",
			Default = true,
			Callback = function(Value)
				MobileButton:SetSnapToEdge(Value)
			end
		})
	end
end
