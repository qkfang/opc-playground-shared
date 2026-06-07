using 'main.bicep'

param baseName = 'plgd'
param projectName = 'playground'
param location = 'australiaeast'
param principals = [
	{
		id: '4b74544b-02c6-4e4f-b936-732c9c3fff65'
		principalType: 'User'
	}
]

