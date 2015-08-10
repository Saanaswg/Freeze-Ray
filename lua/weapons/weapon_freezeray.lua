-- my first swep pls dont judge :^)

SWEP.Author = "Saana"
SWEP.Instructions = "Shoot to freeze players"

SWEP.ViewModel = "models/weapons/v_smg_tmp.mdl"
SWEP.WorldModel	= "models/weapons/w_smg_tmp.mdl"
SWEP.ViewModelFlip = true
SWEP.AnimPrefix	= "python"

SWEP.UseHands = true
SWEP.AdminOnly = true
SWEP.Spawnable = true

 SWEP.PrintName = "Freeze Ray"			
 SWEP.Slot = 2
 SWEP.SlotPos = 50
 SWEP.DrawAmmo = true
 SWEP.DrawCrosshair	= true
 
util.PrecacheModel("models/weapons/v_smg_tmp.mdl")
util.PrecacheModel("models/weapons/w_smg_tmp.mdl")
util.PrecacheSound(Sound("ambient/levels/citadel/portal_beam_shoot5.wav"))
util.PrecacheSound(Sound("Airboat.FireGunRevDown"))
util.PrecacheSound(Sound("physics/glass/glass_impact_bullet4.wav"))
util.PrecacheSound(Sound("physics/glass/glass_pottery_break4.wav"))

local firesound, firesound2	= Sound("ambient/levels/citadel/portal_beam_shoot5.wav"), Sound("Airboat.FireGunRevDown")

SWEP.Primary = {
	ClipSize = 8,
	DefaultClip = 8,
	Automatic = false,
	Ammo = "GaussEnergy"
}

SWEP.Secondary = {
	ClipSize = -1,
	DefaultClip = -1,
	Automatic = false,
	Ammo = "none"
}

function SWEP:Initialize()
	self:SetHoldType("pistol")
end

-- To balance things, ive made it so the ammo slowly refills
if SERVER then
	local refill = CurTime()
	function SWEP:Think()
		if refill > CurTime() then return end 
		refill = CurTime() + 2
		
		if self:Clip1() >= 8 then self:SetClip1(8) return end 
		
		self:SetClip1(self:Clip1() + 1)
	end
end

-- You can only fire the gun once every 1.5 seconds providing the gun has enough charge
local retry = CurTime()
function SWEP:PrimaryAttack()
	if retry > CurTime() then return end 
	retry = CurTime() + 1.5
	
	if self:Clip1() < 4 then return end
	self:SetClip1(self:Clip1() - 4)
	
	local trace = self.Owner:GetEyeTrace()
		
	-- Sounds/Effects
	self.Weapon:EmitSound(firesound)
	self.Weapon:EmitSound(firesound2)
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:ShootEffects(trace)	
	
	if not trace.Hit then return end
	
	-- When the gun hits a player
	if SERVER then  
		local players = ents.FindInSphere(trace.HitPos + Vector(0, 0, 24), 56)
		
		for i=1, #players do
			if IsValid(players[i]) and players[i]:IsPlayer() then
				local ply = players[i]
				
				ply:Freeze(true)
				ply:EmitSound("physics/glass/glass_impact_bullet4.wav")
				
				-- Spawning a cute ice thing around the player
				local ice = ents.Create("prop_dynamic")
				ply.__swgice = ice
				timer.Simple(0.2, function() 
					ice:SetModel("models/props_wasteland/rockcliff01f.mdl")
					ice:SetModelScale(0.6)
					ice:SetPos(ply:GetPos() + Vector(0, 0, 48))
					ice:SetParent(ply)
					ice:SetRenderMode(RENDERMODE_TRANSALPHA)
					ice:SetAngles(Angle(0, math.random(1, 360), 0))
					ice:SetColor(Color(150, 255, 255, 150))
				end)
				
				-- The target is unfrozen after 5 seconds
				timer.Simple(5, function() if IsValid(ice) then ice:Remove() end ply.__swgice = nil end)
				timer.Create("__swgfreeze" .. ply:SteamID(), 5, 1, function()
					ply:Freeze(false)
					ply:EmitSound("physics/glass/glass_pottery_break4.wav")	
				end)
			end
		end
	end
end

-- Nobody should ever pick this weapon up after death
function SWEP:OnDrop()
	self:Remove()
end

-- Pretty much just ripped the toolgun effect because its what i wanted :^)
function SWEP:ShootEffects(trace)
	local effectdata = EffectData()
	effectdata:SetOrigin(trace.HitPos)
	effectdata:SetStart(self.Owner:GetShootPos())
	effectdata:SetAttachment(1)
	effectdata:SetEntity(self.Weapon)
	util.Effect("ToolTracer", effectdata)
end

-- Didnt wanna add a secondary fire :^)
function SWEP:SecondaryAttack() end

-- If the player dies it removes the unfreeze timer so it doesnt play the sound and unfreeze them after theyve already respawned
hook.Add("PlayerDeath", "__swgfreeze", function(ply)
	if not timer.Exists("__swgfreeze" .. ply:SteamID()) then return end
	
	if ply.__swgice and IsValid(ply.__swgice) then
		ply.__swgice:Remove()
		ply.__swgice = nil
	end
	
	ply:Freeze(false)
	timer.Remove("__swgfreeze" .. ply:SteamID())
end)