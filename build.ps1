function BuildVariants {
  param (
    $ldflags,
    $compileflags,
    $prefix,
    $suffix,
    $arch,
    $os,
    $path
  )

  foreach ($currentarch in $arch) {
    foreach ($currentos in $os) {
      $env:GOARCH = $currentarch
      $env:GOOS = $currentos
      
      # More sensible naming for x64
      $namearch = $currentarch
      if ($namearch -eq "amd64") {
        $namearch = "x64"
      }

      & $BUILDER build -ldflags "$ldflags" -o binaries/$prefix-$currentos-$namearch-$VERSION$suffix -trimpath  @compileflags $path
      if (Get-Command "cyclonedx-gomod" -ErrorAction SilentlyContinue)
      {
        cyclonedx-gomod app -json -licenses -output binaries/$prefix-$currentos-$namearch-$VERSION$suffix.bom.json -main $path .
      }
    }
  }
}

Set-Location $PSScriptRoot

$COMMIT = git rev-parse --short HEAD
$VERSION = git describe --tags --exclude latest --exclude devbuild
$DIRTYFILES = git status --porcelain
$BUILDER = "go"

if ("$DIRTYFILES" -ne "") {
  $VERSION = "$VERSION-local-changes"
}

$LDFLAGS = "-X github.com/lkarlslund/adalanche/modules/version.Commit=$COMMIT -X github.com/lkarlslund/adalanche/modules/version.Version=$VERSION"

# Release
BuildVariants -ldflags "$LDFLAGS -s" -compileflags @("-tags", "32bit,collector") -prefix adalanche-collector -path ./adalanche -arch @("386") -os @("windows") -suffix ".exe"
BuildVariants -ldflags "$LDFLAGS -s" -compileflags @("-tags", "collector") -prefix adalanche-collector -path ./adalanche -arch @("amd64") -os @("windows") -suffix ".exe"
BuildVariants -ldflags "$LDFLAGS -s" -prefix adalanche -path ./adalanche -arch @("amd64", "arm64") -os @("windows") -suffix ".exe"
BuildVariants -ldflags "$LDFLAGS -s" -prefix adalanche -path ./adalanche -arch @("amd64", "arm64") -os @("darwin", "freebsd", "openbsd", "linux")
