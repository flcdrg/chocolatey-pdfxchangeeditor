function Parse-ReleaseNotes($html)
{
    $ul = $html.getElementById("bh-history");

    # summary
    $ul.children[0].children[0].innerText;
    ""

    # version from <a class="active" name="6.0.317.1" href="PDFXE_history.html#6.0.317.1">
    $version = $ul.children[0].children[0].name

    # 
    $subUl = $html.getElementById("changes-$version").children[0]

    $newlyAdded = New-Object System.Collections.ArrayList
    $bugFixed = New-Object System.Collections.ArrayList
    $changed = New-Object System.Collections.ArrayList

    $allowedTags = @('#text', 'a')

    foreach ($child in $subUl.children)
    {
        
        $type = $child.children[0].title

        # remove unwanted tags
        [void] ($child.childNodes | Where-Object { $allowedTags -notcontains $_.nodeName } | % { $child.removeChild($_) } )

        # convert links

        [void] ($child.childNodes | Where-Object { $_.nodeName -eq 'A' } | % { 
                $textNode = $ie.Document.createTextNode("[$($_.innerText)]($($_.href))")
                $child.replaceChild($textNode, $_)
            } 
            
        )

        $value = ($child.innerHTML.Trim().Replace("&lt;", "<").Replace("&gt;", ">").Replace("&amp;", "&") )

        switch ($type) 
        {
            "Newly added feature" 
            {
                [void] $newlyAdded.Add($value)
            }
            "A reported error or bug was fixed" 
            {
                [void] $bugFixed.Add($value)
            }
            "Changed, reviewed, modified feature" 
            {
                [void] $changed.Add($value)
            }
        }
    }

    if ($newlyAdded)
    {
        "#### Newly added feature"
        ""
        $newlyAdded | % { "* " + $_ }
        ""
    }

    if ($bugFixed)
    {
        "#### A reported error or bug was fixed"
        ""
        $bugFixed | % { "* " + $_ }
        ""
    }

    if ($changed) 
    {
        "#### Changed, reviewed, modified feature"
        ""

        $changed | % { "* " + $_ }
    }

}

function Calculate-Hash($url)
{
    $tempFile = New-TemporaryFile

    Invoke-WebRequest -Uri $url -OutFile $tempFile

    $hash = Get-FileHash $tempFile -Algorithm SHA256

    Remove-Item $tempFile

    $hash
}

function Update-InstallScript()
{
    # Get latest available version
    $response = Invoke-WebRequest -Uri https://www.tracker-software.com/product/pdf-xchange-editor/history
    $content = $response.Content

    # <b>Version 6.0.318.1</b>
    $isMatch = $content -match "Version (?<release>\d{1,}\.\d{1,}\.\d{1,}(.\d{1,})?)"

    if ($isMatch) {

        $version = $Matches.release

        if ($version.Split(".").Length -eq 3) {
            $paddedVersion = $version + ".0"
        } else {
            $paddedVersion = $version
        }

        $installScript = Join-Path $PSScriptRoot "src/tools/chocolateyInstall.ps1"
        $contents = Get-Content $installScript -Encoding Utf8
        
        $contents = $contents -replace "'\d{1,}\.\d{1,}\.\d{1,}(\.\d{1,})?'", "'$paddedVersion'"

        # According to http://www.tracker-software.com/forum3/viewtopic.php?f=62&t=26831, we can use http://www.docu-track.co.uk/builds/6.0.318.0/xxxx for version-specific URLs

        $hash = Calculate-Hash "http://www.docu-track.co.uk/builds/$paddedVersion/EditorV6.x86.msi"
        $contents = $contents -replace "checksum\s*=\s*'[a-fA-F0-9]+'", "checksum = '$($hash.Hash)'"

        $hash = Calculate-Hash "http://www.docu-track.co.uk/builds/$paddedVersion/EditorV6.x64.msi"
        $contents = $contents -replace "checksum64\s*=\s*'[a-fA-F0-9]+'", "checksum64 = '$($hash.Hash)'"

        $contents | Out-File $installScript -Encoding Utf8

        Write-Host
        Write-Host "Updated chocolateyInstall.ps1."

        return $version
    } else {
        Write-Error "Could not find Version on web page"
        return $null
    }
}

function Update-Version($downloadVersion)
{
    # We use IE because the web page is using JavaScript to dynamically show version release notes
    $ie = New-Object -ComObject InternetExplorer.Application

    $ie.Silent = $true
    $ie.Navigate("https://www.tracker-software.com/product/pdf-xchange-editor/history")
    $ie.Visible = $true

    while($ie.Busy) { Start-Sleep -Milliseconds 100 }


    Start-Sleep -Milliseconds 500

    $html = $ie.Document

    $ul = $html.getElementById("bh-history");

    # version from <a class="active" name="6.0.317.1" href="PDFXE_history.html#6.0.317.1">
    $version = $ul.children[0].children[0].name

    # Current Version:&nbsp; 4.1.3, build 20814, released Dec. 17, 2015
    $isMatch = $content -match "version \d{1,}\.\d{1,}\.\d{1,}(\.\d{1,})?"

    if ($version)
    {
       if ($version -eq $downloadVersion) {
           $releaseNotes = (Parse-ReleaseNotes $html) -join "`n"
       } else {
           $releaseNotes = "http://www.tracker-software.com/product/pdf-xchange-editor/history"
           $version = $downloadVersion
           Write-Host "Release notes not available for $version, so just using URL"
       }

       $nuspec = Join-Path $PSScriptRoot "src/PDFXchangeEditor.nuspec"
       $contents = [xml] (Get-Content $nuspec -Encoding Utf8)

       $contents.package.metadata.version = "$version"
       $contents.package.metadata.releaseNotes = $releaseNotes

       $contents.Save($nuspec)

       Write-Host
       Write-Host "Updated nuspec. Commit this change and open a pull request to the upstream repository on GitHub!"

   }
   else
   {
       Write-Host "Unable to find the release on the download page. Check the regex above"
   }

    $ie.Quit()
}

$version = Update-InstallScript
# $version    = '6.0.321'
if ($version -ne $null) {
    Update-Version $version
}
