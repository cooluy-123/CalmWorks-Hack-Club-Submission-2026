local SoundtrackConfig = {}

SoundtrackConfig.Enabled = true
-- Used only as a fallback if a song entry has no Volume field.
SoundtrackConfig.Volume = 0.2
SoundtrackConfig.FadeTime = 1.25
SoundtrackConfig.DelayBetweenSongs = 1
SoundtrackConfig.Shuffle = true

-- PER_SONG_VOLUME_V1
-- Edit each Volume independently (Roblox Sound.Volume supports 0 to 10).
-- The player's Music setting still scales the whole soundtrack SoundGroup.
SoundtrackConfig.Songs = {
	{ SoundId = "rbxassetid://140256481202851"},
	{ SoundId = "rbxassetid://140662085604483"},
	{ SoundId = "rbxassetid://140375962559637"},
	{ SoundId = "rbxassetid://140319470451829"},
	{ SoundId = "rbxassetid://115213314108382"},

}

return SoundtrackConfig