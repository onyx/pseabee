# usage: Invoke-psake -buildFile ./example.ps1 -taskList local, deploy

Import-Module pseabee

task local {
    $username = "DOMAIN\someuser"
    $password = "secret"

    Write-Host "running local"
    
    role appServer localhost, localhost $username $password
    role webServer localhost $username $password 
}

task deploy {
    run -roles appServer, webServer {
        Set-Location "C:\a\" 
        Get-ChildItem
        
        Set-Location "C:\b\" 
        Get-ChildItem
    }
    
    put -roles appServer, webServer "c:\a\*" "c$\b\"
}