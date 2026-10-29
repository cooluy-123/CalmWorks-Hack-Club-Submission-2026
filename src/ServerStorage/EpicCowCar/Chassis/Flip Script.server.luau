local function flipCar(otherPart)
	local humanoid = otherPart.parent:FindFirstChildWhichIsA("Humanoid")
	if humanoid then
		print("Flip")
		script.Parent.BodyGyroFlip.MaxTorque = Vector3.new(400000, 0, 400000)
	end
	wait(2)
	script.Parent.BodyGyroFlip.MaxTorque = Vector3.new(0, 0, 0)
	wait(3)
end

script.Parent.Touched:Connect(flipCar)