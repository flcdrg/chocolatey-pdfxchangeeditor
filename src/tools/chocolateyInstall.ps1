$ErrorActionPreference = 'Stop'; # stop on all errors
$packageName = 'PDFXchangeEditor' 
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url        = 'http://34e34375d0b7c22eafcf-c0a4be9b34fe09958cbea1670de70e9b.r87.cf1.rackcdn.com/EditorV6.x86.msi' # download url
$url64      = 'http://34e34375d0b7c22eafcf-c0a4be9b34fe09958cbea1670de70e9b.r87.cf1.rackcdn.com/EditorV6.x64.msi'

$packageArgs = @{
  packageName   = $packageName
  unzipLocation = $toolsDir
  fileType      = 'MSI'
  url           = $url
  url64bit      = $url64
  silentArgs = '/quiet /norestart'
  validExitCodes= @(0, 3010, 1641)

  # optional, highly recommended
  softwareName  = 'PDF-XChange Editor' #part or all of the Display Name as you see it in Programs and Features. It should be enough to be unique
  checksum      = '056BB302045AA236BCBC1662FEEC1896'
  checksumType  = 'md5' #default is md5, can also be sha1
  checksum64    = '27C198C23F46B70D24ED76D41AD91B1D'
  checksumType64= 'md5' #default is checksumType
}

Install-ChocolateyPackage @packageArgs
