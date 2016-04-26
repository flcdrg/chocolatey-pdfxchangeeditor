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

function Update-Version
{
    # We use IE because the web page is using JavaScript to dynamically show version release notes
    $ie = New-Object -ComObject InternetExplorer.Application

    $ie.Silent = $true
    $ie.Navigate("http://www.tracker-software.com/PDFXE_history.html")
    $ie.Visible = $true

    while($ie.Busy) { Start-Sleep -Milliseconds 100 }


    Start-Sleep -Milliseconds 500

    $html = $ie.Document

    $ul = $html.getElementById("bh-history");

    # version from <a class="active" name="6.0.317.1" href="PDFXE_history.html#6.0.317.1">
    $version = $ul.children[0].children[0].name

    # Current Version:&nbsp; 4.1.3, build 20814, released Dec. 17, 2015
    $isMatch = $content -match "Current Version:&nbsp; (?<release>\d{1,}\.\d{1,}\.\d{1,}), build (?<build>\d{1,}), released (?<month>[A-Za-z]{3})\. (?<day>[0-9]{1,2})\, (?<year>[0-9]{4})"

    if ($version)
    {
       $releaseNotes = (Parse-ReleaseNotes $html) -join "`n"

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

Update-Version