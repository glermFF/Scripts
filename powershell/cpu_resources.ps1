#### --- Monitor de processos com maior uso de CPU --- ####

param(
    [int]$Top = 10,                         # Quantos processos mostrar por amostra
    [int]$Samples = 4,                      # Quantas vezes coletar (amostras)
    [int]$IntervalSeconds = 2,              # Intervalo entre amostras
    [double]$CpuSecondsMin = 0,             # Limite mínimo de CPU (em segundos)
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$ProcessNameLike,               # Filtro por nome (pattern, ex: "chrome")
    [switch]$IncludeIdleSystem,             # Incluir Idle/System
    [string]$ExportCsv,                     # Caminho para exportar CSV (opcional)
    [switch]$Quiet                          # Não mostrar na tela, só exportar
)

Write-Host "Checking CPU usage on $ComputerName..." -ForegroundColor Cyan

# Armazena resultados para exportação (se solicitado)
$allSamples = @()

for ($i = 1; $i -le $Samples; $i++) {

    $now = Get-Date

    try {
        $processes = Get-Process -ComputerName $ComputerName -ErrorAction Stop
    }
    catch {
        Write-Warning "Falha ao obter processos de ${ComputerName}: $_"
        break
    }

    # Aplica todos os filtros de nome em um único lugar
    $processes = $processes | Where-Object {
        ($IncludeIdleSystem -or ($_.Name -notin 'Idle', 'System')) -and
        (-not $ProcessNameLike -or $_.Name -like "*$ProcessNameLike*")
    }

    $topProcs = $processes |
        Where-Object { $_.CPU -ge $CpuSecondsMin } |
        Sort-Object CPU -Descending |
        Select-Object -First $Top `
            @{ Name = 'Time'; Expression = { $now } },
            Name, Id,
            @{ Name = 'CPU_s'; Expression = { [math]::Round($_.CPU, 1) } },
            @{ Name = 'CPU_%Avg'; Expression = {
                if ($_.StartTime) {
                    $uptime = ($now - $_.StartTime).TotalSeconds
                    if ($uptime -gt 0) {
                        [math]::Round( ($_.CPU / $uptime / $env:NUMBER_OF_PROCESSORS) * 100, 1 )
                    } else { 0 }
                } else { $null }
            } },
            @{ Name = 'RAM_MB'; Expression = { [math]::Round($_.WorkingSet / 1MB, 1) } },
            Handles

    if (-not $Quiet) {
        Write-Host "---- Sample $i of $Samples at $now ----" -ForegroundColor Yellow
        $topProcs | Format-Table -AutoSize
        Write-Host
    }

    if ($ExportCsv) {
        $allSamples += $topProcs
    }

    if ($i -lt $Samples) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

if ($ExportCsv -and $allSamples.Count -gt 0) {
    $allSamples | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
    if (-not $Quiet) {
        Write-Host "Resultados exportados para $ExportCsv" -ForegroundColor Green
    }
}