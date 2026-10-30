-- CalmWorks: edit this file first when tuning the game.
local Config = {}

Config.GameName = "CalmWorks"
Config.StartingCash = 0
-- A solved scenario pays $10 per difficulty level, plus $10 for each current business star.
Config.RewardPerDifficulty = 10
Config.RewardPerStar = 10
-- Stars now come from four expansions, then completing the final stage.
Config.MaxStars = 5
Config.MaxQueueSize = 4

-- Each row is indexed by the player's current business rating. Array indexes
-- are scenario difficulties and values are relative selection weights.
-- 0-2 stars unlock difficulties 1-2; each later rating unlocks its matching
-- difficulty, with advanced cases becoming gradually more common.
Config.DifficultyWeightsByStars = {
    [0] = { 60, 40 },
    [1] = { 50, 50 },
    [2] = { 40, 60 },
    [3] = { 25, 35, 40 },
    [4] = { 15, 20, 28, 37 },
    [5] = { 10, 15, 20, 25, 30 },
}

-- Chance that an entire selected scenario uses free response instead of MCQ.
-- Higher-level multi-stage scenarios use FRQ at every stage when selected.
Config.FRQChanceByDifficulty = { [1] = 0, [2] = 0, [3] = 0.05, [4] = 0.10, [5] = 0.10 }
Config.FRQMaximumScenarioSeverity = 3 -- for generic Level 1-2 FRQs only
Config.FRQDefaultPrompt = "What is one safe, useful next step? A short answer is enough."
Config.FRQMinCharacters = 1 -- Require nonempty text; the grader judges meaning, not length.
Config.FRQMaxCharacters = 500
Config.FRQGradingCooldownSeconds = 5
Config.FRQGradingMaxTokens = 1400
-- Acceptance uses MinimumViable + safety checks, not the coaching/rubric score.
Config.FRQMaximumEscalationRisk = 45 -- Safety backstop, not a completeness/eloquence threshold.

-- Structured AI variations of the reviewed library. Prompts are editable on
-- ServerStorage > CalmWorksScenarioGenerator / CalmWorksScenarioReviewer /
-- CalmWorksScenarioAnswerChecker. These are constrained variations, not a trained model.
Config.AIScenarioEnabled = true
-- The current provider returns HTTP 400 for JsonSchema; local validation remains enabled.
Config.AIScenarioUseJsonSchema = false
Config.AIScenarioLoadingSeconds = 2 -- hard-capped to two seconds by the service
Config.AIScenarioPreparationSeconds = 45 -- background work while customers walk
Config.AIScenarioMaxConcurrent = 2
Config.AIScenarioMaximumSeverity = 3 -- sensitive/flagged cases stay curated
Config.AIScenarioMaxTokens = 1800
Config.AIScenarioReviewMaxTokens = 850
Config.AIScenarioChoiceLengthRatio = 1.65
Config.AIScenarioFailureLimit = 3
Config.AIScenarioCooldownSeconds = 30
Config.AIScenarioLogFallbacks = true -- one Output notice per customer ticket, no player text
Config.AdaptiveFormatBonus = 0.75 -- bounded by AdaptiveMaximumWeight below

-- Adaptive practice keeps the original star/difficulty distribution, then
-- favors categories where the player's answers show a need for practice.
Config.AdaptiveGoalAccuracy = 0.85
Config.AdaptiveMinSamples = 3
Config.AdaptiveRecentAnswers = 10
Config.AdaptiveMasteryCorrect = 10
Config.AdaptiveMasteryMistakes = 1
Config.AdaptiveFocusBonus = 0.8
Config.AdaptiveMaximumWeight = 3
Config.AdaptiveExplorationChance = 0.25

-- Editable skills-tracker window and recommendation thresholds.
Config.AccuracyWindowSize = 50
Config.ProgressCheckpointSeconds = 120
Config.ProgressRetentionDays = 3650 -- ten years of calendar history; compact daily snapshots
Config.PracticeMaximumCategoryStreak = 2
Config.RecommendationMinCategoryAnswers = 3
Config.RecommendationGap = 0.15
Config.RecommendationMaxFocusedCategories = 4
Config.RecommendationRepeatMistakes = 2
Config.RecommendationRepeatGap = 0.10 -- compare error rates, not just unequal exposure
Config.CustomerPromptMaxCharacters = 420

-- The requested production pacing. Turn TestMode on while building in Studio.
Config.TestMode = false
Config.SpawnTimeMin = 15
Config.SpawnTimeMax = 20
Config.TestSpawnTimeMin = 4
Config.TestSpawnTimeMax = 7
-- Random first arrival after claiming; the minimum is always at least 10 seconds.
Config.FirstCustomerDelay = 10
Config.FirstCustomerDelayMax = 15
Config.SpawnRatePerStar = 1.175

-- Variety stays within difficulty, practice and safety-compatible cases.
Config.ScenarioRecentWindow = 12
Config.CustomerRecentProfileWindow = 6
Config.SupportChatMemoryRefreshSeconds = 60
Config.SupportChatContextMessages = 8
Config.SupportChatTimelineDays = 14

-- Published servers save automatically. To test saving in Studio, enable
-- Game Settings > Security > Enable Studio Access to API Services, then set
-- SaveInStudio to true. Leave it false while ordinary playtesting.
-- New gameplay save version: one-time reset for the stage-based progression rework.
-- The old CalmWorksPlayerData_v1 store and separate support-chat history are preserved.
Config.DataStoreName = "CalmWorksPlayerData_StageRatings_v2"
Config.SaveInStudio = false
Config.AutoSaveSeconds = 15
Config.DataStoreRetries = 3
Config.DataSessionLeaseSeconds = 120
Config.DataSessionWaitSeconds = 20

-- Native Roblox TextGenerator support chat. The system prompt itself is
-- editable on ServerStorage > CalmWorksSupportGenerator.
Config.SupportChatEnabled = true
Config.SupportChatDataStoreName = "CalmWorksSupportChat_v1"
Config.SupportChatCooldownSeconds = 5
Config.SupportChatMaxInputCharacters = 280
Config.SupportChatMaxResponseTokens = 180
Config.SupportChatMaxHistoryMessages = 30
Config.SupportChatMaxSavedMessageCharacters = 1200
Config.SupportChatMaxContextTokenCharacters = 100000
Config.SupportChatAutosaveSeconds = 30

-- Roblox's classic R6 walk animation used by the blocky noob customers.
Config.R6WalkAnimationId = "rbxassetid://180426354"
Config.CustomerHairChance = 0.5

Config.PlotOrigin = Vector3.new(0, 0, 0)
Config.PlotSize = Vector3.new(64, 1, 52)

-- Upgrade prices and labels are editable Attributes on each Part under
-- Workspace > CalmWorksTycoon > Building > UpgradePads.

return Config
