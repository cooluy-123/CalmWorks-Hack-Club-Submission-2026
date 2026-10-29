while true do wait(0.1)
	if script.Parent.Health<= 0 then
		
		script.Parent.Parent.CowMesh.Cow2.Volume= 5
		wait(0.1)
		script.Parent.Parent.CowMesh.Cow2:Play()
		wait(2)
		script.Parent.Parent:Destroy()
	end
end
