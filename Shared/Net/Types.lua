--- ### Types
export type NetData = {
	namespace: string,
	RemoteEvent: {[string]: string} | nil,
	RemoteFunction: {[string]: string} | nil,
}

export type NetInstance = {
	RemoteEvent: {[string]: RemoteEvent},
	RemoteFunction: {[string]: RemoteFunction},
}

return {}