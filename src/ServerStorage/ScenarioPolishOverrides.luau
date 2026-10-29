-- Focused wording audit. IDs, answer keys, scores, difficulty and safety metadata stay unchanged.
local revisions = {
    ["CW3-EVC-07"] = {
        Feedback = "Checking the uncertain facts together protects the friendship and avoids assigning a cost before responsibility is clear.",
        Stages = {
            {
                Prompt = "I lent my headphones to a friend last week. I cannot find them, but my friend says they already returned them. Neither of us has checked where they might have been put.",
                Choices = {
                    "Compare our memories and check likely places together before deciding whether either person needs to replace them.",
                    "Ask my friend to arrange a temporary replacement while we leave the question of responsibility for another day.",
                    "Borrow another pair for now and reassure my friend that I will cover the loss rather than question their memory.",
                },
                ChoiceFeedback = {
                    "This combines a practical search with a neutral conversation, without treating either person's uncertain memory as proof.",
                    "A temporary replacement could help with the immediate inconvenience. It still puts the task on your friend before you have checked the facts together; the stronger response addresses that uncertainty first.",
                    "Borrowing another pair avoids an argument and may be useful today. Taking the whole loss immediately leaves the uncertainty unresolved; a shared search could protect both your money and the friendship.",
                },
            },
            {
                Prompt = "My friend remembers leaving them on my desk, while I remember putting other items away that day. We now have a specific place to start looking.",
                Choices = {
                    "Suggest splitting the replacement cost now so neither of us carries the entire loss while our memories remain uncertain.",
                    "Retrace that day together, checking the desk, bags, and shared spaces before deciding who should cover a replacement.",
                    "Agree to discuss sharing the cost if they remain missing, and wait a few days before investigating any further.",
                },
                ChoiceFeedback = {
                    "Sharing a cost can be a fair fallback. Here, a specific lead is still untested; checking it first may avoid charging either person unnecessarily.",
                    "Following the new lead before allocating costs combines evidence, fairness, and a concrete action.",
                    "A shared-cost fallback is reasonable. The missing step is acting on the desk lead now; waiting adds delay without resolving the uncertainty.",
                },
            },
        },
    },
    ["CW3-EVC-09"] = {
        Feedback = "The stronger plan separates an agreed ticket price from an unagreed fee, rather than treating compromise or reimbursement as automatic.",
        Stages = {
            {
                Prompt = "I bought two event tickets after a friend said they would pay me back. They now say they agreed to only part of the price. We still have our messages, but have not reviewed them together.",
                Choices = {
                    "Ask for the amount I remember agreeing on, offering a flexible payment schedule while we settle the difference later.",
                    "Review the messages together to establish the agreed amount, then discuss how repayment can work for both of us.",
                    "Offer to divide the disputed amount equally so we can settle quickly without revisiting the details of our messages.",
                },
                ChoiceFeedback = {
                    "A flexible schedule is considerate if timing is the problem. The disagreement is about the amount itself, so checking the agreement first avoids negotiating from an unverified assumption.",
                    "Reviewing the agreement first distinguishes what is owed from when repayment is manageable.",
                    "Splitting the difference can preserve goodwill when evidence is unavailable. Here there is a record to review; an immediate compromise may override what you actually agreed.",
                },
            },
            {
                Prompt = "The messages confirm the ticket price, but neither of us discussed an added service fee. My friend is willing to pay the agreed price and asks what would be fair about the fee.",
                Choices = {
                    "Accept the agreed ticket price and cover the entire fee myself, keeping the repayment conversation simple and quick.",
                    "Add the entire service fee to their repayment, treating the booking cost as their responsibility despite the missing agreement.",
                    "Keep the agreed ticket price separate and discuss a voluntary, fair arrangement for the fee neither of us anticipated.",
                },
                ChoiceFeedback = {
                    "Covering the fee yourself is a reasonable option if you can afford it and choose freely. It is less complete because it skips discussing a shared unexpected cost before you take it all on.",
                    "The fee was not part of the agreement. Unilaterally adding it changes the terms; discussing it separately respects consent and keeps the confirmed price clear.",
                    "This honors the agreement while leaving room to negotiate an unexpected cost, without assuming either person must accept a new charge.",
                },
            },
        },
    },
    ["CW3-COM-07"] = {
        Feedback = "The strongest response repairs the missed work and improves the shared information process, rather than only settling blame or preventing the next mistake.",
        Stages = {
            {
                Prompt = "Our club missed a deadline because half the group thought the meeting was Friday and half thought it was Saturday. The group wants to understand the mix-up and avoid repeating it.",
                Choices = {
                    "Ask the club president to hear each account and choose a plan so the group can restart work without further debate.",
                    "Review the messages together, identify the conflicting information, and agree on one shared source for future dates.",
                    "Make the last person who sent a message accept responsibility, so everyone knows who should prevent future confusion.",
                },
                ChoiceFeedback = {
                    "A neutral coordinator can help the group move forward. The missing step is checking the records and fixing the source of the confusion, so the same problem does not recur.",
                    "This checks evidence without blaming people for conflicting memories and makes future coordination clearer.",
                    "Being the last messenger does not establish responsibility. Assigning blame without checking the conflicting information can damage trust and leave the communication problem unchanged.",
                },
            },
            {
                Prompt = "The messages show one post said Friday and a later calendar invite said Saturday. Some missed work can still be recovered if the group contacts the organizer today.",
                Choices = {
                    "Remove the conflicting posts to give everyone a clean start, then continue using the calendar for the remaining work.",
                    "Make the calendar the official source and resume normal work, leaving the missed deadline discussion until people feel calmer.",
                    "Acknowledge both notices, contact the organizer about recovery today, and agree which source will govern future changes.",
                },
                ChoiceFeedback = {
                    "A single source is useful, but deleting the record hides how the error happened and does not recover the missed work. Preserve the facts while correcting the process.",
                    "Choosing one source helps future coordination, and a calm discussion matters. Here there is a time-sensitive recovery opportunity; the stronger plan also acts on that today.",
                    "This handles both the immediate consequence and the system that caused it, without requiring a winner in a memory dispute.",
                },
            },
        },
    },
    ["CW3-COM-10"] = {
        Feedback = "The most complete response combines responsibility for unclear commitments, practical scheduling, and acknowledgement of the friend's feelings.",
        Stages = {
            {
                Prompt = "I told two friends I would \"probably be free\" Saturday. Both now believe I promised to attend their separate events. I have not yet asked whether either plan is flexible.",
                Choices = {
                    "Choose the invitation that arrived first and apologize to the other friend, offering to spend time together another day.",
                    "Tell both friends I created unclear expectations and ask about flexibility before agreeing on a plan I can actually keep.",
                    "Show both friends that I said probably rather than definitely, then ask what changes they could make to accommodate me.",
                },
                ChoiceFeedback = {
                    "Using a consistent rule and offering another time is reasonable. It decides the outcome before checking flexibility, so a plan that accommodates both may be missed.",
                    "This accepts your part in the misunderstanding and checks practical options before making a new commitment.",
                    "The messages provide useful context, and asking about flexibility helps. Focusing on the word probably can sound like dismissing their expectations; acknowledge the impact of your wording as well.",
                },
            },
            {
                Prompt = "One event can be moved without losing the booking, but that friend says moving it makes them feel less important. I still want to respect both friendships.",
                Choices = {
                    "Arrange the practical change and send both friends the new times, leaving the emotional conversation for another occasion.",
                    "Keep the movable event at its original time to prove that friendship matters, even if this breaks the other commitment.",
                    "Acknowledge the hurt, explain the scheduling tradeoff, and confirm a workable plan without ranking either friendship.",
                },
                ChoiceFeedback = {
                    "Clear scheduling is helpful and might reduce immediate confusion. It leaves the stated hurt unanswered; a brief acknowledgement can address that without changing a workable arrangement.",
                    "Reassurance matters, but proving it by breaking the other commitment creates another avoidable disappointment. Address the feeling directly rather than treating the calendar as a test of loyalty.",
                    "This responds to both the logistics and the relationship concern without promising something you cannot deliver.",
                },
            },
        },
    },
    ["CW3-PWC-08"] = {
        Feedback = "A complete response corrects the work record and documents the concern without spreading the rumor or demanding punishment before the facts are established.",
        Stages = {
            {
                Prompt = "A coworker tells others that I caused a mistake I did not make, and the rumor reaches my supervisor. I have records that could clarify who completed each task.",
                Choices = {
                    "Give my supervisor the relevant records and ask for an accurate account, then consider a private clarification if it is useful.",
                    "Explain my account to a few trusted coworkers so they can understand my position before I speak with the supervisor.",
                    "Share the coworker's previous mistakes with the team so people will doubt their accusation and stop blaming me.",
                },
                ChoiceFeedback = {
                    "This puts relevant facts with the person reviewing the work and avoids expanding the gossip.",
                    "Seeking support from trusted coworkers is understandable. It does not yet correct the supervisor's account and may spread the story; sharing the records through the work process is more direct.",
                    "A counter-campaign attacks the coworker rather than clarifying this incident. It can escalate the conflict and weaken trust even when your original concern is valid.",
                },
            },
            {
                Prompt = "My supervisor accepts that the records do not support blaming me, but cannot tell who started the rumor. The incorrect attribution is still in the shared work report.",
                Choices = {
                    "Refuse further teamwork until the supervisor identifies who began the rumor and assigns a consequence for the false accusation.",
                    "Request a factual correction to the shared report, keep a record of the incident, and return attention to the team's work.",
                    "Agree to move on and keep private notes in case it happens again, leaving the shared report as it currently stands.",
                },
                ChoiceFeedback = {
                    "Accountability is a fair concern. Making cooperation depend on identifying an uncertain source turns it into an all-or-nothing demand; correcting the verified record is a more workable first step.",
                    "This corrects a concrete consequence, preserves evidence of a pattern if one develops, and supports continued cooperation.",
                    "Moving on and keeping notes are reasonable. The missing step is correcting the shared report, where the inaccurate attribution could affect future decisions about your work.",
                },
            },
        },
    },
    ["CW3-PSC-10"] = {
        Feedback = "The strongest response combines a fair review process with the specific context and evidence that could resolve the allegation, without pressuring a reporter.",
        Stages = {
            {
                Prompt = "A teacher says someone anonymously reported that I used unauthorized notes during a test. I did not cheat, and I want a fair chance to explain what happened.",
                Choices = {
                    "Ask a trusted classmate what they observed around my desk, then wait for the teacher to tell me more about the allegation.",
                    "Ask for an evidence-based review that protects the reporter's identity, but hold back my own account until the procedure is agreed.",
                    "Ask what evidence is being considered and calmly offer my own relevant account, while respecting the reporter's privacy.",
                },
                ChoiceFeedback = {
                    "Checking with a witness may help and does not require finding the reporter. It leaves the teacher's actual evidence unclear; the stronger response also engages directly with the review.",
                    "A fair process and privacy are important. Waiting to provide your account may delay useful clarification; you can ask about the process while sharing relevant facts.",
                    "This combines fair procedure, privacy, and timely evidence rather than treating them as competing goals.",
                },
            },
            {
                Prompt = "The teacher says a photo shows paper near my desk. I believe it belonged to the student behind me, and the seating arrangement and photo angle may help clarify that.",
                Choices = {
                    "Explain why I think the paper was elsewhere, identify relevant seating details, and let the teacher check those claims independently.",
                    "Ask the teacher to review the seating plan and photo angle independently, without explaining the details I personally remember.",
                    "Ask for a second staff member to review the allegation, postponing my detailed account until that additional review is arranged.",
                },
                ChoiceFeedback = {
                    "This supplies testable context without declaring another student guilty, while leaving the evidence review to the school.",
                    "An independent review is reasonable and avoids confrontation. The missing piece is your specific account, which helps the teacher know what the records need to clarify.",
                    "A second reviewer can be useful if the process seems unfair. At this point, delaying your relevant account adds a step before using information that might resolve the uncertainty.",
                },
            },
        },
    },
}
local Overrides = {}

function Overrides.Apply(library)
    local result = table.clone(library)
    for i, scenario in ipairs(library) do
        local revision = revisions[scenario.Id]
        if revision then
            local copy = table.clone(scenario)
            copy.Feedback = revision.Feedback
            copy.Stages = {}
            assert(#revision.Stages == #scenario.Stages, "Audit stage count changed")
            for j, stage in ipairs(scenario.Stages) do
                local patch = revision.Stages[j]
                local nextStage = table.clone(stage)
                assert(#patch.Choices == 3 and #patch.ChoiceFeedback == 3, "Audit needs three choices")
                nextStage.Prompt = patch.Prompt
                nextStage.Choices = table.clone(patch.Choices)
                nextStage.ChoiceFeedback = table.clone(patch.ChoiceFeedback)
                copy.Stages[j] = nextStage
            end
            result[i] = copy
        end
    end
    return result
end

return Overrides
