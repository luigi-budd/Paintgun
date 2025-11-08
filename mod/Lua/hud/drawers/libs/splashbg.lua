local HUD = Paint.HUD

HUD.drawSplashBG = function(v, x,y, sx,sy, w,h, flags,cmap,light)
	local patch = v.cachePatch(light and "PT_LOW_BGL" or "PT_LOW_BG")
	local maxw = patch.width*FU
	local maxh = patch.height*FU
	
	sx = $ % maxw
	sy = $ % maxh
	
	local workx = 0
	local w_sx = sx
	while (workx < (w + maxw - sx))
		local worky = 0
		local w_sy = sy
		while (worky < h+maxh - sy)
			v.drawCropped(x + workx, y + worky, FU,FU, patch, flags,cmap,
				max(w_sx, 0), max(w_sy, 0), max(min(w, w - workx), 0), max(min(h, h - worky), 0)
			)
			worky = $ + (maxh - w_sy)
			w_sy = 0
		end
		
		workx = $ + (maxw - w_sx)
		w_sx = 0
	end
end