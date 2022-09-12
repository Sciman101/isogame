function unwrap(arr,index)
	index = index or 1
	if index > #arr then return nil end
	return arr[index],unwrap(arr,index+1)
end

return {
	unwrap=unwrap
}