function unwrap(arr,index)
	index = index or 1
	if index > #arr then return nil end
	return arr[index],unwrap(arr,index+1)
end

function drawDiamond(mode,x,y,s)
	love.graphics.polygon(mode,x-s2,y, x,y-s, x+s2,y, x,y+s)
end

return {
	unwrap=unwrap,
	drawDiamond=drawDiamond
}