local ServerStorage = game:GetService('ServerStorage')
print('no libs for a while')

for _, test in ServerStorage.tests:GetDescendants() do
	task.spawn(require, test)
end
