$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$generator = Join-Path $repoRoot 'Scripts/generate-device-catalog.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("h2phone-device-catalog-" + [guid]::NewGuid())
$fixturePath = Join-Path $tempRoot 'appledb.json'
$osFixturePath = Join-Path $tempRoot 'appledb-ios.json'
$outputPath = Join-Path $tempRoot 'DeviceCatalog.json'

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    @'
[
  {"name":"iPad Pro","type":"iPad","identifier":["iPad8,1"],"board":["J317AP"],"model":["A1980"],"released":"2018-11-07"},
  {"name":"iPhone 7 (GSM)","type":"iPhone","identifier":["iPhone9,3"],"board":["D101AP"],"model":["A1778"],"released":["2016-09-16","2017-03-24"]},
  {"name":"iPhone 7 (CDMA)","type":"iPhone","identifier":["iPhone9,1"],"board":["D10AP"],"model":["A1660","A1779"],"released":"2016-09-16"},
  {"name":"Broken phone","type":"iPhone","identifier":[],"board":[],"model":[]}
]
'@ | Set-Content -LiteralPath $fixturePath -Encoding utf8
    @'
[
  {"version":"15.8","build":"19H370","deviceMap":["iPhone9,1","iPhone9,3"],"beta":false,"rc":false},
  {"version":"15.8","build":"19H370","deviceMap":["iPhone9,1"],"beta":false,"rc":false},
  {"version":"16.0","build":"20A362","deviceMap":["iPhone9,3"],"beta":false,"rc":false},
  {"version":"16.1 beta","build":"20B5045d","deviceMap":["iPhone9,1"],"beta":true,"rc":false}
]
'@ | Set-Content -LiteralPath $osFixturePath -Encoding utf8

    & $generator -SourcePath $fixturePath -OSSourcePath $osFixturePath -OutputPath $outputPath
    if (-not (Test-Path -LiteralPath $outputPath)) { throw 'Generator did not create the catalog.' }

    $rawCatalog = Get-Content -Raw -LiteralPath $outputPath
    if ($rawCatalog.Contains("`r")) { throw 'Catalog output must use deterministic LF line endings.' }
    $catalog = $rawCatalog | ConvertFrom-Json
    if ($catalog.schemaVersion -ne 1) { throw 'Catalog schema version must be 1.' }
    if ($catalog.source -ne 'https://github.com/littlebyteorg/appledb') { throw 'Catalog must identify AppleDB as its source.' }
    if ($catalog.devices.Count -ne 2) { throw 'Catalog must contain only valid iPhone records.' }
    if ($catalog.devices[0].identifier -ne 'iPhone9,1' -or $catalog.devices[1].identifier -ne 'iPhone9,3') {
        throw 'Catalog must be sorted by numeric iPhone identifier.'
    }
    if ($catalog.devices[0].name -ne 'iPhone 7' -or $catalog.devices[1].name -ne 'iPhone 7') {
        throw 'Catalog must normalize AppleDB radio-variant suffixes.'
    }
    if ($catalog.devices[0].boards[0] -ne 'D10AP' -or $catalog.devices[0].models.Count -ne 2) {
        throw 'Catalog must preserve board and model identifiers.'
    }
    if ($catalog.devices[1].released -ne '2016-09-16') {
        throw 'Catalog must keep the earliest release date.'
    }
    if ($catalog.devices[0].firmwares.Count -ne 1 -or
        $catalog.devices[0].firmwares[0].version -ne '15.8' -or
        $catalog.devices[0].firmwares[0].build -ne '19H370' -or
        $catalog.devices[0].firmwares[0].darwin -ne '21.6.0') {
        throw 'Catalog must attach deduplicated stable firmware tuples to each compatible ProductType.'
    }
    if ($catalog.devices[1].firmwares.Count -ne 2 -or $catalog.devices[1].firmwares[1].version -ne '16.0') {
        throw 'Firmware compatibility must be filtered independently for each ProductType and sorted by version.'
    }

    Write-Output 'Device catalog tests passed: 11 assertions.'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
