$packageName = 'PDFXchangeEditor' 
$installerType = 'MSI'
$url = 'http://www.tracker-software.com/downloads/PDFXVE3.x86.msi'
$url64 = 'http://www.tracker-software.com/downloads/PDFXVE3.x64.msi'
$silentArgs = '/quiet'
$validExitCodes = @(0)

Install-ChocolateyPackage "$packageName" "$installerType" "$silentArgs" "$url" "$url64"  -validExitCodes $validExitCodes
