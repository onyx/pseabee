$script:roles = @{}

function role($name, $servers, $username, $password) {
    $script:roles[$name] = @{ servers = $servers; username = $username; password = $password }
}

function run([array]$roles, [array]$argumentList, [scriptblock]$definition) {
    foreach ($role in UniqueServers($roles)) {
        $credential = New-object -typename System.Management.Automation.PSCredential($role.username, (ConvertTo-SecureString $role.password -AsPlainText –Force))
        Invoke-Command -ComputerName $role.server -Credential $credential $definition -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck) -ArgumentList $argumentList
    }
}

function put(
    [string]$source = $(throws "A source directory to copy from is required"), 
    [string]$destination = $(throws "A destination directory to copy to is required"),
    $roles){
    
    foreach ($role in UniqueServers($roles)) {
        Exec-Safe {net use "/User:$($role.username)" "\\$($role.server)" "$($role.password)"}
	if (!(Test-Path "\\$($role.server)\$destination")) {
		mkdir "\\$($role.server)\$destination"
	}
        Copy-Item "$source" -Destination "\\$($role.server)\$destination" -Recurse -Force
    }
}

function Exec-Safe([ScriptBlock]$command) {
	#This will resolve ANY variable occurences in the script block, which could look weird
	$commandString = $ExecutionContext.InvokeCommand.ExpandString($command)

    $output = @(&$command)
    $ret = $LastExitCode
    $output | foreach { Write-Debug $_ }
    if ($ret -ne 0) {
		$output | foreach { Write-Host -f 'red' $_ }
		throw ("$commandString exited with $ret")
	}
}

function UniqueServers($roles) {
    $servers = @()
    foreach($roleName in $roles) {
        $role = $script:roles[$roleName]
        foreach ($server in $role.servers) {
            #see this comma here, this is how you make a list of lists *FACEPALM*
            $servers += ,@($server,$role.username,$role.password)
        }
    }

    $serversToReturn = @()
    $servers | select -uniq | % { $serversToReturn += @{server=$_[0]; username = $_[1]; password = $_[2] } }
    return $serversToReturn
}

Export-ModuleMember role, run, put
