-- ugh
addHook("HUD",function(v)
	v.dointerp = function(tag)
		if v.interpolate == nil then return end
		v.interpolate(tag)
	end
	v.dolatch = function(tag)
		if v.interpLatch == nil then return end
		v.interpLatch(tag)
	end
end,"game")