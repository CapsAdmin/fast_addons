OldCleanUpMap = OldCleanUpMap or game.CleanUpMap

function game.CleanUpMap(...)
	hook.Call("PreGameCleanUpMap")
	OldCleanUpMap(...)
	hook.Call("PostGameCleanUpMap")
end