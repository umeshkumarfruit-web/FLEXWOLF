param(
    [ValidateSet("all", "debug-apk", "profile-apk", "release-apk", "appbundle")]
    [string]$Target = "all",
    [string]$EnvFile = ".env",
    [switch]$SkipChecks,
    [switch]$SplitPerAbi = $true
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$versionLine = Select-String -Path "pubspec.yaml" -Pattern "^version:\s+(.+)$" | Select-Object -First 1
if (-not $versionLine) {
    throw "pubspec.yaml does not contain a version field."
}

$version = $versionLine.Matches[0].Groups[1].Value.Trim()
$parts = $version.Split("+")
$buildName = $parts[0]
$buildNumber = if ($parts.Length -gt 1) { $parts[1] } else { "1" }

$dartDefineKeys = @(
    "API_BASE_URL",
    "SHOPIFY_STORE_DOMAIN",
    "SHOPIFY_STOREFRONT_PUBLIC_TOKEN",
    "SHOPIFY_API_KEY",
    "SHOPIFY_CUSTOMER_ACCOUNT_CLIENT_ID",
    "SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI",
    "SHOPIFY_CUSTOMER_ACCOUNT_ACCESS_TOKEN",
    "SHOPIFY_CUSTOMER_ACCOUNT_TOKEN_EXPIRES_AT",
    "FIREBASE_PROJECT_ID",
    "LOOX_PUBLIC_STORE_ID",
    "ENABLE_SHOPIFY_CUSTOMER_SYNC",
    "DEEP_LINK_SCHEME",
    "DEEP_LINK_HOST",
    "APP_VERSION",
    "BUILD_NUMBER",
    "RELEASE_NOTES"
)

function Read-EnvFile {
    param([string]$Path)

    $values = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $values
    }

    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
            continue
        }

        $separator = $trimmed.IndexOf("=")
        if ($separator -le 0) {
            continue
        }

        $key = $trimmed.Substring(0, $separator).Trim()
        $value = $trimmed.Substring($separator + 1).Trim()
        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'"))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $values[$key] = $value
    }

    return $values
}

$envValues = Read-EnvFile -Path $EnvFile
$customerRedirectUri = [Environment]::GetEnvironmentVariable("SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI")
if ([string]::IsNullOrWhiteSpace($customerRedirectUri) -and $envValues.ContainsKey("SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI")) {
    $customerRedirectUri = $envValues["SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI"]
}
if (-not [string]::IsNullOrWhiteSpace($customerRedirectUri)) {
    $parsedRedirectUri = [Uri]$customerRedirectUri
    $env:FLEXWOLF_SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_SCHEME = $parsedRedirectUri.Scheme
    $env:FLEXWOLF_SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_HOST = $parsedRedirectUri.Host
    $env:FLEXWOLF_SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_PATH = if ([string]::IsNullOrWhiteSpace($parsedRedirectUri.AbsolutePath)) { "/" } else { $parsedRedirectUri.AbsolutePath }
}
$dartDefines = @()
foreach ($key in $dartDefineKeys) {
    $value = [Environment]::GetEnvironmentVariable($key)
    if ([string]::IsNullOrWhiteSpace($value) -and $envValues.ContainsKey($key)) {
        $value = $envValues[$key]
    }
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $dartDefines += "--dart-define=$key=$value"
    }
}

if (-not $SkipChecks) {
    flutter analyze
    flutter test
}

if ($Target -eq "all" -or $Target -eq "debug-apk") {
    flutter build apk --debug --build-name $buildName --build-number $buildNumber @dartDefines
}

if ($Target -eq "profile-apk") {
    flutter build apk --profile --build-name $buildName --build-number $buildNumber @dartDefines
    if ($LASTEXITCODE -ne 0) { throw 'Profile APK build failed.' }
}

if ($Target -eq "all" -or $Target -eq "release-apk") {
    if ($SplitPerAbi) {
        flutter build apk --release --split-per-abi --build-name $buildName --build-number $buildNumber @dartDefines
    } else {
        flutter build apk --release --build-name $buildName --build-number $buildNumber @dartDefines
    }
    if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed.' }
    if ($SplitPerAbi) {
        $releaseApks = @(Get-ChildItem -Path 'build/app/outputs/flutter-apk' -Filter 'app-*-release.apk')
        if ($releaseApks.Count -eq 0) { throw 'No ABI-specific release APKs were produced.' }
        foreach ($apk in $releaseApks) {
            if ($apk.Length -gt 35MB) {
                throw "$($apk.Name) is larger than the 35 MB APK limit."
            }
        }
    }
}

if ($Target -eq "all" -or $Target -eq "appbundle") {
    flutter build appbundle --release --build-name $buildName --build-number $buildNumber @dartDefines
}
