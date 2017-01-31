game.OldCleanUpMap = game.OldCleanUpMap or game.CleanUpMap

function game.CleanUpMap(...)
	hook.Call("PreGameCleanUpMap")
	game.OldCleanUpMap(...)
	hook.Call("PostGameCleanUpMap")
end