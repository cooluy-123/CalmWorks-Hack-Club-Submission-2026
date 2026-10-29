script.Parent.HealthChanged:Connect(function()
	script.Parent.Parent.CowMesh.BLOOD:Play()
	script.Parent.Parent.CowMesh.BloodParticle.Enabled= true
	wait(0.2)
	script.Parent.Parent.CowMesh.BloodParticle.Enabled= false
end)
