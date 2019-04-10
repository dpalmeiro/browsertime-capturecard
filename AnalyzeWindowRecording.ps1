param([string]$dir, [string]$output)
. (".\SetPaths.ps1")

$dir = Resolve-Path $dir

$convert = "$imagemagick\convert.exe"

$chop = "0x197"

[array]$files = Get-ChildItem $dir -Filter *.png | select -expand name

$firstframe = 999999
$timestamps = 0..($files.Count - 1)
$f = 0
foreach($file in $files) {
	$test = $file -Match "(.*)frame-(.*)-(.*).png"
	$newname = $Matches[3].PadLeft(6, '0')
	$timestamps[$f] = [convert]::ToInt32($newname)
	$f = $f + 1
	if ([convert]::ToInt32($newname) -lt $firstframe) { $firstframe = [convert]::ToInt32($newname) }
	$ffmpegname = $Matches[2].PadLeft(5, '0')
	Copy "$dir\$file" "$dir\frame$ffmpegname.png"
	#$last = Start-Process -FilePath $convert -ArgumentList "$dir\$file -chop $chop $dir\ms_$newname.png" -NoNewWindow -PassThru
	$last = Start-Process -FilePath $convert -ArgumentList "$dir\$file -resize 1280x720 $dir\frame$ffmpegname.png" -NoNewWindow -PassThru
}

$lastframe = "$($files.Count)".PadLeft(5, '0')
$endframe = "$($files.Count + 1)".PadLeft(5, '0')
Copy "$dir\frame$lastframe.png" "$dir\frame$endframe.png"
Copy "$dir\frame00001.png" "$dir\frame00000.png"

Start-Process -FilePath $ffmpeg -ArgumentList "-y -i $dir\frame%05d.png -vf `"pad=ceil(iw/2)*2:ceil(ih/2)*2`" -pix_fmt yuv420p $dir\tmp-cfr.mp4" -Wait
$last.WaitForExit()

#$firstframename = "$firstframe".PadLeft(6, '0')
#Copy "$dir\ms_$firstframename.png" "$dir\ms_000000.png"

[array]::sort($timestamps)
Add-Content -Path "$dir\tmp.txt" -Value "# timecode format v2`n0`n"
foreach ($ts in $timestamps) {
  Add-Content -Path "$dir\tmp.txt" -Value "$ts`n"
}

$finaltimestamp = ([int]::parse($timestamps[$files.Count - 1]) + 1000)
Add-Content -Path "$dir\tmp.txt" -Value "$finaltimestamp`n"

Start-Process -FilePath $fpsmod -ArgumentList "-o $dir\video.mp4 -t $dir\tmp.txt $dir\tmp-cfr.mp4" -Wait

#$pinfo = New-Object System.Diagnostics.ProcessStartInfo
#$pinfo.FileName = $python
#$pinfo.RedirectStandardError = $true
#$pinfo.RedirectStandardOutput = $true
#$pinfo.UseShellExecute = $false
#$pinfo.WorkingDirectory = $pwd
#$pinfo.Arguments = "visualmetrics.py -d $dir -l --json -p -n -vvv"
#
#$p = New-Object System.Diagnostics.Process
#$p.StartInfo = $pinfo
#$p.Start() | Out-Null
#$p.WaitForExit()
#$stdout = $p.StandardOutput.ReadToEnd()
#$stderr = $p.StandardError.ReadToEnd()

Del "$dir\frame0*.png"
Del "$dir\ms_*.png"
Del "$dir\tmp.txt"
Del "$dir\tmp-cfr.mp4"

#$out = $stdout | ConvertFrom-Json
#
#$progress = $out.VisualProgress.split(", ", [System.StringSplitOptions]::RemoveEmptyEntries)
#$parsedprogress = New-Object 'object[,]' $progress.Count,2
#
#$firstchangeframe = [array]::indexof($timestamps, $out.FirstVisualChange)
#$drawtext = "FirstVisualChange\: $($out.FirstVisualChange)"
#$drawtextstring = "drawtext=enable='between(n,$firstchangeframe,100000)':fontfile=/Windows/Fonts/Tahoma.ttf:fontcolor='White':box=1:boxcolor='Black':boxborderw=2:text='$drawtext':x=(w-tw)/2:y=40"
#$lastchangeframe = [array]::indexof($timestamps, $out.LastVisualChange)
#$drawtext = "LastVisualChange\: $($out.LastVisualChange)"
#$drawtextstring += ",drawtext=enable='between(n,$lastchangeframe,100000)':fontfile=/Windows/Fonts/Tahoma.ttf:fontcolor='White':box=1:boxcolor='Black':boxborderw=2:text='$drawtext':x=(w-tw)/2:y=60"
#$drawtext = "SpeedIndex\: $($out.SpeedIndex)"
#$drawtextstring += ",drawtext=enable='between(n,$lastchangeframe,100000)':fontfile=/Windows/Fonts/Tahoma.ttf:fontcolor='White':box=1:boxcolor='Black':boxborderw=2:text='$drawtext':x=(w-tw)/2:y=80"
#for ($i = 0; $i -lt $progress.Count ; $i++) {
#    $tmp = $progress[$i].split("=")
#	$parsedprogress[$i,0] = $tmp[0]
#	$parsedprogress[$i,1] = $tmp[1]
#}
#
#for ($i = 0; $i -lt $progress.Count - 1 ; $i++) {
#    $startts = $parsedprogress[$i,0]
#	$startframe = [array]::indexof($timestamps, [int]::parse($startts))
#	$i2 = $i + 1
#	$endts = $parsedprogress[$i2,0]
#	$endframe = [array]::indexof($timestamps, [int]::parse($endts)) - 1
#
#	$drawtext = $parsedprogress[$i,1].TrimEnd("%")
#    $drawtextstring = $drawtextstring + ",drawtext=enable='between(n,$startframe,$endframe)':fontfile=/Windows/Fonts/Tahoma.ttf:fontcolor='White':box=1:boxcolor='Black':boxborderw=2:text='$drawtext':x=(w-tw)/2:y=20"
#}
#
#$last = $progress.Count - 1
#$startts = $parsedprogress[$last,0]
#$startframe = [array]::indexof($timestamps, [int]::parse($startts))
#$drawtext = $parsedprogress[$last,1].TrimEnd("%")
#$drawtextstring = $drawtextstring + ",drawtext=enable='between(n,$startframe,100000)':fontfile=/Windows/Fonts/Tahoma.ttf:fontcolor='White':box=1:boxcolor='Black':boxborderw=2:text='$drawtext':x=(w-tw)/2:y=20"
#Start-Process -FilePath $ffmpeg -ArgumentList "-i $dir\video.mp4 -vf `"$drawtextstring`" $output.mp4"
#Write-Output "FirstVisualChange: $($out.FirstVisualChange) LastVisualChange: $($out.LastVisualChange) SpeedIndex: $($out.SpeedIndex)"
