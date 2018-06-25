# Sample script to install PointCloudLibrary and pip under Windows
# Authors: Olivier Grisel, Jonathan Helmus, Kyle Kastner, and Alex Willmer
# License: CC0 1.0 Universal: http://creativecommons.org/publicdomain/zero/1.0/

$BASE_CPPCHECK_URL = "https://github.com/danmar/cppcheck/releases/download"

function Download ($filename, $url) 
{
    # TLS 1.2 valid(use Github)
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;

    $webclient = New-Object System.Net.WebClient

    $basedir = $pwd.Path + "\"
    $filepath = $basedir + $filename
    if (Test-Path $filename) 
    {
        Write-Host "Reusing" $filepath
        return $filepath
    }

    # Download and retry up to 3 times in case of network transient errors.
    Write-Host "Downloading" $filename "from" $url
    $retry_attempts = 2
    for ($i = 0; $i -lt $retry_attempts; $i++) {
        try {
            $webclient.DownloadFile($url, $filepath)
            break
        }
        Catch [Exception]{
            Start-Sleep 1
        }
    }

    if (Test-Path $filepath) 
    {
        Write-Host "File saved at" $filepath
        Write-Host $(Get-ChildItem $filepath).Length
    }
    else 
    {
        # Retry once to get the error message if any at the last try
        $webclient.DownloadFile($url, $filepath)
    }

    return $filepath
}

function RunCommand ($command, $command_args) 
{
    Write-Host $command $command_args
    Start-Process -FilePath $command -ArgumentList $command_args -Wait -Passthru
}

function InstallCppCheck ($cppcheck_version, $cppcheck_root)
{
    $platform_suffix = "x64"

    $installer_filename = "cppcheck-" + "$cppcheck_version" + "-" + "$platform_suffix" + "-Setup.msi"
    $url = "$BASE_CPPCHECK_URL" + "/$cppcheck_version" + "/" + "$installer_filename"
    $filepath = Download $installer_filename $url

    Write-Host $filepath
    $current_dir =  [System.IO.Directory]::GetCurrentDirectory()
    Write-Host $current_dir
    $installer_path = $current_dir + "/" + $installer_filename
    # Copy-Item $installer_path $current_dir

    $installer_ext = [System.IO.Path]::GetExtension($filepath)
    Write-Host "Installing $filepath"
    $install_log = $current_dir + "\install.log"
    if ($installer_ext -eq '.msi')
    {
        InstallCppCheckMSI $installer_filename $install_log
    }
    else
    {
        InstallCppCheckEXE $installer_path $install_log
    }

    if (Test-Path $cppcheck_root) 
    {
        Write-Host "CppCheck $cppcheck_version ($architecture) installation complete"
    }
    else 
    {
        Write-Host "Failed to install CppCheck in $cppcheck_root"
        # Exit 1
    }
}


function InstallCppCheckMSI ($msipath, $install_log)
{
    $install_args = "/quiet /qn /norestart"

    RunCommand "schtasks" "/create /tn checkcpp_install /RL HIGHEST /tr `"msiexec.exe /i $msipath $install_args`" /sc once /st 23:59"
    RunCommand "sleep" "10"
    RunCommand "schtasks" "/run /tn checkcpp_install"
    RunCommand "sleep" "180"
    RunCommand "schtasks" "/delete /tn checkcpp_install_install /f"
}


function InstallCppCheckEXE ($exepath, $install_log)
{
    # http://www.ibm.com/support/knowledgecenter/SS2RWS_2.1.0/com.ibm.zsecure.doc_2.1/visual_client/responseexamples.html?lang=ja
    $install_args = "/S /v/qn /v/norestart"

    RunCommand "schtasks" "/create /tn checkcpp_install /RL HIGHEST /tr `"$exepath $install_args`" /sc once /st 23:59"
    RunCommand "sleep" "10"
    RunCommand "schtasks" "/run /tn checkcpp_install"
    RunCommand "sleep" "90"
    RunCommand "schtasks" "/delete /tn checkcpp_install /f"
}

InstallCppCheck $env:CPPCHECK_VERSION $env:CPPCHECK_ROOT

