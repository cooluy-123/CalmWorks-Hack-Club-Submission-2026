while true do wait(math.random(6,10))
	local RandomSoundsC= math.random(1,3)
	if RandomSoundsC== 1 then
		script.Parent.Cow1:Play()
	end
	if RandomSoundsC== 2 then
		script.Parent.Cow2:Play()
	end
	if RandomSoundsC== 3 then
		script.Parent.Cow3:Play()
	end
end
