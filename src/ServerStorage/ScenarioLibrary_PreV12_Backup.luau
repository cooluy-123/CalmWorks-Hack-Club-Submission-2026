-- Generated from CalmWorks_Scenario_Library.txt. Keep this module in ServerStorage.
-- Answer keys remain server-only and are never sent to clients.
local ScenarioLibrary = {
	{
		Id = "CW-001",
		Title = "Cut In Line",
		Difficulty = 1,
		Skill = "Calm assertion",
		Feedback = "State the problem clearly without threatening or embarrassing the other person.",
		Stages = {
			{
				Prompt = "Someone cut in front of me in line. I want to teach them a lesson without causing a scene. What should I do?",
				Choices = {
					"Cut back in front of them and stare them down.",
					"Calmly say, \"Excuse me, the line starts behind us.\"",
					"Follow them afterward and confront them; continue without outside support.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-002",
		Title = "Wrong Drink",
		Difficulty = 1,
		Skill = "Clear communication",
		Feedback = "A specific, respectful request gives the worker a fair chance to fix the mistake.",
		Stages = {
			{
				Prompt = "The cafe gave me the wrong drink, and I am already late. I feel like yelling at the worker.",
				Choices = {
					"Throw the drink away in front of the worker; make no further changes.",
					"Calmly show the receipt and ask if the order can be corrected.",
					"Post the worker's name online right away; share it with more people.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-003",
		Title = "Borrowed Charger",
		Difficulty = 1,
		Skill = "Boundary-setting",
		Feedback = "A calm boundary addresses both the immediate need and the future behavior.",
		Stages = {
			{
				Prompt = "My sibling took my charger without asking. I need it right now.",
				Choices = {
					"Ask for it back and explain that they need permission before borrowing it.",
					"Hide every charger in the house; continue without asking for help.",
					"Yell until they return it; continue until they give in.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-004",
		Title = "Blamed For The Loss",
		Difficulty = 1,
		Skill = "Avoiding blame cycles",
		Feedback = "Shift the conversation from personal blame to shared improvement.",
		Stages = {
			{
				Prompt = "My teammate says we lost because of me. I want to tell everyone how badly they played.",
				Choices = {
					"List all of the teammate's mistakes; continue without asking for help.",
					"Say, \"We all made mistakes. Can we talk about what to improve next round?\"",
					"Sabotage the next game to prove a point; insist on an apology.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-005",
		Title = "Interrupted In Class",
		Difficulty = 1,
		Skill = "Respectful self-advocacy",
		Feedback = "Assert your turn without copying the disrespectful behavior.",
		Stages = {
			{
				Prompt = "A classmate keeps speaking over me whenever I answer a question.",
				Choices = {
					"Speak even louder over them; make no other attempt to resolve the issue afterward.",
					"Calmly say, \"I would like to finish my point, then I will listen to yours.\"",
					"Stop participating completely; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-006",
		Title = "Canceled Plans",
		Difficulty = 1,
		Skill = "Expressing disappointment",
		Feedback = "Explain the pattern and its impact before assuming bad intent.",
		Stages = {
			{
				Prompt = "My friend canceled our plans at the last minute for the second time. I am really annoyed.",
				Choices = {
					"Pretend it does not bother you, then ignore them for a week.",
					"Ask what happened and explain that repeated last-minute cancellations are frustrating.",
					"Cancel every future plan with them at the last minute.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-007",
		Title = "Noisy Study Space",
		Difficulty = 1,
		Skill = "Making a specific request",
		Feedback = "A clear request with a time limit is easier for others to follow.",
		Stages = {
			{
				Prompt = "My family is being loud while I study. I cannot focus.",
				Choices = {
					"Slam the door and shout at everyone; insist on an apology.",
					"Ask if they can lower the volume for a set amount of time.",
					"Give up and blame them for the grade; keep the situation completely private.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-008",
		Title = "My Seat",
		Difficulty = 1,
		Skill = "Checking assumptions",
		Feedback = "A usual seat may not be a reserved seat. Check before treating it as a conflict.",
		Stages = {
			{
				Prompt = "Someone is sitting in the spot where I usually sit at lunch.",
				Choices = {
					"Tell them they stole your seat; make no further changes.",
					"Push their tray aside; continue until they give in.",
					"Ask politely if the seat is available or choose another place.",
				},
				BestIndex = 3,
			},
		},
	},
	{
		Id = "CW-009",
		Title = "Late Group Member",
		Difficulty = 1,
		Skill = "Problem-focused communication",
		Feedback = "Address the delay while keeping the group focused on completing the work.",
		Stages = {
			{
				Prompt = "One person arrived late to our group meeting, and now we are behind.",
				Choices = {
					"Refuse to let them participate; continue without asking for help.",
					"Ask what happened, summarize what they missed, and agree on the next task.",
					"Secretly remove their name from the project; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-010",
		Title = "Broken Pencil",
		Difficulty = 1,
		Skill = "Pausing before reacting",
		Feedback = "An accident can still be upsetting, but retaliation creates a second problem.",
		Stages = {
			{
				Prompt = "My younger sibling broke my favorite pencil. I know it was an accident, but I am furious.",
				Choices = {
					"Break something they like; demand an apology before stopping the confrontation.",
					"Pause, explain why it mattered to you, and ask them to be more careful.",
					"Call them careless for the rest of the day; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-011",
		Title = "Bumped In The Hall",
		Difficulty = 1,
		Skill = "Giving room for mistakes",
		Feedback = "Not every rude-looking moment is intentional or worth escalating.",
		Stages = {
			{
				Prompt = "Someone bumped into me in the hallway and kept walking.",
				Choices = {
					"Chase them and shove them back; continue until they give in.",
					"Assume it may have been accidental and continue unless there is a safety issue.",
					"Block the hallway until they apologize; wait to see if they stop.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-012",
		Title = "Sold Out",
		Difficulty = 1,
		Skill = "Managing disappointment",
		Feedback = "Focus on available solutions rather than punishing someone who did not cause the shortage.",
		Stages = {
			{
				Prompt = "I waited all week to buy an item, but the store sold out before I arrived.",
				Choices = {
					"Demand that another customer give you theirs; make no further changes.",
					"Ask when it may return or look for an alternative.",
					"Knock items off a shelf; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-013",
		Title = "My Joke",
		Difficulty = 1,
		Skill = "Direct but proportionate response",
		Feedback = "A light, direct comment can correct the record without creating a larger conflict.",
		Stages = {
			{
				Prompt = "A classmate repeated my joke and everyone acted like it was theirs.",
				Choices = {
					"Interrupt and call them a thief; make no further changes.",
					"Calmly mention, \"I am glad you liked the joke I told earlier.\"",
					"Spread an embarrassing story about them; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-014",
		Title = "The Mess",
		Difficulty = 1,
		Skill = "Using \"I\" statements",
		Feedback = "Describe the effect and request a specific action instead of attacking the person.",
		Stages = {
			{
				Prompt = "My sibling left a mess in our shared room again.",
				Choices = {
					"Put all of the mess on their bed; wait for their next response.",
					"Say, \"I feel stressed when our shared space is left like this. Can we clean it now?\"",
					"Complain to friends but never speak to them; continue without asking for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-015",
		Title = "Benched",
		Difficulty = 1,
		Skill = "Seeking useful feedback",
		Feedback = "A private question is more likely to produce useful information than a public argument.",
		Stages = {
			{
				Prompt = "My coach benched me, and I think it was unfair.",
				Choices = {
					"Quit during the game; keep the entire situation private unless it becomes worse.",
					"Ask the coach privately what you can improve and when you may have another opportunity.",
					"Refuse to practice; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-016",
		Title = "No Text Back",
		Difficulty = 1,
		Skill = "Avoiding negative assumptions",
		Feedback = "Delayed replies can have many explanations. Wait for more information.",
		Stages = {
			{
				Prompt = "My friend has not answered my message for hours. I think they are ignoring me.",
				Choices = {
					"Send twenty more messages; continue without asking for help.",
					"Accuse them of being fake; wait for their next response.",
					"Give them time and check in later without assuming why they are unavailable.",
				},
				BestIndex = 3,
			},
		},
	},
	{
		Id = "CW-017",
		Title = "Lag Accusation",
		Difficulty = 1,
		Skill = "Staying respectful online",
		Feedback = "A brief respectful response prevents a minor disagreement from becoming harassment.",
		Stages = {
			{
				Prompt = "A player says I only won because their game was lagging.",
				Choices = {
					"Say, \"That is frustrating. We can rematch later if you want.\"",
					"Follow them into another server to tease them; continue without outside support.",
					"Report them only because they complained; make no further changes.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-018",
		Title = "Wrong Change",
		Difficulty = 1,
		Skill = "Calm correction",
		Feedback = "Invite both people to check the facts instead of starting with an accusation.",
		Stages = {
			{
				Prompt = "The cashier gave me the wrong change. I am worried they will think I am accusing them of stealing.",
				Choices = {
					"Leave without saying anything; keep the entire situation private unless it becomes worse.",
					"Say, \"I may be mistaken, but can we check the receipt and change together?\"",
					"Call the cashier dishonest; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-019",
		Title = "Teammate Will Not Pass",
		Difficulty = 1,
		Skill = "Constructive request",
		Feedback = "Discuss the teamwork problem at a calm moment and propose a specific adjustment.",
		Stages = {
			{
				Prompt = "My teammate never passes the ball to me.",
				Choices = {
					"Stop passing to them too; make no further changes.",
					"Shout at them during the game; insist on an apology.",
					"Ask during a break if you can coordinate positions and passes.",
				},
				BestIndex = 3,
			},
		},
	},
	{
		Id = "CW-020",
		Title = "Used My Supplies",
		Difficulty = 1,
		Skill = "Setting expectations",
		Feedback = "Explain the reason for the boundary and what you need in the future.",
		Stages = {
			{
				Prompt = "Someone used my markers without asking and left the caps off.",
				Choices = {
					"Hide their supplies; wait for the other person to decide what happens next.",
					"Explain that the markers can dry out and ask them to request permission next time.",
					"Say nothing, then explode later; avoid discussing the situation with anyone who could help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-021",
		Title = "A Secret Was Shared",
		Difficulty = 2,
		Skill = "Addressing broken trust",
		Feedback = "Address the breach directly and decide future boundaries based on their response.",
		Stages = {
			{
				Prompt = "I told my friend something private, and they repeated it to someone else.",
				Choices = {
					"Share one of their secrets in return; share it with more people.",
					"Ask privately what happened, explain how it affected your trust, and set a boundary.",
					"Pretend everything is fine while planning revenge; wait for it to disappear.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-022",
		Title = "The Grade Dispute",
		Difficulty = 2,
		Skill = "Evidence-based disagreement",
		Feedback = "Use the rubric and specific questions rather than attacking the teacher's motives.",
		Stages = {
			{
				Prompt = "I think my teacher graded my assignment unfairly.",
				Choices = {
					"Accuse the teacher of hating you in front of the class.",
					"Compare the rubric with your work and ask privately for clarification.",
					"Change the grade in the online system if possible; share it with more people.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-023",
		Title = "Embarrassing Photo",
		Difficulty = 2,
		Skill = "Consent and direct requests",
		Feedback = "Clearly state the consent issue and request removal. Escalate to platform or adult support if needed.",
		Stages = {
			{
				Prompt = "My friend posted an embarrassing photo of me without asking.",
				Choices = {
					"Post a worse photo of them; continue posting updates until public pressure changes the outcome.",
					"Ask them to remove it and explain that you did not consent to it being shared.",
					"Log into their account and delete it yourself; avoid discussing it with anyone else.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-024",
		Title = "Stolen Credit",
		Difficulty = 2,
		Skill = "Calm self-advocacy",
		Feedback = "Preserve evidence and use the proper setting to correct the contribution record.",
		Stages = {
			{
				Prompt = "A group member presented my idea as if it were completely theirs.",
				Choices = {
					"Interrupt the presentation and call them a liar; make no further changes.",
					"Document your work and discuss the credit issue privately with the group or teacher.",
					"Delete the group's files; keep the entire situation private unless it becomes worse.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-025",
		Title = "The Nickname",
		Difficulty = 2,
		Skill = "Firm boundaries",
		Feedback = "A joke stops being harmless when a person clearly asks for it to stop.",
		Stages = {
			{
				Prompt = "My classmates keep using a nickname I dislike. They say it is only a joke.",
				Choices = {
					"Say clearly that you do not like the name and want them to stop.",
					"Laugh every time so they do not know it bothers you; make no further changes.",
					"Threaten to fight the next person who says it; insist on an apology.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-026",
		Title = "Blocked Driveway",
		Difficulty = 2,
		Skill = "Neighbor communication",
		Feedback = "Start with a clear request. Use property management or appropriate authorities only if the pattern continues.",
		Stages = {
			{
				Prompt = "My neighbor keeps parking partly across our driveway.",
				Choices = {
					"Block their car with yours; wait for their next response.",
					"Speak calmly, explain the access problem, and ask them to keep the driveway clear.",
					"Damage the car so they learn; demand that they back down.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-027",
		Title = "Damaged Borrowed Item",
		Difficulty = 2,
		Skill = "Repairing harm",
		Feedback = "Focus on facts, responsibility, and a fair repair rather than punishment.",
		Stages = {
			{
				Prompt = "My friend borrowed my headphones and returned them damaged.",
				Choices = {
					"Break something of theirs; continue until they give in.",
					"Ask what happened and discuss repair or replacement; reassess the situation afterward.",
					"Demand far more money than the headphones cost; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-028",
		Title = "Constant Comparisons",
		Difficulty = 2,
		Skill = "Explaining emotional impact",
		Feedback = "Separate your needs from the sibling and request feedback focused on your own progress.",
		Stages = {
			{
				Prompt = "My parent keeps comparing my grades with my sibling's grades.",
				Choices = {
					"Insult your sibling's abilities; continue the confrontation until the other person gives in.",
					"Say at a calm time that comparisons are discouraging and ask to discuss your own goals.",
					"Stop showing any schoolwork; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-029",
		Title = "No Privacy",
		Difficulty = 2,
		Skill = "Negotiating boundaries",
		Feedback = "Agree on a specific household boundary and seek help enforcing it if necessary.",
		Stages = {
			{
				Prompt = "My sibling enters my room without knocking, even after I asked them not to.",
				Choices = {
					"Enter their room and search through everything; wait for their next response.",
					"Discuss a clear knocking rule and involve a caregiver if the boundary keeps being ignored.",
					"Barricade the door without telling anyone; continue without asking for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-030",
		Title = "Online Insult",
		Difficulty = 2,
		Skill = "Choosing whether to engage",
		Feedback = "You do not owe a hostile stranger a debate. Use platform tools instead of retaliation.",
		Stages = {
			{
				Prompt = "A stranger commented that I am stupid and should delete my video.",
				Choices = {
					"Search their profile for something to insult; insist on an apology.",
					"Reply for hours until they admit you are right; continue without outside support.",
					"Avoid a hostile argument; mute, block, or report if appropriate.",
				},
				BestIndex = 3,
			},
		},
	},
	{
		Id = "CW-031",
		Title = "Left Out",
		Difficulty = 2,
		Skill = "Asking instead of assuming",
		Feedback = "Ask for information before deciding what the exclusion means.",
		Stages = {
			{
				Prompt = "My friends made plans without me. I think they do not want me around anymore.",
				Choices = {
					"Ask one friend calmly if there was a reason you were not included.",
					"Post that they are terrible people; share it with more people.",
					"Arrange another event only to exclude them; make no further changes.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-032",
		Title = "Long Restaurant Wait",
		Difficulty = 2,
		Skill = "Respectful complaint",
		Feedback = "Ask the responsible staff for information and a reasonable solution without intimidating anyone.",
		Stages = {
			{
				Prompt = "My family has waited a long time for food, and nobody has updated us.",
				Choices = {
					"Leave without paying for drinks already received; wait for it to disappear.",
					"Ask politely for an update and discuss options if the delay is too long.",
					"Walk into the kitchen to demand answers; continue without asking for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-033",
		Title = "Return Refused",
		Difficulty = 2,
		Skill = "Escalating through proper channels",
		Feedback = "Use the written policy and the next appropriate decision-maker rather than personal pressure.",
		Stages = {
			{
				Prompt = "A store employee refused my return, but I believe the receipt shows it is allowed.",
				Choices = {
					"Threaten the employee; continue until they give in.",
					"Review the policy and calmly ask a supervisor to clarify it.",
					"Refuse to leave until they give in; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-034",
		Title = "Rumor From A Misunderstanding",
		Difficulty = 2,
		Skill = "Correcting misinformation",
		Feedback = "Clarify the facts while recognizing why the partial statement caused hurt.",
		Stages = {
			{
				Prompt = "Someone thinks I insulted them because they heard only part of a conversation.",
				Choices = {
					"Tell them they are too sensitive; continue without asking for help.",
					"Explain the full context, acknowledge how it sounded, and clarify what you meant.",
					"Start a rumor about the person who told them; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-035",
		Title = "Accused Of Cheating",
		Difficulty = 2,
		Skill = "Staying factual under accusation",
		Feedback = "Defend yourself with facts and boundaries, not retaliation.",
		Stages = {
			{
				Prompt = "My friend says I cheated in a game, but I did not.",
				Choices = {
					"Explain what happened, offer available evidence, and pause the conversation if it becomes hostile.",
					"Cheat next time because they already accused you; make no further changes.",
					"Get everyone to remove them from the group; share it with more people.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-036",
		Title = "Yelling Team Captain",
		Difficulty = 2,
		Skill = "Timing a difficult conversation",
		Feedback = "Choose a calmer moment and make a specific request about communication.",
		Stages = {
			{
				Prompt = "Our team captain yells at me whenever I make a mistake.",
				Choices = {
					"Yell back during the game; continue until they give in.",
					"Speak privately after everyone is calm and explain what feedback would help you improve.",
					"Purposely ignore every instruction; keep the entire situation private unless it becomes worse.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-037",
		Title = "Missing Lunch",
		Difficulty = 2,
		Skill = "Checking facts first",
		Feedback = "Verify what happened and use a fair reporting process instead of revenge.",
		Stages = {
			{
				Prompt = "My lunch disappeared from the work refrigerator, and I think a coworker took it.",
				Choices = {
					"Accuse the coworker in front of everyone; continue posting updates until public pressure changes the outcome.",
					"Ask if anyone moved or mistakenly took it, then use the workplace process if it keeps happening.",
					"Put something unsafe in tomorrow's food; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-038",
		Title = "Idea Ignored",
		Difficulty = 2,
		Skill = "Re-entering a discussion",
		Feedback = "Calmly reconnect your contribution to the discussion and invite collaboration.",
		Stages = {
			{
				Prompt = "My club ignored my suggestion, then praised a similar idea from someone else.",
				Choices = {
					"Quit and tell everyone the club is biased; invite the group to judge them.",
					"Say, \"That is similar to my earlier suggestion. Could we combine the ideas and discuss it?\"",
					"Secretly stop helping with the project; continue with the same approach if the problem returns.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-039",
		Title = "Wrong Appointment Time",
		Difficulty = 2,
		Skill = "Collaborative problem-solving",
		Feedback = "Bring evidence and ask both sides to solve the scheduling conflict.",
		Stages = {
			{
				Prompt = "The office says my appointment was earlier, but my confirmation message shows a different time.",
				Choices = {
					"Show the confirmation, ask them to check the record, and discuss the next available solution.",
					"Refuse to move from the desk; continue without asking for help.",
					"Threaten a bad review before they respond; continue until they give in.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-040",
		Title = "Group Chat Argument",
		Difficulty = 2,
		Skill = "Moving conflict to a better setting",
		Feedback = "Public audiences often intensify conflict. Reduce the audience and slow the conversation.",
		Stages = {
			{
				Prompt = "Two friends are arguing in our group chat, and everyone is choosing sides.",
				Choices = {
					"Add jokes that embarrass both people; make no further changes.",
					"Suggest pausing the public argument and speaking privately when calm.",
					"Run a poll to decide who is wrong; share it with more people.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-041",
		Title = "Repeated Hallway Bullying",
		Difficulty = 3,
		Skill = "Assertiveness and adult support",
		Feedback = "Repeated bullying should not be handled alone. Prioritize safety, documentation, and trusted support.",
		Stages = {
			{
				Prompt = "The same students block my path and mock me almost every day. I am afraid fighting back will make it worse.",
				Choices = {
					"Bring friends to surround them tomorrow; wait for the other person to decide what happens next; keep the situation completely private.",
					"Calmly tell them to stop if it feels safe, leave the area, and report the repeated behavior to a trusted adult.",
					"Wait until they are alone and threaten them; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-042",
		Title = "Cyberbullying Group",
		Difficulty = 3,
		Skill = "Digital boundaries and evidence",
		Feedback = "Preserve evidence and involve support instead of entering a cycle of online retaliation.",
		Stages = {
			{
				Prompt = "A group chat was created to make fun of me. People keep adding me back after I leave.",
				Choices = {
					"Make a second group to insult them; continue the confrontation until the other person gives in.",
					"Save relevant evidence, block or leave, report the accounts, and tell a trusted adult or school contact.",
					"Delete every message before anyone can see it; avoid discussing it with anyone else.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-043",
		Title = "Password Pressure",
		Difficulty = 3,
		Skill = "Recognizing controlling behavior",
		Feedback = "Trust does not require surrendering account security or personal boundaries.",
		Stages = {
			{
				Prompt = "My best friend says real friends share passwords. They are angry because I said no.",
				Choices = {
					"Share the password to prove trust; share it with more people.",
					"Explain that privacy is a normal boundary and keep the password private.",
					"Create a fake password so they stop asking; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-044",
		Title = "Constant Location Checks",
		Difficulty = 3,
		Skill = "Healthy relationship boundaries",
		Feedback = "Repeated surveillance demands and guilt-based pressure are warning signs, not proof of care.",
		Stages = {
			{
				Prompt = "The person I am dating demands my live location all day. They say I must be hiding something if I turn it off.",
				Choices = {
					"Keep sharing it so they do not become angry; wait for their next response.",
					"Explain that constant tracking is not a requirement for trust and turn it off if you want.",
					"Give the phone to a friend so the location looks different; cooperate again if they insist.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They replied, 'If you loved me, you would have nothing to hide.'",
				Choices = {
					"Apologize and turn tracking back on; follow any additional instructions the other person gives afterward.",
					"State that guilt is not consent, repeat the boundary, and seek support if the pressure continues.",
					"Ignore the concern but continue the relationship unchanged; avoid discussing it with anyone else.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-045",
		Title = "Pressured To Vape",
		Difficulty = 3,
		Skill = "Resisting peer pressure",
		Feedback = "A respectful friend can accept a clear no without punishment or pressure.",
		Stages = {
			{
				Prompt = "My friends keep pressuring me to vape. They say I am ruining the mood by refusing.",
				Choices = {
					"Try it once so they stop asking; continue without asking for help.",
					"Clearly refuse, leave if the pressure continues, and spend time with people who respect the decision.",
					"Pretend to use it without inhaling; keep the entire situation private unless it becomes worse.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-046",
		Title = "Rumor Threat",
		Difficulty = 3,
		Skill = "Responding to coercion",
		Feedback = "Coercion usually grows when rewarded. Preserve evidence and involve responsible support.",
		Stages = {
			{
				Prompt = "A classmate says they will spread a false rumor unless I do their homework.",
				Choices = {
					"Complete the homework to keep the peace; make no other attempt to resolve the issue afterward.",
					"Save the message, refuse the demand, and report the threat to a trusted adult or school staff.",
					"Meet them alone and threaten them; continue the confrontation until the other person gives in.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-047",
		Title = "Publicly Humiliated By A Coach",
		Difficulty = 3,
		Skill = "Reporting repeated misconduct",
		Feedback = "Repeated humiliation by an authority figure should be documented and reported through appropriate channels.",
		Stages = {
			{
				Prompt = "My coach regularly calls me useless in front of the team. Private conversations have not stopped it.",
				Choices = {
					"Insult the coach during practice; continue until they give in.",
					"Record dates and details, then speak with a parent or program leader.",
					"Encourage the entire team to refuse practice without explanation; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-048",
		Title = "Constant Family Insults",
		Difficulty = 3,
		Skill = "Boundaries and support networks",
		Feedback = "Apologies do not erase a repeated pattern. Boundaries and outside support may be necessary.",
		Stages = {
			{
				Prompt = "A family member calls me names whenever they are angry. They later say I should know they do not mean it.",
				Choices = {
					"Use harsher names in return; wait for the other person to decide what happens next.",
					"Explain that anger does not make insults acceptable, leave the conversation when possible, and seek support if it continues.",
					"Accept every insult because they apologize later; continue the confrontation until the other person gives in.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-049",
		Title = "Customer Threatens An Employee",
		Difficulty = 3,
		Skill = "De-escalation with boundaries",
		Feedback = "Empathy does not require accepting intimidation. Escalate to trained support when behavior becomes threatening.",
		Stages = {
			{
				Prompt = "A customer at my job is shouting because a coupon expired. They say they will get me fired.",
				Choices = {
					"Shout that the rules are not your fault; insist on an apology.",
					"Acknowledge the frustration, explain the policy briefly, and offer available options.",
					"Give any discount they demand; wait to see if they stop.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They step closer and say, 'I am not leaving until you fix this.'",
				Choices = {
					"Set a clear boundary, create distance, and call a supervisor or security under workplace policy.",
					"Push them away right away; demand an apology before stopping the confrontation.",
					"Lock the doors with the customer inside; wait for their next response.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-050",
		Title = "Money Guilt",
		Difficulty = 3,
		Skill = "Recognizing emotional manipulation",
		Feedback = "A boundary is not selfish. Guilt should not replace consent or repayment.",
		Stages = {
			{
				Prompt = "My friend says I must lend them money or I am selfish. They still have not repaid the last loan.",
				Choices = {
					"Lend more to protect the friendship; cooperate again if they insist.",
					"Say no clearly and separate the friendship from financial pressure; reassess the situation afterward.",
					"Take money from their bag later; continue without asking for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-051",
		Title = "Harassment At A Teen Job",
		Difficulty = 3,
		Skill = "Workplace reporting",
		Feedback = "Repeated workplace harassment should be documented and raised through responsible channels.",
		Stages = {
			{
				Prompt = "A coworker repeatedly insults me and hides my supplies. My manager says we should work it out ourselves.",
				Choices = {
					"Document the incidents and report them again through a supervisor, owner, parent, or formal workplace process.",
					"Threaten the coworker after work; continue the confrontation until the other person gives in.",
					"Stop showing up without telling anyone; continue with the same approach if the problem returns.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-052",
		Title = "Identity-Based Teasing",
		Difficulty = 3,
		Skill = "Safe intervention and reporting",
		Feedback = "Targeted harassment is not made harmless by calling it a joke. Seek support rather than retaliating.",
		Stages = {
			{
				Prompt = "Students keep mocking my accent and background. They say I cannot take a joke.",
				Choices = {
					"State that the comments are unwelcome, leave if needed, document the pattern, and tell a trusted adult.",
					"Change the way you speak so they stop; continue without asking for help.",
					"Challenge the group to a fight; continue the confrontation until the other person gives in.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-053",
		Title = "Impersonation Account",
		Difficulty = 3,
		Skill = "Digital evidence and reporting",
		Feedback = "Threats increase the need for evidence and support; they do not make retaliation safer.",
		Stages = {
			{
				Prompt = "Someone made an account using my name and photo. It is posting rude messages as if they came from me.",
				Choices = {
					"Make a fake account of the suspected person; continue without asking for help.",
					"Save screenshots and links, report the account for impersonation, and tell trusted contacts the account is fake.",
					"Delete your real account permanently; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The fake account now says it will post edited pictures if I keep reporting it.",
				Choices = {
					"Stop reporting and obey the account; avoid telling anyone while you wait for the pressure to stop.",
					"Preserve the new threat, avoid negotiating, and involve a trusted adult, school, platform, or law enforcement if safety is threatened.",
					"Offer money for the password; wait for the other person to decide what happens next; wait for it to disappear.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-054",
		Title = "Fight Video",
		Difficulty = 3,
		Skill = "Refusing to amplify harm",
		Feedback = "Sharing humiliating or violent footage can deepen harm and reward the conflict.",
		Stages = {
			{
				Prompt = "My friends recorded a fight and want me to repost it because it will get attention.",
				Choices = {
					"Post it with a funny caption; ask more people to share it and support your side.",
					"Refuse to share it, encourage checking on anyone hurt, and report serious violence to an adult or platform.",
					"Edit it to make one person look worse; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-055",
		Title = "Project Sabotage",
		Difficulty = 3,
		Skill = "Documentation and mediation",
		Feedback = "Use records and a shared process to stop sabotage without copying it.",
		Stages = {
			{
				Prompt = "A group member keeps deleting my work because they want their idea chosen.",
				Choices = {
					"Delete all of their work; wait for the problem to disappear without taking another step.",
					"Preserve version history, ask the group to set editing rules, and involve the teacher if it continues.",
					"Lock everyone out of the file; continue posting updates until public pressure changes the outcome.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-056",
		Title = "Move The Chat",
		Difficulty = 3,
		Skill = "Online safety and boundaries",
		Feedback = "Requests for secrecy and isolation are major warning signs, especially from an unknown adult or older person.",
		Stages = {
			{
				Prompt = "A stranger in a game says I seem mature and wants me to move to a private messaging app.",
				Choices = {
					"Move the conversation so moderators cannot read it; make no further changes.",
					"Keep personal information private, decline the request, and block or report suspicious behavior.",
					"Give them a temporary account; wait to see if they stop.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They say, 'Do not tell your parents. They would not understand our friendship.'",
				Choices = {
					"Keep the secret because they trust you; make no further changes.",
					"End contact, save relevant evidence, and tell a trusted adult; reassess the situation afterward.",
					"Meet them to prove the friendship is real; continue without outside support.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-057",
		Title = "Friendship Ultimatum",
		Difficulty = 3,
		Skill = "Resisting controlling demands",
		Feedback = "Concerns can be discussed, but healthy friendship does not require control or isolation.",
		Stages = {
			{
				Prompt = "My friend says I must stop talking to another person or our friendship is over.",
				Choices = {
					"Ask about the concern, but explain that they cannot control all of your friendships.",
					"Give them the same ultimatum; wait to see if they stop.",
					"Lie about seeing the other person; continue without asking for help.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-058",
		Title = "Teammate Shoves Me",
		Difficulty = 3,
		Skill = "Safety and reporting",
		Feedback = "Physical aggression requires a safety response and adult involvement, not retaliation.",
		Stages = {
			{
				Prompt = "A teammate shoves me when they get angry. The coach has not noticed.",
				Choices = {
					"Shove them harder next time; continue the confrontation until the other person gives in.",
					"Move away, state that physical contact is not acceptable, and tell the coach or another trusted adult.",
					"Hide the behavior because the team needs them; avoid discussing it with anyone else.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-059",
		Title = "Repeatedly Missing Items",
		Difficulty = 3,
		Skill = "Avoiding unsupported accusations",
		Feedback = "Protect yourself and report facts without conducting your own search or making an unproven accusation.",
		Stages = {
			{
				Prompt = "Small items keep disappearing from my backpack, and I suspect a classmate.",
				Choices = {
					"Search the classmate's bag; wait for the other person to decide what happens next.",
					"Secure your belongings, document what is missing, and report the pattern without claiming certainty you do not have.",
					"Announce that they are a thief; invite the wider group to judge who handled it correctly.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-060",
		Title = "Secret Gifts From A Mentor",
		Difficulty = 3,
		Skill = "Recognizing boundary violations",
		Feedback = "Secret special treatment and isolation requests can be warning signs. Report; do not investigate alone.",
		Stages = {
			{
				Prompt = "An adult mentor gives me expensive gifts and says I am their favorite. They tell me not to mention it because others will be jealous.",
				Choices = {
					"Keep the gifts and the secret; continue without asking for help.",
					"Tell a trusted adult and avoid being alone with the mentor until it is reviewed.",
					"Post about the gifts but do not tell anyone responsible; share it with more people.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The mentor is now asking me to meet alone outside the program.",
				Choices = {
					"Go so they do not feel rejected; make no other attempt to resolve the issue afterward.",
					"Do not meet alone, save the messages, and report the request to a trusted adult or program leader.",
					"Threaten the mentor publicly; continue the confrontation until the other person gives in; insist on an apology.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-061",
		Title = "Private Image Blackmail",
		Difficulty = 4,
		Skill = "Recognizing sextortion and seeking help",
		Feedback = "Blackmailers use urgency and shame to isolate victims. Preserve evidence, seek help quickly, and do not reward the demand.",
		ContentFlag = "Sensitive online exploitation; optional 13+ module",
		Stages = {
			{
				Prompt = "Someone obtained private images of me and says they will send them to my school unless I pay $1,000.",
				Choices = {
					"Send more material to prove you trust them; continue without asking for help.",
					"Do not pay or send more; preserve the messages and tell a trusted adult right away.",
					"Delete the entire conversation before anyone sees it; avoid discussing it with anyone else.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They say I have ten minutes and that telling anyone will make things worse.",
				Choices = {
					"Follow their deadline because there is no time for help; continue without outside support.",
					"Keep the evidence, stop negotiating, and report through the platform and authorities with trusted support.",
					"Send a partial payment; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-062",
		Title = "Doxxing Threat",
		Difficulty = 4,
		Skill = "Digital safety planning",
		Feedback = "Partial personal information can still be used to intimidate. Reduce exposure and involve support rather than testing the threat.",
		Stages = {
			{
				Prompt = "An online player says they found my address and will post it unless I give them my rare items.",
				Choices = {
					"Challenge them to prove they know the address; continue without outside support.",
					"Save the threat, stop engaging, secure your accounts, and tell a trusted adult.",
					"Agree to meet them; continue cooperating until the other person ends the demand.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They post the name of my street, but not my house number.",
				Choices = {
					"Assume it is a bluff and continue playing with them; make no other attempt to resolve the issue afterward.",
					"Treat it seriously, report it, review exposed account information, and involve local authorities if there is a credible safety threat.",
					"Delete your account without preserving evidence; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-063",
		Title = "Threats Through A Fake Account",
		Difficulty = 4,
		Skill = "Evidence and safety escalation",
		Feedback = "Specific details involving a child or location require immediate protective action and responsible authorities.",
		Stages = {
			{
				Prompt = "A new account is sending threats about my family. I do not know who is behind it.",
				Choices = {
					"Reply with threats against their family; handle the rest of it alone.",
					"Preserve the messages, block or report the account, and tell a trusted adult.",
					"Ignore every message even if details become specific; keep the situation completely private.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The account now mentions where my younger sibling gets picked up after school.",
				Choices = {
					"Keep it secret so your sibling does not worry; keep the entire situation private unless it becomes worse.",
					"Inform caregivers and the school right away, change the pickup plan, and contact law enforcement about the specific threat.",
					"Send your sibling to confront whoever appears; handle every later response without asking anyone else for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-064",
		Title = "Stalking After A Breakup",
		Difficulty = 4,
		Skill = "Safety planning and documentation",
		Feedback = "Persistent unwanted contact and following are safety concerns. Do not rely on a private confrontation to end the behavior.",
		Stages = {
			{
				Prompt = "My former partner waits outside my classes and keeps creating new accounts after I block them.",
				Choices = {
					"Meet alone and demand that they stop; continue the discussion privately until the other person agrees.",
					"Save records, tell trusted adults or school staff, change routines when practical, and avoid being alone with them.",
					"Ask a friend to scare them; continue the confrontation until the other person gives in.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They followed me toward home today and said we need one final conversation.",
				Choices = {
					"Go to a populated safe place, contact a trusted person or emergency services, and do not go home alone if followed.",
					"Lead them to a remote area and confront them; handle every later response without asking anyone else for help.",
					"Turn off your phone so nobody can track you; wait for the other person to decide what happens next.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-065",
		Title = "Specific School Violence Threat",
		Difficulty = 4,
		Skill = "Urgent reporting",
		Feedback = "A specific weapon threat is not a conflict to mediate. Report promptly and let trained authorities assess it.",
		Stages = {
			{
				Prompt = "A student posted that they will bring a weapon to school tomorrow. They included a photo that might be real.",
				Choices = {
					"Reply that they are not brave enough; settle everything face to face.",
					"Save the information and right away tell a trusted adult, school official, or police.",
					"Wait until tomorrow to see if they arrive; wait for it to disappear.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "My friend says reporting it could ruin the student's life if it was only a joke.",
				Choices = {
					"Delete the evidence to protect the student; keep the situation completely private.",
					"Report it anyway; responsible adults can evaluate credibility and protect everyone; reassess the situation afterward.",
					"Ask the student privately if they are serious; make no further changes.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-066",
		Title = "Gaming Account Extortion",
		Difficulty = 4,
		Skill = "Account security and refusal",
		Feedback = "Use trusted platform recovery and protect connected accounts. Paying or sharing more access can deepen the loss.",
		Stages = {
			{
				Prompt = "Someone says they stole my gaming account and will delete everything unless I buy them a gift card.",
				Choices = {
					"Pay before they change their mind; wait to see if they stop.",
					"Use official account recovery, change related passwords, enable stronger security, and report the extortion.",
					"Send personal documents to prove ownership directly to them; make no further changes.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They send a screenshot showing that they can access my account.",
				Choices = {
					"Continue only through official recovery and support channels; preserve the screenshot as evidence.",
					"Pay half now and half later; wait to see if they stop.",
					"Ask strangers online to recover it for a fee; share it with more people.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-067",
		Title = "Threatened At A Teen Job",
		Difficulty = 4,
		Skill = "Workplace safety and adult support",
		Feedback = "A young worker should not face intimidation or physical aggression alone. Use outside support and formal channels.",
		Stages = {
			{
				Prompt = "My manager says they will cut all my hours if I report that they yell at and shove employees.",
				Choices = {
					"Stay quiet because the manager controls the schedule; keep the situation completely private.",
					"Document what happened and tell a parent, owner, human-resources contact, or appropriate labor authority.",
					"Threaten to invent a story unless they pay you; insist on an apology.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The manager says I must meet alone after closing to discuss my attitude.",
				Choices = {
					"Attend alone to prove you are responsible; continue with the same approach if the problem returns.",
					"Decline an unsafe private meeting and arrange for a trusted adult or appropriate representative to be involved.",
					"Agree but hide from everyone where you are; invite the group to judge them.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-068",
		Title = "Hazing Pressure",
		Difficulty = 4,
		Skill = "Refusing dangerous group coercion",
		Feedback = "Forced confinement or threats turn hazing into an urgent safety issue. Seek immediate help.",
		Stages = {
			{
				Prompt = "A team says I must complete a humiliating challenge to prove I belong. They threaten to exclude me if I refuse.",
				Choices = {
					"Refuse, leave it, and tell a coach, school official, caregiver, or program leader.",
					"Create a worse challenge for future members; settle everything face to face.",
					"Film it for proof that you are tough; share it with more people.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They take my phone and say I cannot leave until I finish.",
				Choices = {
					"Move toward safety, call for help promptly, and contact emergency services if you are being restrained or threatened.",
					"Try to injure the nearest person; wait for the other person to decide what happens next.",
					"Promise revenge later; continue the confrontation until the other person gives in; insist on an apology.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-069",
		Title = "Emergency Impersonation Scam",
		Difficulty = 4,
		Skill = "Verifying urgent claims",
		Feedback = "Urgency and secrecy are common manipulation tactics. Verify using contact information you already trust.",
		Stages = {
			{
				Prompt = "I received a message that appears to be from my cousin. It says they were arrested and need gift cards immediately.",
				Choices = {
					"Verify through a known phone number or another trusted relative before sending anything.",
					"Post the gift-card codes in the chat; share it with more people.",
					"Ask the message to send a selfie and trust any image received.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "The sender says I must not contact the family because it would embarrass my cousin.",
				Choices = {
					"Stop and verify independently; secrecy and urgent unusual payment methods are warning signs.",
					"Send a small amount as a test; continue without asking for help.",
					"Share your identification to show you are trustworthy; share it with more people.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-070",
		Title = "\"I Will Hurt Myself If You Leave\"",
		Difficulty = 4,
		Skill = "Taking threats seriously without accepting control",
		Feedback = "A crisis threat deserves professional help, but it should not be used to trap another person in a relationship.",
		ContentFlag = "Emotional crisis; optional 13+ module",
		Stages = {
			{
				Prompt = "My partner says they will hurt themselves if I end the relationship. I am scared to leave.",
				Choices = {
					"Stay in the relationship forever to keep them safe; wait to see if they stop.",
					"Treat the threat seriously, involve a trusted adult or crisis professional, and do not manage it alone.",
					"Tell them they are only seeking attention; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They say I am the only person who can save them and I may not tell anyone.",
				Choices = {
					"Refuse secrecy, contact crisis support or emergency services if danger appears immediate, and maintain your own safety boundary.",
					"Block them without alerting anyone despite a specific plan; wait for their next response.",
					"Publicly shame them; ask more people to share it and support your side; share it with more people.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-071",
		Title = "Intoxicated Driver",
		Difficulty = 4,
		Skill = "Preventing immediate danger",
		Feedback = "Impaired driving creates immediate danger. Get trained help rather than entering the vehicle or using risky physical force.",
		Stages = {
			{
				Prompt = "My parent has been drinking and insists on driving us home. They become angry when I take the keys.",
				Choices = {
					"Refuse to get in, seek another safe ride, and contact a trusted adult or emergency services if they attempt to drive.",
					"Let them drive but ask them to go slowly; wait for the other person to decide what happens next.",
					"Insult them until they hand over the keys; continue the confrontation until the other person gives in.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They start the car and my younger sibling is already inside.",
				Choices = {
					"Get in so your sibling is not alone; make no other attempt to resolve the issue afterward.",
					"Call emergency services and alert a safe adult right away; do not physically stand in front of the vehicle.",
					"Wait to see if they crash; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-072",
		Title = "A Weapon At School",
		Difficulty = 4,
		Skill = "Distance and urgent reporting",
		Feedback = "Do not touch, investigate, or bargain around a weapon. Create distance and report immediately.",
		Stages = {
			{
				Prompt = "A friend quietly showed me a weapon in their backpack and said not to tell anyone.",
				Choices = {
					"Move away safely and right away tell a trusted adult, school official, or police.",
					"Keep the secret because they are your friend; make no further changes.",
					"Post a picture in the class chat; share it with more people.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They notice I am nervous and say, 'You will regret it if you tell.'",
				Choices = {
					"Do not confront them; get to safety and report the threat as urgently as possible.",
					"Challenge them to use it; manage the remaining problem without involving outside support.",
					"Tell only one student to avoid them; continue without asking for help.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-073",
		Title = "Property Destruction And Threats",
		Difficulty = 4,
		Skill = "Recognizing escalating violence",
		Feedback = "Destroying property and blocking exits can signal escalating danger. Safety comes before resolving the disagreement.",
		Stages = {
			{
				Prompt = "A family member punches walls and breaks objects during arguments. They have not hit me, but I feel unsafe.",
				Choices = {
					"Treat the behavior as a safety warning, move away, and discuss a safety plan with trusted support.",
					"Stand close and challenge them; handle every later response without asking anyone else for help.",
					"Tell them physical violence is fine if it avoids yelling; wait for their next response.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "Tonight they block the doorway and say nobody is leaving until the argument is finished.",
				Choices = {
					"Try to push through them; continue the confrontation until the other person gives in; insist on an apology.",
					"Avoid escalating, seek another safe exit or protected area, and contact emergency services if you are being trapped or threatened.",
					"Continue the argument until they calm down; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-074",
		Title = "Violent Customer At The Counter",
		Difficulty = 4,
		Skill = "Workplace emergency response",
		Feedback = "Once physical aggression begins, protect people and summon trained help rather than continuing customer service.",
		Stages = {
			{
				Prompt = "A customer is screaming, hitting the counter, and threatening staff over a refund.",
				Choices = {
					"Argue until they admit the policy is fair; settle everything face to face.",
					"Create distance, use calm brief language, and alert a supervisor or security according to policy.",
					"Offer unlimited money to make them leave; continue without asking for help.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The customer reaches over the counter and tries to grab an employee.",
				Choices = {
					"Move people to safety and contact security or emergency services right away.",
					"Encourage customers to restrain the person; continue without asking for help.",
					"Throw objects at them; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-075",
		Title = "Unwanted Explicit Messages",
		Difficulty = 4,
		Skill = "Digital consent and reporting",
		Feedback = "Repeated contact plus location knowledge increases the safety concern and requires outside support.",
		ContentFlag = "Sensitive sexual harassment; optional 13+ module",
		Stages = {
			{
				Prompt = "Someone keeps sending me sexual messages after I told them to stop.",
				Choices = {
					"Reply with sexual content so they lose interest; manage the remaining problem without involving outside support.",
					"Save relevant evidence, block and report the account, and tell a trusted adult if you are a minor.",
					"Delete everything and say nothing; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They create another account and say they know where I go to school.",
				Choices = {
					"Continue blocking without telling anyone; wait for the other person to decide what happens next.",
					"Preserve the new threat, involve trusted adults and the school, and contact law enforcement if the threat is credible.",
					"Send them your schedule to prove you are not afraid; continue without asking for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-076",
		Title = "Secret Meeting With An Adult",
		Difficulty = 4,
		Skill = "Recognizing grooming and isolation",
		Feedback = "Adults should not isolate minors or demand secrecy. Trusted adults and program leaders should review the behavior.",
		Stages = {
			{
				Prompt = "An adult from my activity sends private messages and asks me to meet alone. They say I am more mature than everyone else.",
				Choices = {
					"Do not meet alone; save the messages and tell a trusted adult or program leader.",
					"Delete the messages to protect the adult; avoid discussing it with anyone else.",
					"Bring one friend but tell no adults; wait for their next response.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They say the meeting must stay secret because other people would misunderstand.",
				Choices = {
					"Keep the secret to protect their reputation; continue without asking for help.",
					"End the private contact and report the secrecy request; do not investigate or confront them alone.",
					"Give them your home address instead; follow any additional instructions the other person gives afterward.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-077",
		Title = "Hate-Based Threat",
		Difficulty = 4,
		Skill = "Safety, documentation, and support",
		Feedback = "A targeted threat tied to a location or event requires prompt safety coordination.",
		Stages = {
			{
				Prompt = "Someone sent me a threat because of my religion, race, disability, or identity.",
				Choices = {
					"Send a threat targeting their identity; wait for their next response.",
					"Preserve the message, report it, and tell trusted adults or responsible authorities.",
					"Publish your location to challenge them; handle the rest of it alone.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The sender names an event I plan to attend tomorrow.",
				Choices = {
					"Attend alone to prove you are not afraid; make no other attempt to resolve the issue afterward.",
					"Inform event organizers and law enforcement, review the safety plan, and avoid predictable exposure until the threat is assessed.",
					"Bring an untrained group to confront them; handle every later response without asking anyone else for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-078",
		Title = "Revenge Assault Plan",
		Difficulty = 4,
		Skill = "Interrupting planned violence",
		Feedback = "Specific plans make the threat urgent. Share actionable details with people trained to prevent violence.",
		Stages = {
			{
				Prompt = "My friend says they are going to beat up someone after school for humiliating them.",
				Choices = {
					"Help plan it so nobody gets caught; continue without asking for help.",
					"Take the threat seriously, discourage the violence, and tell a trusted adult or school official.",
					"Film the fight; continue the confrontation until the other person gives in.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They show me where they will wait and say they already invited others.",
				Choices = {
					"Immediately report the specific time and place to responsible adults or law enforcement; do not personally intervene in the confrontation.",
					"Invite more people to stop it by force; wait for the other person to decide what happens next.",
					"Delete the messages; wait for the problem to disappear without taking another step; wait for it to disappear.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-079",
		Title = "Forced Into A Theft",
		Difficulty = 4,
		Skill = "Coercion, safety, and reporting",
		Feedback = "Coercion does not make a private confrontation safe. Seek immediate adult or emergency support.",
		Stages = {
			{
				Prompt = "Older students say I must help steal from a store or they will hurt me after school.",
				Choices = {
					"Participate because you have no choice; make no other attempt to resolve the issue afterward.",
					"Get to a safe adult, preserve any messages, and report the threat before the planned event.",
					"Carry a weapon for protection; continue the confrontation until the other person gives in.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They are waiting near the exit and messaging me to come outside alone.",
				Choices = {
					"Stay in a staffed public area, call a trusted adult or emergency services, and do not meet them alone.",
					"Ask another child to deliver a message; wait for the other person to decide what happens next.",
					"Post insults about them; ask more people to share it and support your side; share it with more people.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-080",
		Title = "Online Predator Demands More Images",
		Difficulty = 4,
		Skill = "Ending exploitation and reporting",
		Feedback = "Victims deserve help and are not responsible for an offender's coercion. Secrecy protects the exploiter, not the victim.",
		ContentFlag = "Sensitive child-safety topic; optional 13+ module",
		Stages = {
			{
				Prompt = "An online person convinced me to send a private image. Now they demand more and threaten to share the first one.",
				Choices = {
					"Send one more and ask them to delete everything; avoid discussing it with anyone else.",
					"Stop responding, preserve evidence, tell a trusted adult, and report the account to the platform and authorities.",
					"Meet them in person; handle every later response without asking anyone else for help.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They claim I will get in trouble because I sent the first image.",
				Choices = {
					"Believe them and obey; avoid telling anyone while you wait for the pressure to stop.",
					"Recognize that the exploiter is responsible, seek help right away, and do not allow shame to keep it secret.",
					"Blame yourself and erase the evidence; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-081",
		Title = "Violence At Home",
		Difficulty = 5,
		Skill = "Domestic-violence safety planning",
		Feedback = "Abuse is not solved by better arguing. Safety planning should be private, personalized, and supported by trained advocates.",
		ContentFlag = "Abuse; optional advanced module",
		Stages = {
			{
				Prompt = "My husband yells at me and our children, controls the money, and hits me. I am afraid that trying to leave could make things worse.",
				Choices = {
					"Confront him during the next argument and demand an immediate change; continue without outside support.",
					"Contact a domestic-violence advocate or trusted professional from a safe device and build a personalized safety plan.",
					"Accept the abuse to keep the family together; continue without asking for help.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "He checks my phone and says he will take the children if I tell anyone.",
				Choices = {
					"Search for help only on the monitored phone; wait for the other person to decide what happens next.",
					"Use a safer device or trusted contact when possible, protect important information, and call emergency services if danger becomes immediate.",
					"Threaten him with the same behavior; continue the confrontation until the other person gives in; insist on an apology.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-082",
		Title = "Child Witnesses Violence",
		Difficulty = 5,
		Skill = "Child safety during family violence",
		Feedback = "Children should not be placed between violent adults. Get to safety and involve responsible help.",
		ContentFlag = "Family violence; optional advanced module",
		Stages = {
			{
				Prompt = "My caregivers are fighting violently. One tells me to stand between them and make the other stop.",
				Choices = {
					"Move to a safer location away from the conflict and contact a trusted adult or emergency services.",
					"Choose one caregiver's side and join the argument; continue without asking for help.",
					"Record from nearby; invite the wider group to judge who handled it correctly.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "My younger sibling is crying in the next room.",
				Choices = {
					"Return to the fight to demand that it stop; continue the confrontation until the other person gives in.",
					"Bring the sibling to the safest available place if you can do so without approaching the violence, then call for help.",
					"Stay silent because family matters must remain private; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-083",
		Title = "Assault In Public",
		Difficulty = 5,
		Skill = "Emergency response without creating another victim",
		Feedback = "Helping does not require entering the attack. Summon trained help, provide information, and avoid becoming another victim.",
		Stages = {
			{
				Prompt = "I see someone being attacked in a parking lot. I want to help, but the attacker is much larger than me.",
				Choices = {
					"Move to safety, call emergency services, alert nearby security or adults, and give clear location details.",
					"Film silently for social media; continue posting updates until public pressure changes the outcome.",
					"Leave without telling anyone; wait for the problem to disappear without taking another step.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "The attacker looks toward me and starts moving in my direction.",
				Choices = {
					"Create distance, enter a secure populated place if possible, and update emergency services.",
					"Challenge them to follow you; manage the remaining problem without involving outside support.",
					"Throw objects and remain in place; wait for their next response.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-084",
		Title = "Child Discloses Abuse",
		Difficulty = 5,
		Skill = "Believing, protecting, and reporting",
		Feedback = "The role is to listen, protect, and report—not conduct a private investigation or force a confrontation.",
		ContentFlag = "Child abuse; adult-player or advanced module",
		Stages = {
			{
				Prompt = "A child tells me that an adult at home hurts them and makes them keep it secret.",
				Choices = {
					"Question the child repeatedly until every detail is proven; wait for the other person to decide what happens next.",
					"Stay calm, listen without blaming, explain that you need to get safe help, and report through appropriate child-protection or emergency channels.",
					"Confront the accused adult alone right away; handle every later response without asking anyone else for help.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The child says they are afraid they will be punished for telling.",
				Choices = {
					"Withdraw the report to reduce their fear; make no other attempt to resolve the issue afterward.",
					"Reassure them that the abuse is not their fault, avoid coaching their story, and continue obtaining qualified protection.",
					"Post the allegation publicly; ask more people to share it and support your side.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-085",
		Title = "Dating Violence",
		Difficulty = 5,
		Skill = "Immediate safety and support",
		Feedback = "Recent violence plus an unwanted appearance at home creates an urgent safety concern.",
		ContentFlag = "Relationship abuse; optional advanced module",
		Stages = {
			{
				Prompt = "My partner grabbed and hurt me during an argument. They apologized and say it will never happen again.",
				Choices = {
					"Meet alone to make them promise again; handle the rest of it alone.",
					"Treat the physical aggression seriously, tell a trusted person, and seek help creating a safe plan.",
					"Hide it because apologies solve the problem; wait for their next response.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They are outside my home now, demanding that I come out and talk.",
				Choices = {
					"Stay in a secure place, alert trusted people, and call emergency services if they will not leave or threaten entry.",
					"Invite them inside to keep the neighbors from noticing; make no other attempt to resolve the issue afterward.",
					"Send a friend outside to fight them; continue the confrontation until the other person gives in.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-086",
		Title = "Threatened With A Weapon",
		Difficulty = 5,
		Skill = "Survival and urgent reporting",
		Feedback = "When a weapon is present, winning the argument is irrelevant. Escape and trained emergency response come first.",
		Stages = {
			{
				Prompt = "During an argument, someone shows a weapon and says I cannot leave.",
				Choices = {
					"Avoid sudden confrontation, look for a safe opportunity to get away, and contact emergency services promptly.",
					"Insult them to show confidence; continue the confrontation until the other person gives in.",
					"Reach into your pocket without explanation; continue with the same approach if the problem returns.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They become distracted and the exit is clear.",
				Choices = {
					"Leave quickly without escalating, move to safety, and call emergency services; reassess the situation afterward.",
					"Announce that you are going to report them; share it with more people.",
					"Lock yourself in another room without a way to call for help; make no further changes.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-087",
		Title = "Detailed School Attack Plan",
		Difficulty = 5,
		Skill = "Immediate threat reporting",
		Feedback = "Detailed, time-specific threats require immediate authority involvement and compliance with emergency procedures.",
		Stages = {
			{
				Prompt = "A student sends me a detailed plan for attacking the school, including a date, entrance, and list of targets.",
				Choices = {
					"Ask if you can join so you learn more; make no further changes.",
					"Preserve the message and right away contact emergency services, school officials, and a trusted adult.",
					"Post the full plan publicly; continue posting updates until public pressure changes the outcome.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The planned date is today, and the student is not in class.",
				Choices = {
					"Follow official emergency instructions, share the information with authorities, and do not investigate personally.",
					"Leave through any door without alerting staff; continue without asking for help.",
					"Tell everyone to run in different directions; ask others to support your side.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-088",
		Title = "Stalker Outside The Home",
		Difficulty = 5,
		Skill = "Securing a location and coordinating help",
		Feedback = "Attempted entry is an immediate emergency. Remain secured and get professional help.",
		Stages = {
			{
				Prompt = "A person who has been stalking me is sitting in a car outside my home.",
				Choices = {
					"Stay inside a secure location, contact law enforcement and a trusted person, and document only from safety if possible.",
					"Invite them in to discuss why they are there; continue with the same approach if the problem returns.",
					"Walk past the car to test if they follow; manage the remaining problem without involving outside support.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They leave the car and begin trying the door handle.",
				Choices = {
					"Open the door and tell them to stop; continue without asking for help.",
					"Move away from entry points, call emergency services, and follow dispatcher instructions; reassess the situation afterward.",
					"Stand at the window and argue; handle the rest of it alone.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-089",
		Title = "Sextortion Release In Progress",
		Difficulty = 5,
		Skill = "Urgent exploitation response",
		Feedback = "The offender—not the victim—is responsible for the exploitation. Help remains valuable even after content is shared.",
		ContentFlag = "Sensitive online exploitation; optional 13+ module",
		Stages = {
			{
				Prompt = "The person blackmailing me has started sending a private image to classmates. I feel like there is no point asking for help now.",
				Choices = {
					"Pay them to stop the remaining messages; follow any additional instructions the other person gives afterward.",
					"Tell a trusted adult right away, preserve evidence, report the accounts and content, and seek specialized support.",
					"Send more images in exchange for a promise; continue without asking for help.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The offender says the sharing is my fault because I refused to pay.",
				Choices = {
					"Recognize that the offender is responsible, continue reporting and removal efforts, and receive emotional support rather than facing it alone.",
					"Delete all evidence out of shame; wait for the problem to disappear without taking another step.",
					"Retaliate by sharing other people's images; wait for the other person to decide what happens next.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-090",
		Title = "Friend Afraid To Go Home",
		Difficulty = 5,
		Skill = "Protecting a child from immediate family violence",
		Feedback = "A child reporting recent violence needs responsible adult protection, not a secret plan managed by another child.",
		Stages = {
			{
				Prompt = "My friend says their parent attacked them last night and is waiting angrily at home. They beg me not to tell anyone.",
				Choices = {
					"Stay with them in a safe public or supervised place and contact a trusted adult, school counselor, child-protection service, or emergency services.",
					"Hide the friend in your home without informing any adult; wait for the other person to decide what happens next.",
					"Tell them to apologize to the parent; avoid telling anyone while you wait for the pressure to stop.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "The parent arrives at school and demands that my friend get into the car.",
				Choices = {
					"Alert school staff or security and do not personally block or confront the parent.",
					"Create a distraction so the friend can run alone; make no further changes.",
					"Film without notifying staff; continue posting updates until public pressure changes the outcome.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-091",
		Title = "Road-Rage Pursuit",
		Difficulty = 5,
		Skill = "Safe escape and emergency communication",
		Feedback = "Avoid direct engagement and do not lead a pursuer home. Coordinate with emergency services while driving safely.",
		Stages = {
			{
				Prompt = "An angry driver is following me, honking, and trying to force my car to stop.",
				Choices = {
					"Drive home as quickly as possible; handle every later response without asking anyone else for help.",
					"Keep doors locked, avoid engaging, call emergency services hands-free, and drive toward a police station or busy public place.",
					"Lead them onto a quiet road; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They pull beside me and point for me to pull over.",
				Choices = {
					"Continue toward a safe populated location, follow dispatcher instructions, and do not reveal your home address.",
					"Display a weapon; continue the confrontation until the other person gives in.",
					"Start recording while ignoring the road; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-092",
		Title = "Group Attack Planned",
		Difficulty = 5,
		Skill = "Preventing coordinated violence",
		Feedback = "Coordinated violence with a time, place, and weapons requires urgent professional intervention.",
		Stages = {
			{
				Prompt = "Several students are organizing a group attack on one person after an event. They share a meeting place and weapons in the chat.",
				Choices = {
					"Warn only the intended target and let them handle it; wait for their next response.",
					"Preserve the specific information and right away report it to responsible adults, event security, and law enforcement.",
					"Post the plan publicly with everyone's location; continue posting updates until public pressure changes the outcome.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The group says they are leaving now.",
				Choices = {
					"Go to the location to watch; continue without asking for help; make no further changes.",
					"Update authorities with the timing and stay away from the planned confrontation; reassess the situation afterward.",
					"Delete the chat to stop rumors; avoid discussing it with anyone else.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-093",
		Title = "Armed Threat At Work",
		Difficulty = 5,
		Skill = "Emergency workplace response",
		Feedback = "Armed emergencies require established emergency procedures, not improvised mediation.",
		Stages = {
			{
				Prompt = "A former employee enters the workplace, shows a weapon, and demands to see the manager.",
				Choices = {
					"Try to explain that the manager is busy; continue with the same approach if the problem returns.",
					"Follow the site's emergency plan: escape if safely possible, otherwise secure or hide, and contact emergency services when safe.",
					"Challenge them to calm down; handle every later response without asking anyone else for help.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The safest exit becomes available while the person looks away.",
				Choices = {
					"Stop to warn the armed person you are leaving; make no further changes.",
					"Leave quietly, keep hands visible when responders arrive, and follow law-enforcement instructions; reassess the situation afterward.",
					"Shout directions that reveal hidden people; demand that they back down; insist on an apology.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-094",
		Title = "Elder Abuse By A Caregiver",
		Difficulty = 5,
		Skill = "Protecting a vulnerable adult",
		Feedback = "Vulnerable adults may need protection through qualified services; private confrontation can increase risk.",
		ContentFlag = "Abuse; advanced module",
		Stages = {
			{
				Prompt = "My elderly neighbor says their caregiver takes their money, insults them, and sometimes prevents them from using the phone.",
				Choices = {
					"Confront the caregiver alone at the house; handle the rest of it alone.",
					"Listen, document what is reported, and contact adult-protection or emergency services based on the danger.",
					"Borrow money from the neighbor before it is taken; make no further changes.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "The neighbor now has an injury and says the caregiver will return soon.",
				Choices = {
					"Treat it as urgent, seek medical or emergency help, and avoid alerting the suspected abuser in a way that increases danger.",
					"Enter the home and remove the caregiver by force; wait for the other person to decide what happens next.",
					"Ask the neighbor to secretly confront the caregiver; handle every later response without asking anyone else for help.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-095",
		Title = "Controlled And Prevented From Leaving",
		Difficulty = 5,
		Skill = "Coercive-control safety planning",
		Feedback = "Coercive control limits choices deliberately. Personalized planning and safe communication are essential.",
		ContentFlag = "Relationship abuse; optional advanced module",
		Stages = {
			{
				Prompt = "My partner controls my money, transportation, and contacts. They say I am not allowed to leave the relationship.",
				Choices = {
					"Announce that you are leaving during the next argument; invite the group to judge them.",
					"Contact a domestic-violence advocate or trusted professional from a safe channel and develop a private safety plan.",
					"Transfer control of every account to the partner; wait to see if they stop.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "They have hidden my identification and monitor my devices.",
				Choices = {
					"Discuss safe document recovery and technology safety with an advocate; call emergency services if you are restrained or in immediate danger.",
					"Tell them where you plan to stay; wait for the other person to decide what happens next.",
					"Give up because leaving is impossible; wait for the problem to disappear without taking another step; keep the situation completely private.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-096",
		Title = "Gunshots From An Angry Neighbor",
		Difficulty = 5,
		Skill = "Shelter and emergency reporting",
		Feedback = "Gunfire creates unpredictable danger. Shelter, distance, and emergency response take priority.",
		Stages = {
			{
				Prompt = "My neighbor is yelling outside and firing a gun into the air.",
				Choices = {
					"Go outside and tell them to stop; continue without asking for help.",
					"Move away from windows, shelter in a safer location, and call emergency services.",
					"Record from the front porch; continue posting updates until public pressure changes the outcome.",
				},
				BestIndex = 2,
			},
			{
				Prompt = "A bullet breaks a nearby window.",
				Choices = {
					"Stay low and protected, move farther from the exposed area if safe, and update emergency services.",
					"Shout the neighbor's name; continue the confrontation until the other person gives in.",
					"Drive past the house to identify them; continue without asking for help.",
				},
				BestIndex = 1,
			},
		},
	},
	{
		Id = "CW-097",
		Title = "Customer Blocks The Exit",
		Difficulty = 5,
		Skill = "Workplace escape and alerting others",
		Feedback = "Blocking exits and threatening occupants changes a complaint into an emergency.",
		Stages = {
			{
				Prompt = "An enraged customer locks the front door and says nobody leaves until they receive a refund.",
				Choices = {
					"Quietly alert security or emergency services, move people away, and use another safe exit if available.",
					"Encourage everyone to rush the customer; continue posting updates until public pressure changes the outcome.",
					"Hand over all cash without following workplace safety procedures; wait for their next response.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "The customer begins threatening anyone who uses a phone.",
				Choices = {
					"Hold the phone up and challenge them; handle the rest of it alone.",
					"Avoid drawing attention, follow emergency instructions, and escape or secure in place when safely possible.",
					"Stand between the customer and the door; continue without asking for help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-098",
		Title = "Arson Threat",
		Difficulty = 5,
		Skill = "Responding to a credible fire threat",
		Feedback = "A specific threat plus visible preparation is an immediate emergency. Protect people, not property.",
		Stages = {
			{
				Prompt = "Someone who is furious with my family messages that they will set our house on fire tonight.",
				Choices = {
					"Preserve the threat, contact law enforcement and trusted adults, and follow safety guidance rather than confronting the sender.",
					"Ignore it because angry people exaggerate; wait for the problem to disappear without taking another step.",
					"Invite the person over to talk; wait for the other person to decide what happens next.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "A person carrying a fuel container is now walking toward the property.",
				Choices = {
					"Go outside and record them closely; continue posting updates until public pressure changes the outcome.",
					"Leave or shelter according to the safest available route, warn others, and call emergency services right away.",
					"Wait for visible flames before calling; keep the entire situation private unless it becomes worse.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-099",
		Title = "\"I Am Going To Hurt Someone Now\"",
		Difficulty = 5,
		Skill = "Urgent violence intervention",
		Feedback = "An immediate threat with a weapon, target, and location requires emergency intervention—not private mediation.",
		Stages = {
			{
				Prompt = "A friend calls me and says, 'I have a weapon, and I am going to hurt someone right now.'",
				Choices = {
					"Keep them talking calmly if safe while another person contacts emergency services, or contact emergency services yourself right away.",
					"Go meet them alone; handle every later response without asking anyone else for help; continue without outside support.",
					"Warn the intended person but tell nobody else; make no other attempt to resolve the issue afterward.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They give me the target's location and say they are almost there.",
				Choices = {
					"Drive there and block them yourself; wait for their next response.",
					"Give all specific information to emergency services and do not enter the danger area.",
					"Delete the call record; avoid discussing the situation with anyone who could help.",
				},
				BestIndex = 2,
			},
		},
	},
	{
		Id = "CW-100",
		Title = "Forced Entry By An Enraged Ex-Partner",
		Difficulty = 5,
		Skill = "Securing people during an immediate domestic threat",
		Feedback = "During forced entry, prioritize escape, concealment, and emergency instructions. Children should never be used to mediate violence.",
		ContentFlag = "Relationship violence; optional advanced module",
		Stages = {
			{
				Prompt = "My ex-partner is outside, breaking windows and demanding that I let them in. My children are inside with me.",
				Choices = {
					"Move everyone to the safest secure area available, call emergency services, and avoid confronting the person.",
					"Send a child outside to speak with them; continue without asking for help.",
					"Stand at the broken window and argue; handle the rest of it alone.",
				},
				BestIndex = 1,
			},
			{
				Prompt = "They enter through a broken window while emergency services are on the way.",
				Choices = {
					"Approach and try to physically remove them; handle every later response without asking anyone else for help.",
					"Escape through a safe route if possible; otherwise secure or hide, stay connected with emergency services, and follow instructions.",
					"Ask the children to distract them; wait for the other person to decide what happens next.",
				},
				BestIndex = 2,
			},
		},
	},
}

return ScenarioLibrary
