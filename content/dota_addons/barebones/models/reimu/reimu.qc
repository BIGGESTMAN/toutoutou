// Created by Crowbar 0.32.0.0

$ModelName "MMD Touhou\Reimu.mdl"

$Model "reimu" "reimu_reference.smd" {

	eyeball "eye_right" "ValveBiped.Bip01_Head1" -1.660000 -1.669998 66.659996 "eyeball_r" 1 4 "iris_unused" 1.5
	eyeball "eye_left" "ValveBiped.Bip01_Head1" 2.660000 -1.669998 66.659996 "eyeball_l" 1 -4 "iris_unused" 1.5

	flexfile "reimu.vta" 
	{
		defaultflex frame 0
		flex "suprised" frame 1
		flex "suprised3" frame 2
		flex "suprised2" frame 3
		flex "yacantbsrs" frame 4
		flex "cheerful" frame 5
		flex "alert" frame 6
		flex "calm" frame 7
		flex "angry" frame 8
		flex "sad" frame 9
		flex "yacantbsrs2" frame 10
		flex "yacantbsrs3" frame 11
		flex "cheerful2" frame 12
		flex "cheerful3" frame 13
		flex "pistonhondo" frame 14
		flex "pistonhondo2" frame 15
		flex "calm2" frame 16
		flex "calm3" frame 17
		flex "angry2" frame 18
		flex "angry3" frame 19
		flex "sad2" frame 20
		flex "sad3" frame 21
		flex "blink" frame 22
		flex "happy" frame 23
		flex "wink" frame 24
		flex "wink2" frame 25
		flex "meh" frame 26
		flex "close" frame 27
		flex "meh2" frame 28
		flex "meh3" frame 29
		flex "tightwink" frame 30
		flex "tightwink2" frame 31
		flex "a" frame 32
		flex "e" frame 33
		flex "u" frame 34
		flex "y" frame 35
		flex "o" frame 36
		flex "smile" frame 37
		flex "smirk" frame 38
		flex "smile2" frame 39
		flex "opensmile" frame 40
		flex "shock" frame 41
		flex "frown" frame 42
		flex "omega" frame 43
		flex "shout" frame 44
		flex "blush" frame 45
		flex "blush2" frame 46
		flex "cry" frame 47
		flex "cry2" frame 48
		flex "shadow" frame 49
	}

	flexcontroller blink range 0 1 blink
	flexcontroller suprised range 0 1 suprised
	flexcontroller happy range 0 1 happy
	flexcontroller wink range 0 1 wink
	flexcontroller wink2 range 0 1 wink2
	flexcontroller meh range 0 1 meh
	flexcontroller close range 0 1 close
	flexcontroller suprised2 range 0 1 suprised2
	flexcontroller suprised3 range 0 1 suprised3
	flexcontroller meh2 range 0 1 meh2
	flexcontroller meh3 range 0 1 meh3
	flexcontroller tightwink range 0 1 tightwink
	flexcontroller tightwink2 range 0 1 tightwink2
	flexcontroller a range 0 1 a
	flexcontroller e range 0 1 e
	flexcontroller u range 0 1 u
	flexcontroller y range 0 1 y
	flexcontroller o range 0 1 o
	flexcontroller smile range 0 1 smile
	flexcontroller smirk range 0 1 smirk
	flexcontroller smile2 range 0 1 smile2
	flexcontroller opensmile range 0 1 opensmile
	flexcontroller shock range 0 1 shock
	flexcontroller frown range 0 1 frown
	flexcontroller omega range 0 1 omega
	flexcontroller shout range 0 1 shout
	flexcontroller cry range 0 1 cry
	flexcontroller cry2 range 0 1 cry2
	flexcontroller blush range 0 1 blush
	flexcontroller blush2 range 0 1 blush2
	flexcontroller shadow range 0 1 shadow
	flexcontroller yacantbsrs range 0 1 yacantbsrs
	flexcontroller cheerful range 0 1 cheerful
	flexcontroller alert range 0 1 alert
	flexcontroller calm range 0 1 calm
	flexcontroller angry range 0 1 angry
	flexcontroller sad range 0 1 sad
	flexcontroller yacantbsrs2 range 0 1 yacantbsrs2
	flexcontroller yacantbsrs3 range 0 1 yacantbsrs3
	flexcontroller cheerful2 range 0 1 cheerful2
	flexcontroller cheerful3 range 0 1 cheerful3
	flexcontroller pistonhondo range 0 1 pistonhondo
	flexcontroller pistonhondo2 range 0 1 pistonhondo2
	flexcontroller calm2 range 0 1 calm2
	flexcontroller calm3 range 0 1 calm3
	flexcontroller angry2 range 0 1 angry2
	flexcontroller angry3 range 0 1 angry3
	flexcontroller sad2 range 0 1 sad2
	flexcontroller sad3 range 0 1 sad3
	flexcontroller null range 0 1 null
	flexcontroller eyes range -45 45 eyes_updown
	flexcontroller eyes range -45 45 eyes_rightleft

	localvar null
	%blink = blink
	%suprised = suprised
	%happy = happy
	%wink = wink
	%wink2 = wink2
	%meh = meh
	%close = close
	%suprised2 = suprised2
	%suprised3 = suprised3
	%meh2 = meh2
	%meh3 = meh3
	%tightwink = tightwink
	%tightwink2 = tightwink2
	%a = a
	%e = e
	%u = u
	%y = y
	%o = o
	%smile = smile
	%smirk = smirk
	%smile2 = smile2
	%opensmile = opensmile
	%shock = shock
	%frown = frown
	%omega = omega
	%shout = shout
	%cry = cry
	%cry2 = cry2
	%blush = blush
	%blush2 = blush2
	%shadow = shadow
	%yacantbsrs = yacantbsrs
	%cheerful = cheerful
	%alert = alert
	%calm = calm
	%angry = angry
	%sad = sad
	%yacantbsrs2 = yacantbsrs2
	%yacantbsrs3 = yacantbsrs3
	%cheerful2 = cheerful2
	%cheerful3 = cheerful3
	%pistonhondo = pistonhondo
	%pistonhondo2 = pistonhondo2
	%calm2 = calm2
	%calm3 = calm3
	%angry2 = angry2
	%angry3 = angry3
	%sad2 = sad2
	%sad3 = sad3
	%null = null
}


$SurfaceProp "flesh"

$Contents "solid"

$EyePosition 0 0 70

$MaxEyeDeflection 90

$CDMaterials "models\touhou\reimu\"

$Attachment "eyes" "ValveBiped.Bip01_Head1" 2.59 -2.42 0.03 rotate 0 -89.38 -90
$Attachment "righteye" "ValveBiped.Bip01_Head1" 2.59 -2.42 2.19 rotate 0 -89.38 -90
$Attachment "lefteye" "ValveBiped.Bip01_Head1" 2.59 -2.42 -2.13 rotate 0 -89.38 -90

$CBox 0 0 0 0 0 0

$BBox -14.775 -25.288 -2.198 11.235 26.22 77.691


$Sequence "ragdoll" {
	"reimu_anims\ragdoll.smd"
	activity "ACT_DIERAGDOLL" 1
	fadein 0.2
	fadeout 0.2
	fps 30
}
