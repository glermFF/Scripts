#### --- Apresentar conexões e portas ativas (local e remotas) --- ####

param(
    [ValidateSet(
        'Listen','Established','Closed','SynSent','SynReceived',
        'FinWait1','FinWait2','CloseWait','Closing','LastAck',
        'TimeWait','DeleteTcb'
    )]
    [string]$State = 'Listen',
    [string[]]$ComputerName
)

Write-Host "Checking $State TCP connections on $env:COMPUTERNAME..." -ForegroundColor Cyan

#### --- Conexões TCP do host local --- ####

$processLookup = Get-Process | Group-Object Id -AsHashTable -AsString

$localResults =
    Get-NetTCPConnection -State $State |
    ForEach-Object {
        $procID = $_.OwningProcess
        $proc   = $processLookup[[string]$procID]

        [pscustomobject]@{
            ComputerName  = $env:COMPUTERNAME
            LocalAddress  = $_.LocalAddress
            LocalPort     = $_.LocalPort
            RemoteAddress = $_.RemoteAddress
            RemotePort    = $_.RemotePort
            State         = $_.State
            ProcessId     = $procID
            ProcessName   = $proc.ProcessName
        }
    }

$localResults | Sort-Object LocalPort, ProcessName | Format-Table -AutoSize

#### --- Conexões TCP em outros hosts (PowerShell Remoting) --- ####

if ($ComputerName) {
    Write-Host "`n>> Connections in: $($ComputerName -join ', ')" -ForegroundColor Yellow
    Write-Host "(Its necessary to enable PS Remoting in hosts)" -ForegroundColor DarkYellow

    $remoteResults = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        param($State)

        $procLookup = Get-Process | Group-Object Id -AsHashTable -AsString

        Get-NetTCPConnection -State $State | ForEach-Object {
            $p = $procLookup[[string]$_.OwningProcess]

            [pscustomobject]@{
                ComputerName  = $env:COMPUTERNAME
                LocalAddress  = $_.LocalAddress
                LocalPort     = $_.LocalPort
                RemoteAddress = $_.RemoteAddress
                RemotePort    = $_.RemotePort
                State         = $_.State
                ProcessId     = $_.OwningProcess
                ProcessName   = $p.ProcessName
            }
        }
    } -ArgumentList $State -ErrorAction SilentlyContinue

    if ($remoteResults) {
        Write-Host "`n>> Results(local + remote)" -ForegroundColor Cyan
        $all = $localResults + $remoteResults
        $all | Sort-Object ComputerName, LocalPort, ProcessName | Format-Table -AutoSize
    }
    else {
        Write-Host "No remote information obtained (hosts inaccessible or remoting disabled)." -ForegroundColor Red
    }
}