function Get-Versions {
    param(
        [Parameter(ValueFromPipeline)]
        [string]$service, 
        [string]$env = 'dev') 

    Process {
        Write-Host "Polling versions for $service in $env";
        if ($env -eq 'live') {
            $port = ':8080'
        }
        else {
            $port = ''
        }
        $servers = Invoke-RestMethod -Method Get -Uri "http://platal.service.owf-$($env)$($port)/api/consul/health/$service"
        Write-Host "Found $($servers.Count) servers"
        $servers.Port | ForEach-Object { 
            $url = "http://$service.service.owf-$($env):$_"
            $status = Invoke-RestMethod -Method Get -Uri "$url/v1/status"
            Write-Host "Server at $url returned version $($status.version)"
        } 
    }
}