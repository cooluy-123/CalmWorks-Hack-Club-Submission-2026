-- Fictional staff concerns; the owner is being asked for practical workplace advice.
local library = {}
local categories = {
    PWC = "Public / Workplace Conflict",
    COM = "Communication & Misunderstandings",
    BND = "Boundary Setting",
    CSV = "Customer & Service Conflict",
}

local function add(id, role, level, code, skill, title, background, choices, feedback)
    table.insert(library, {
        Id = "CW-STAFF-" .. id,
        WorkplaceRole = role,
        CustomerTags = {
            Moods = level == 1 and { "Calm", "Confused", "Annoyed" }
                or { "Frustrated", "Anxious", "Hurt", "Defensive" },
            Personalities = role == "Manager" and { "Analytical", "Direct", "Perfectionistic", "Skeptical" }
                or { "Reserved", "Sensitive", "PeoplePleasing", "Direct" },
            Styles = { "Brief", "Logical", "Detailed", "Uncertain" },
        },
        Title = title,
        Difficulty = level,
        CategoryCode = code,
        Category = categories[code],
        EloSeed = 800 + level * 150,
        Severity = 1,
        Skills = { skill },
        Skill = skill,
        Feedback = feedback[1],
        FRQ = {
            Prompt = "What would you advise this team member to do next? Give a practical response and briefly explain why.",
            Rubric = {
                {
                    Label = "Understanding",
                    Weight = 20,
                    Anchor = "Recognize the workplace concern without assuming motives.",
                },
                {
                    Label = "De-escalation",
                    Weight = 20,
                    Anchor = "Use calm, respectful wording without blame or threats.",
                },
                { Label = "Practical next step", Weight = 25, Anchor = feedback[1] },
                {
                    Label = "Boundaries and fairness",
                    Weight = 20,
                    Anchor = "Respect both staff members' needs and realistic limits.",
                },
                {
                    Label = "Clear communication",
                    Weight = 15,
                    Anchor = "Explain a workable next step; simple everyday wording is enough.",
                },
            },
        },
        Stages = {
            {
                StageNumber = 1,
                Prompt = background,
                Choices = choices,
                ChoiceFeedback = feedback,
                ChoiceOutcomes = { "Optimal", "Mixed", "Risky" },
                ChoiceResultScores = { 1, 0.6, 0 },
                ChoiceKeys = { "A", "B", "C" },
                BestIndex = 1,
                BestKey = "A",
            },
        },
    })
end

add(
    "C-01",
    "Counselor",
    1,
    "BND",
    "boundary setting",
    "Shared desk supplies",
    "At CalmWorks, another counselor takes the last blank forms from my desk without telling me. I need them for the next customer, and there are more in the supply cupboard. How should I address this?",
    {
        "Restock now, then privately agree to check and replace shared forms before taking the last ones.",
        "Restock now, then send everyone a general reminder without discussing the specific problem privately.",
        "Restock now, then reserve all spare forms at my desk to prevent another shortage.",
    },
    {
        "This meets the immediate need and agrees on a clear, shared expectation without blame.",
        "A reminder may help, but a private agreement addresses the recurring misunderstanding more directly.",
        "Keeping all supplies may protect your desk but shifts the shortage onto other counselors.",
    }
)

add(
    "C-02",
    "Counselor",
    1,
    "COM",
    "active listening",
    "An unclear handoff",
    "At CalmWorks, a manager asks me to follow up with a customer but leaves before saying which question is unresolved. The customer is waiting calmly. What should I do before giving advice?",
    {
        "Ask the customer what remains unresolved and confirm the handoff with the manager before advising.",
        "Review the available notes and give general advice while waiting to confirm the missing details.",
        "Use the usual follow-up script and assume the previous conversation covered the main concern.",
    },
    {
        "Checking the customer's understanding and the handoff avoids guessing about their needs.",
        "Notes help, but advice before clarification may not address what the customer is asking.",
        "A familiar script cannot establish facts that are missing from the handoff.",
    }
)

add(
    "C-03",
    "Counselor",
    2,
    "PWC",
    "calm assertion",
    "Interrupted at the team meeting",
    "At CalmWorks, a coworker interrupts my updates at two team meetings. They later say they were trying to keep the meetings short. I still need to share information that affects our handoffs. What could I try first?",
    {
        "Explain the impact privately and agree on brief uninterrupted updates followed by questions from everyone.",
        "Send my updates before meetings so everyone has information without discussing the interruptions directly.",
        "Ask the owner to limit that coworker's speaking time before discussing their explanation with them.",
    },
    {
        "This addresses the behavior and the time concern with a practical agreement before escalating.",
        "Written updates support clarity, but they leave the interruption pattern and speaking expectations unresolved.",
        "An imposed restriction escalates a problem that may be resolved through a direct private discussion.",
    }
)

add(
    "C-04",
    "Counselor",
    2,
    "CSV",
    "problem solving",
    "Conflicting expectations",
    "At CalmWorks, a customer says another counselor promised a longer session today. My schedule shows the usual time, and the other counselor is available to clarify. I cannot promise extra time yet. What should I do?",
    {
        "Acknowledge the confusion, verify the earlier promise privately, and offer only options we can provide.",
        "Offer another appointment immediately so the customer has an option before checking the earlier promise.",
        "Honor the longer session immediately and explain the resulting delay to the other customers afterward.",
    },
    {
        "Verifying first protects trust without making an unsupported promise or blaming a colleague.",
        "Another appointment may be useful, but checking the original agreement should come before settling the response.",
        "Promising time you cannot provide transfers the problem to waiting customers and may create another broken promise.",
    }
)

add(
    "C-05",
    "Counselor",
    3,
    "BND",
    "self advocacy",
    "Extra tasks at a busy counter",
    "At CalmWorks, I finish routine tasks quickly, so my manager gives me extra follow-ups. Now both my customer queue and follow-ups are slipping. The manager has not seen the combined workload. How should I raise this?",
    {
        "Show the combined workload, ask which tasks take priority, and agree on a realistic revised allocation.",
        "Complete the shortest tasks first and report the remaining work at the next scheduled team meeting.",
        "Return the extra follow-ups to the manager so I can meet the original counter responsibilities.",
    },
    {
        "Shared facts let you negotiate priorities and capacity instead of treating every task as equally urgent.",
        "Short tasks can reduce a backlog, but delaying the capacity discussion leaves important priorities uncertain.",
        "Unilaterally returning work may leave customers unsupported; first agree who will handle each responsibility.",
    }
)

add(
    "C-06",
    "Counselor",
    3,
    "PWC",
    "evidence based problem solving",
    "Credit for a useful idea",
    "At CalmWorks, I designed a clearer handoff checklist. A coworker presented it as our shared idea, although they only tested it. We still need to work together, and the owner has not assigned credit. What is the best next step?",
    {
        "Discuss our contributions privately and propose a joint clarification that credits design and testing accurately.",
        "Send the owner my original draft to establish the timeline without discussing it with my coworker.",
        "Wait for the next meeting and correct the description publicly so the whole team hears it.",
    },
    {
        "Specific contributions support fair recognition while giving your coworker a chance to correct the misunderstanding.",
        "The draft is relevant evidence, but contacting the owner first skips a proportionate opportunity to resolve it together.",
        "Public correction may increase defensiveness before you have checked whether a private clarification would work.",
    }
)

add(
    "M-01",
    "Manager",
    1,
    "COM",
    "clear communication",
    "Two versions of an instruction",
    "At CalmWorks, two counselors understood my handoff instruction differently. Both interpretations fit the short message I sent, and no customer has been affected yet. How should I put this right?",
    {
        "Acknowledge the ambiguity, clarify the handoff together, and ask both counselors to explain the shared plan.",
        "Send a longer written instruction and invite either counselor to ask if anything remains unclear.",
        "Choose the interpretation used by the more experienced counselor and ask everyone to follow that example.",
    },
    {
        "Owning the unclear message and checking understanding creates a shared process without blaming staff.",
        "A written clarification helps, but directly checking understanding is more reliable after two different interpretations.",
        "Experience does not resolve what the original instruction meant and may unfairly dismiss the other counselor.",
    }
)

add(
    "M-02",
    "Manager",
    1,
    "CSV",
    "active listening",
    "A vague complaint about service",
    "At CalmWorks, a customer says a counselor was unhelpful but gives no example. The counselor remembers a routine conversation. I want to respond fairly without deciding who is wrong from this alone. What should I do?",
    {
        "Ask privately for specific examples from both people, then identify the service issue before choosing action.",
        "Apologize for the disappointing visit and arrange another counselor before asking for more specific details.",
        "Give the counselor corrective feedback immediately so the customer sees that the complaint was taken seriously.",
    },
    {
        "Hearing concrete accounts supports a fair response and avoids treating an impression as established wrongdoing.",
        "Offering another visit can help, but it does not explain what needs to change or establish a fair account.",
        "Correction before checking the facts assumes the counselor did something wrong and can damage trust.",
    }
)

add(
    "M-03",
    "Manager",
    2,
    "BND",
    "boundary setting",
    "An unsustainable favor",
    "At CalmWorks, a counselor keeps accepting coworkers' routine tasks to be helpful and now misses their own follow-ups. Nobody was assigned to transfer those tasks. I need to support the counselor without discouraging teamwork. What should I do?",
    {
        "Review capacity privately, agree on limits, and make task transfers explicit so responsibility stays clear.",
        "Praise their helpfulness and offer time-management tips while keeping the informal task-sharing arrangement unchanged.",
        "Stop coworkers from asking them for help entirely so their original workload can recover first.",
    },
    {
        "Clear capacity limits and agreed transfers protect both teamwork and reliable follow-ups.",
        "Time management may help, but it does not fix unclear responsibility or work that exceeds capacity.",
        "A blanket ban removes useful cooperation instead of setting a proportionate boundary around workload.",
    }
)

add(
    "M-04",
    "Manager",
    2,
    "PWC",
    "collaborative problem solving",
    "Disagreement over desk coverage",
    "At CalmWorks, two counselors disagree about who should cover a shared desk during a quiet period. Both have valid follow-up tasks, and there is no agreed rotation. How can I resolve this fairly?",
    {
        "Hear both priorities, agree on coverage for today, and establish a rotation with a review date.",
        "Split today's quiet period equally and leave the longer-term arrangement until the disagreement happens again.",
        "Assign coverage to the counselor who complains less so the discussion ends without further conflict.",
    },
    {
        "This meets today's need and creates a transparent, reviewable process for future coverage.",
        "An equal split may help today, but postponing a clear process invites the same disagreement later.",
        "Using willingness to complain as the criterion rewards pressure rather than addressing workload and fairness.",
    }
)

add(
    "M-05",
    "Manager",
    3,
    "CSV",
    "proportional response",
    "Speed versus careful service",
    "At CalmWorks, shorter conversations reduced the queue, but several customers returned because their next step was unclear. The counselors say they were following my request to work faster. I need both reasonable waits and useful advice. What should I change?",
    {
        "Acknowledge the tradeoff, add a brief understanding check, and review wait times and repeat visits together.",
        "Restore longer conversations immediately and review queue lengths after customers stop returning for clarification.",
        "Keep the faster target and ask counselors to fit every clarification into the same shorter conversations.",
    },
    {
        "A specific understanding check addresses the evidence while measuring both service quality and waiting time.",
        "More time may help, but a blanket change does not test which clarification is missing or track both goals together.",
        "Keeping the unchanged time target ignores the tradeoff that the counselors have already encountered.",
    }
)

add(
    "M-06",
    "Manager",
    3,
    "PWC",
    "fair decision making",
    "A recurring handoff problem",
    "At CalmWorks, two counselors blame each other for missed handoffs. Their notes show gaps on both shifts, but the handoff checklist does not say who confirms receipt. Customers need continuity while we find the cause. What should I do first?",
    {
        "Arrange interim receipt checks, review specific handoffs with both counselors, and clarify shared responsibilities before assigning blame.",
        "Interview both counselors separately and postpone process changes until their accounts agree about the missed handoffs.",
        "Assign one counselor full handoff responsibility immediately so there is a single person accountable for every gap.",
    },
    {
        "Interim checks protect customers while a fact-based review separates an unclear process from individual performance.",
        "Listening matters, but waiting for agreement leaves the known confirmation gap unaddressed in the meantime.",
        "Single-person accountability may look clear but can unfairly transfer a shared process problem before it is understood.",
    }
)

add(
    "E-01",
    "Executive",
    1,
    "COM",
    "active listening",
    "An unclear referral",
    "At CalmWorks, a counselor sends a customer to my executive desk with only a brief note. The customer says they already explained the issue downstairs. How should I begin?",
    {
        "Acknowledge the repeated explanation, ask what remains unresolved, and confirm only the missing facts with the counselor.",
        "Read the note aloud and start giving general advice while the counselor prepares a fuller handoff.",
        "Ask the customer to explain everything again so my notes are independent of the earlier conversation.",
    },
    {
        "This respects the customer's time and checks the gap before advising.",
        "General advice can miss the unresolved need even if the note is accurate.",
        "A complete restart adds frustration when a focused clarification would be enough.",
    }
)

add(
    "E-02",
    "Executive",
    1,
    "BND",
    "boundary setting",
    "A quiet moment to finish notes",
    "At CalmWorks, coworkers interrupt my executive consultations with routine questions that could wait. I want to stay helpful while giving each customer my attention. What should I suggest?",
    {
        "Agree on a clear signal for active consultations and a shared place for nonurgent questions afterward.",
        "Ask coworkers to judge for themselves whether each interruption is important enough to bring upstairs.",
        "Set a rule that no coworker may ask me questions during any part of the working day.",
    },
    {
        "A clear signal and follow-up channel protect attention while keeping support available.",
        "Without a shared expectation the same interruption pattern can continue.",
        "A total ban prevents useful support and does not distinguish urgent needs.",
    }
)

add(
    "E-03",
    "Executive",
    2,
    "CSV",
    "problem solving",
    "Conflicting accounts of a wait",
    "At CalmWorks, a customer complains that a counselor ignored them. The counselor says the customer was waiting for a separate referral. I have incomplete notes and both want an immediate answer. What is a fair next step?",
    {
        "Acknowledge the wait, check the timeline with both people, and agree on a practical next step without assigning blame yet.",
        "Apologize on the counselor's behalf and offer a process change before discussing the differing accounts.",
        "Explain that referrals take time and ask the customer to wait while the counselor finishes their notes.",
    },
    {
        "Checking specific facts supports a fair response while still addressing the customer's immediate need.",
        "An apology for the experience can help, but assigning responsibility before checking facts can be unfair.",
        "Explaining a process without checking what occurred can dismiss a legitimate concern.",
    }
)

add(
    "E-04",
    "Executive",
    2,
    "PWC",
    "clear communication",
    "Advice that changes at handoff",
    "At CalmWorks, my executive desk and a downstairs counselor have given different next steps for the same customer. Both suggestions could help, but switching back and forth is confusing the customer. What should I do?",
    {
        "Compare the reasons privately with the counselor, agree on one coherent plan, and explain the update to the customer.",
        "Ask the customer to choose whichever advice sounds better and record that decision for the next visit.",
        "Use the executive plan immediately and tell the counselor to explain the change during the next handoff.",
    },
    {
        "A coordinated explanation reduces confusion while respecting both perspectives.",
        "Customer choice matters, but staff should clarify contradictions rather than transfer that burden.",
        "Changing the plan by seniority alone misses useful information and can damage teamwork.",
    }
)

add(
    "E-05",
    "Executive",
    3,
    "BND",
    "boundary setting",
    "Urgent requests and limited capacity",
    "At CalmWorks, two counselors request immediate executive support while I am helping a customer whose concern needs careful attention. Neither request appears to involve immediate danger, but waiting also has costs. What should I arrange?",
    {
        "Briefly check urgency, agree on interim steps and realistic updates, then finish or hand off my current consultation deliberately.",
        "Pause my current consultation to handle both requests quickly, then return when the downstairs queues are moving.",
        "Finish my current consultation without interruption and tell both counselors to bring their requests back later.",
    },
    {
        "A short urgency check balances continuity with support and avoids making promises beyond capacity.",
        "Frequent abrupt switches can harm the current consultation without establishing priorities.",
        "Protecting focus helps, but offering no triage or interim support ignores the other needs.",
    }
)

add(
    "E-06",
    "Executive",
    3,
    "PWC",
    "fair decision making",
    "A colleague feels dismissed",
    "At CalmWorks, a counselor says my executive handoffs make them feel that their judgment is ignored. Some referrals did need clarification, and I also want customers to receive consistent advice. How should I respond?",
    {
        "Review specific handoffs together, acknowledge the impact, and agree on when clarification or a joint explanation is needed.",
        "Reassure the counselor that their work is valued and keep the current handoff approach until complaints increase.",
        "Ask the manager to approve every future referral before it reaches my desk so disagreements are avoided.",
    },
    {
        "Specific examples and shared thresholds protect service quality while addressing trust and workload.",
        "Reassurance alone leaves the source of the recurring tension unchanged.",
        "Adding approval to every referral can create delays without resolving the communication problem.",
    }
)

return library
