-- Reviewed compatibility tags for all 100 library references. Edit lists, not the scenario answer keys.
-- These select the closest eligible preset AFTER difficulty, format and adaptive category selection.
local Catalog = {}
local categoryTraits = {
    EVC = {
        Personalities = { "Direct", "Perfectionistic", "Analytical", "Competitive", "Impatient" },
        Styles = { "Brief", "Logical", "Uncertain" },
    },
    PSC = {
        Personalities = { "Sensitive", "ConflictAverse", "PeoplePleasing", "Competitive", "Impulsive" },
        Styles = { "Emotional", "Indirect", "Detailed" },
    },
    COM = {
        Personalities = { "Analytical", "Reserved", "Talkative", "EmotionDriven", "Direct" },
        Styles = { "Uncertain", "Logical", "Detailed" },
    },
    BND = {
        Personalities = { "ConflictAverse", "PeoplePleasing", "Reserved", "Sensitive", "Stubborn" },
        Styles = { "Brief", "Indirect", "Emotional" },
    },
    CSV = {
        Personalities = { "Direct", "Impatient", "Perfectionistic", "Skeptical", "Talkative" },
        Styles = { "Brief", "Detailed", "Logical" },
    },
    DIG = {
        Personalities = { "Skeptical", "Sensitive", "Impulsive", "Analytical", "Avoidant" },
        Styles = { "Uncertain", "Detailed", "Emotional" },
    },
    MNC = {
        Personalities = { "PeoplePleasing", "Skeptical", "ConflictAverse", "Avoidant", "Analytical" },
        Styles = { "Uncertain", "Indirect", "Logical" },
    },
    FAM = {
        Personalities = { "Sensitive", "EmotionDriven", "Reserved", "ConflictAverse", "Stubborn" },
        Styles = { "Emotional", "Detailed", "Indirect" },
    },
    PWC = {
        Personalities = { "Direct", "Competitive", "Impatient", "Analytical", "Stubborn" },
        Styles = { "Brief", "Logical", "Confrontational" },
    },
    SCJ = {
        Personalities = { "Direct", "Reserved", "Analytical", "Sensitive" },
        Styles = { "Brief", "Logical", "Uncertain" },
    },
}
local moodsByCategory = {
    EVC = {
        { "Calm", "Annoyed", "Confused" },
        { "Annoyed", "Calm" },
        { "Annoyed", "Confused", "Defensive" },
        { "Frustrated", "Annoyed", "Embarrassed" },
        { "Frustrated", "Annoyed" },
        { "Frustrated", "Hurt", "Suspicious" },
        { "Confused", "Suspicious", "Defensive" },
        { "Frustrated", "Annoyed", "Calm" },
        { "Suspicious", "Frustrated", "Confused" },
        { "Ashamed", "Anxious", "Confused" },
    },
    PSC = {
        { "Anxious", "Annoyed", "Confused" },
        { "Hurt", "Confused" },
        { "Embarrassed", "Hurt", "Anxious" },
        { "Defensive", "Embarrassed", "Hurt" },
        { "Angry", "Frustrated", "Hurt" },
        { "Anxious", "Confused" },
        { "Hurt", "Suspicious", "Confused" },
        { "Hurt", "Frustrated", "Angry" },
        { "Anxious", "Hurt", "Defensive" },
        { "Defensive", "Anxious", "Frustrated" },
    },
    COM = {
        { "Confused", "Annoyed" },
        { "Hurt", "Annoyed", "Calm" },
        { "Confused", "Defensive" },
        { "Confused", "Anxious" },
        { "Suspicious", "Hurt", "Confused" },
        { "Hurt", "Suspicious", "Confused" },
        { "Confused", "Frustrated", "Ashamed" },
        { "Defensive", "Confused", "Frustrated" },
        { "Ashamed", "Embarrassed", "Defensive" },
        { "Anxious", "Ashamed", "Confused" },
    },
    BND = {
        { "Calm", "Anxious" },
        { "Embarrassed", "Calm" },
        { "Annoyed", "Embarrassed" },
        { "Anxious", "Confused" },
        { "Frustrated", "Anxious" },
        { "Anxious", "Calm" },
        { "Suspicious", "Frustrated", "Anxious" },
        { "Anxious", "Hurt", "Defensive" },
        { "Anxious", "Hurt", "Angry" },
        { "Frustrated", "Anxious", "Suspicious" },
    },
    CSV = {
        { "Calm", "Annoyed", "Confused" },
        { "Annoyed", "Frustrated" },
        { "Calm", "Confused" },
        { "Frustrated", "Annoyed" },
        { "Embarrassed", "Defensive", "Calm" },
        { "Frustrated", "Confused" },
        { "Frustrated", "Anxious" },
        { "Suspicious", "Frustrated" },
        { "Anxious", "Frustrated" },
        { "Suspicious", "Frustrated", "Confused" },
    },
    DIG = {
        { "Annoyed", "Hurt", "Calm" },
        { "Confused", "Hurt" },
        { "Embarrassed", "Hurt" },
        { "Frustrated", "Annoyed" },
        { "Anxious", "Angry", "Confused" },
        { "Defensive", "Frustrated", "Hurt" },
        { "Angry", "Suspicious", "Hurt" },
        { "Anxious", "Embarrassed" },
        { "Defensive", "Anxious", "Frustrated" },
        { "Anxious", "Suspicious", "Hurt" },
    },
    MNC = {
        { "Anxious", "Confused" },
        { "Confused", "Anxious" },
        { "Anxious", "Embarrassed" },
        { "Embarrassed", "Anxious" },
        { "Confused", "Suspicious", "Hurt" },
        { "Anxious", "Suspicious", "Confused" },
        { "Anxious", "Embarrassed", "Panicked" },
        { "Defensive", "Hurt", "Anxious" },
        { "Anxious", "Embarrassed", "Panicked" },
        { "Confused", "Anxious", "Suspicious" },
    },
    FAM = {
        { "Annoyed", "Frustrated" },
        { "Confused", "Defensive" },
        { "Anxious", "Confused" },
        { "Hurt", "Confused", "Defensive" },
        { "Frustrated", "Hurt" },
        { "Hurt", "Embarrassed", "Defensive" },
        { "Hurt", "Angry", "Suspicious" },
        { "Hurt", "Frustrated", "Anxious" },
        { "Anxious", "Hurt" },
        { "Anxious", "Hurt", "Panicked" },
    },
    PWC = {
        { "Annoyed", "Calm" },
        { "Annoyed", "Calm" },
        { "Frustrated", "Hurt" },
        { "Annoyed", "Frustrated" },
        { "Angry", "Frustrated" },
        { "Frustrated", "Anxious" },
        { "Anxious", "Angry", "Panicked" },
        { "Defensive", "Frustrated", "Anxious" },
        { "Panicked", "Anxious" },
        { "Anxious", "Suspicious" },
    },
    SCJ = {
        { "Anxious", "Panicked", "Calm" },
        { "Anxious", "Suspicious" },
        { "Panicked", "Anxious" },
        { "Anxious", "Panicked" },
        { "Anxious", "Suspicious" },
        { "Anxious", "Hurt" },
        { "Panicked", "Anxious" },
        { "Anxious", "Hurt" },
        { "Anxious", "Confused" },
        { "Anxious", "Panicked", "Calm" },
    },
}
for category, rows in pairs(moodsByCategory) do
    for index, moods in ipairs(rows) do
        Catalog[string.format("CW3-%s-%02d", category, index)] = {
            Moods = moods,
            Personalities = table.clone(categoryTraits[category].Personalities),
            Styles = table.clone(categoryTraits[category].Styles),
        }
    end
end
-- Explicit prompt-compatible traits for sensitive cases; no aggressive customer styling.
Catalog["CW3-EVC-05"].Personalities = { "Competitive", "Controlling", "Direct", "Stubborn" }
for _, id in ipairs({
    "CW3-MNC-07",
    "CW3-MNC-09",
    "CW3-MNC-10",
    "CW3-FAM-09",
    "CW3-FAM-10",
    "CW3-DIG-08",
    "CW3-DIG-10",
    "CW3-PWC-09",
    "CW3-PWC-10",
}) do
    Catalog[id].Personalities = { "Reserved", "Sensitive", "Analytical", "ConflictAverse" }
    Catalog[id].Styles = { "Brief", "Uncertain", "Logical" }
end
-- Reviewed low-level frustrations can use an angry tone without adding danger.
for _, id in ipairs({
    "CW3-EVC-01",
    "CW3-EVC-02",
    "CW3-EVC-03",
    "CW3-EVC-04",
    "CW3-PSC-01",
    "CW3-COM-01",
    "CW3-COM-02",
    "CW3-BND-03",
    "CW3-CSV-01",
    "CW3-CSV-02",
    "CW3-CSV-04",
    "CW3-DIG-01",
    "CW3-DIG-04",
    "CW3-FAM-01",
    "CW3-PWC-01",
    "CW3-PWC-02",
    "CW3-PWC-03",
    "CW3-PWC-04",
}) do
    table.insert(Catalog[id].Moods, "Angry")
end

return Catalog
