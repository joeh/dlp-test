
param(
    [Parameter(Mandatory)]
    [ValidateRange(1, 100000)]
    [int]$SizeMB,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [string[]]$Files = @()
)

Add-Type -AssemblyName System.IO.Compression

$targetBytes = [long]$SizeMB * 1MB
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)

$directory = Split-Path $OutputPath -Parent
New-Item -ItemType Directory -Path $directory -Force | Out-Null

$resolvedFiles = foreach ($file in $Files) {
    $item = Get-Item -LiteralPath $file -ErrorAction Stop
    if ($item.PSIsContainer) {
        throw "Directories are not supported: $file"
    }
    $item
}

$archive = $null
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

try {
    $archive = [System.IO.Compression.ZipFile]::Open(
        $OutputPath,
        [System.IO.Compression.ZipArchiveMode]::Create
    )

    # Add user-supplied files first
    foreach ($file in $resolvedFiles) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $file.FullName,
            $file.Name,
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }

    # Estimate remaining space based on archive size so far
    $archive.Dispose()
    $archive = $null

    $currentSize = (Get-Item -LiteralPath $OutputPath).Length
    $remaining = [Math]::Max(0L, $targetBytes - $currentSize)

    # Append random data as a ZIP entry
    $archive = [System.IO.Compression.ZipFile]::Open(
        $OutputPath,
        [System.IO.Compression.ZipArchiveMode]::Update
    )

    if ($remaining -gt 0) {
        $entry = $archive.CreateEntry(
            "padding.bin",
            [System.IO.Compression.CompressionLevel]::NoCompression
        )

        $stream = $entry.Open()
        try {
            $buffer = New-Object byte[] (1MB)

            while ($remaining -gt 0) {
                $count = [int][Math]::Min($buffer.Length, $remaining)
                $rng.GetBytes($buffer)
                $stream.Write($buffer, 0, $count)
                $remaining -= $count
            }
        }
        finally {
            $stream.Dispose()
        }
    }
}
finally {
    if ($null -ne $archive) {
        $archive.Dispose()
    }
    $rng.Dispose()
}

$result = Get-Item -LiteralPath $OutputPath

Write-Host "Created: $($result.FullName)"
Write-Host ("Size: {0:N2} MiB" -f ($result.Length / 1MB))
