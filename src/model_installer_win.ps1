#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Help,
    [int]$ModelNum = 1,
    [string]$InstallDir = $HOME,
    [switch]$Interactive,
    [string]$PythonOption = "N",
    [int]$PrintModelName = 0,
    [string]$Token = "",
    [string]$ModelWeights = ""
)

$N_MODELS = 12

function Write-StratisLogo {
    Write-Host "==============================================="
    Write-Host "             CERR Segmentation"
    Write-Host "==============================================="
    Write-Host " "
    Write-Host "Medical Physics Department, Memorial Sloan Kettering Cancer Center, New York, NY"
    Write-Host " "
}

function Get-ModelName {
    param([int]$N)
    switch ($N) {
        1  { return "CT_cardiac_structures_deeplab" }
        2  { return "CT_LungOAR_incrMRRN" }
        3  { return "MR_Prostate_Deeplab" }
        4  { return "CT_Lung_SMIT" }
        5  { return "MRI_Pancreas_Fullshot_AnatomicCtxShape" }
        6  { return "CT_HeadAndNeck_OARs" }
        7  { return "CT_HN_SMIT" }
        8  { return "CT_HeartSubstruct_SMIT" }
        9  { return "CT_WHOLEBODY_SMITplus" }
        10 { return "MR_Rectum_GTV_SMIT" }
        11 { return "MR_HN_Nodule_SMIT" }
        12 { return "CT_Lung_OAR_SMITplus" }
        default { return "Error" }
    }
}

function Show-ModelOptions {
    param([int]$NModels)
    Write-Host "The following are the list of available models. When passing the argument to installer, select the number of the model to download: "
    for ($N = 1; $N -le $NModels; $N++) {
        $name = Get-ModelName -N $N
        Write-Host ("                  {0}.  {1}" -f $N, $name)
    }
}

function Show-HelpText {
    param([int]$NModels)
    Write-Host "Usage Information: "
    Write-Host "  Flags: "
    Write-Host "          -Interactive       : Run installer in interactive mode (no argument)"
    Write-Host "          -ModelNum          : [1-$NModels] Integer number to select model to install. For list of available options, see below. "
    Write-Host "          -InstallDir        : Directory to install model with network weights "
    Write-Host "          -PythonOption      : [P/C/U/N] Setup and install Python environment P: Conda env from requirements; C: Conda pack download; U: uv; N: No install. "
    Write-Host "          -PrintModelName    : [1-$NModels] Print the model name of number argument "
    Write-Host "          -ModelWeights      : Provide URL to tar archive for model weights (optional) "
    Write-Host "          -Token             : User credentials for private GitHub repo, format is user:token "
    Write-Host "          -Help              : Print help menu "
    Write-Host " "
    Show-ModelOptions -NModels $NModels
}

function Show-IntroText {
    Write-Host "Welcome to the CERR segmentation model installer! For usage information, run with -Help flag"
    Write-Host " "
}

function Get-DecodedFromFile {
    param(
        [string]$FilePath,
        [string]$Key
    )
    $line = Select-String -Path $FilePath -Pattern $Key | Select-Object -First 1
    if (-not $line) { return "" }
    $hash = ($line.Line -split '\s+')[1]
    if (-not $hash) { return "" }

    try {
        $bytes = [System.Convert]::FromBase64String($hash)
        $inStream = New-Object System.IO.MemoryStream(, $bytes)
        $gzip     = New-Object System.IO.Compression.GZipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
        $reader   = New-Object System.IO.StreamReader($gzip)
        $result   = $reader.ReadToEnd()
        $reader.Close()
        return $result.Trim()
    }
    catch {
        Write-Warning "Failed to decode value for key '$Key': $_"
        return ""
    }
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

Write-StratisLogo
Show-IntroText

if ($Help) {
    Show-HelpText -NModels $N_MODELS
    exit 0
}

if ($PrintModelName -ge 1) {
    Write-Host (Get-ModelName -N $PrintModelName)
    exit 0
}

# Validate Python option
if ($PythonOption -ne "P" -and $PythonOption -ne "C" -and $PythonOption -ne "U") {
    $PythonOption = "N"
    Write-Host "Selected -PythonOption invalid, defaulting to N"
}

$ModelName = Get-ModelName -N $ModelNum
if ($ModelName -eq "Error") {
    Write-Warning "Invalid model number specified: $ModelNum"
}

# ------------------------------------------------------------------
# Interactive Mode
# ------------------------------------------------------------------
if ($Interactive) {
    Write-Host "Interactive installation mode selected."
    Write-Host "======================================="
    Write-Host " "
    Write-Host "Press Ctrl-C at any time to exit"
    Write-Host " "
    Write-Host "Step 1. Model Selection"
    Write-Host "***********************"
    Write-Host " "
    Show-ModelOptions -NModels $N_MODELS
    $usrAns = Read-Host "Please select model to install on local machine [$ModelNum]"
    if ($usrAns -ne "") { $ModelNum = [int]$usrAns }

    $ModelName = Get-ModelName -N $ModelNum
    if ($ModelName -ne "Error") {
        Write-Host "Model selected is $ModelNum. $ModelName"
    }
    else {
        Write-Host "Error, no valid model selected [$ModelNum]"
        exit 1
    }

    Write-Host " "
    $usrAns = Read-Host "Please provide GitHub access token if needed (format user:tokenstring), otherwise press [Enter]"
    $Token = $usrAns

    Write-Host "Step 2. Installation Directory"
    Write-Host "******************************"
    Write-Host " "
    $usrAns = Read-Host "Please specify installation directory [$InstallDir]"
    if ($usrAns -ne "") { $InstallDir = $usrAns }
    Write-Host "Installation directory selected is $InstallDir"

    Write-Host " "
    Write-Host "Step 3. Python Option"
    Write-Host "*********************"
    Write-Host " "
    Write-Host "Please select the option to indicate if the installer should create the Python environment [$PythonOption]: "
    Write-Host "  P : Set up Conda environment from repository requirements.txt file"
    Write-Host "  C : Download Conda-Pack environment"
    Write-Host "  U : Set up uv virtual environment"
    Write-Host "  N : No Python setup"
    $usrAns = Read-Host "Selection"
    if ($usrAns -ne "") {
        if ($usrAns -ne "P" -and $usrAns -ne "C" -and $usrAns -ne "U") {
            $PythonOption = "N"
        }
        else {
            $PythonOption = $usrAns
        }
    }
    Write-Host "Python setup option selected is $PythonOption"
    Write-Host "Proceeding with installation and setup"
}
else {
    $ModelName = Get-ModelName -N $ModelNum
}

# ------------------------------------------------------------------
# Commence with install
# ------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Set-Location -LiteralPath $InstallDir

if ([string]::IsNullOrEmpty($Token)) {
    $ModelGit = "https://github.com/cerr/$ModelName.git"
}
else {
    $ModelGit = "https://$Token@github.com/cerr/$ModelName.git"
}

Write-Host "git clone $ModelGit"
git clone $ModelGit

$ModelFolder = Join-Path $InstallDir $ModelName
Set-Location -LiteralPath $ModelFolder

if ([string]::IsNullOrEmpty($ModelWeights)) {
    $ModelWeights = Get-DecodedFromFile -FilePath "model.txt" -Key "MODEL_WEIGHTS"
}

Write-Host "curl -L -o model_weights.tar.gz $ModelWeights"
curl.exe -L -o model_weights.tar.gz $ModelWeights

Write-Host "tar xf model_weights.tar.gz"
tar.exe xf model_weights.tar.gz
Remove-Item -LiteralPath "model_weights.tar.gz" -Force

switch ($PythonOption) {
    "C" {
        # Download conda-pack
        $CondaPackDir = Join-Path $ModelFolder "conda-pack"
        New-Item -ItemType Directory -Path $CondaPackDir -Force | Out-Null
        Set-Location -LiteralPath $CondaPackDir

        $CondaPack = Get-DecodedFromFile -FilePath (Join-Path $ModelFolder "model.txt") -Key "CONDAPACK"
        Write-Host "curl -L -o condapack.tar.gz $CondaPack"
        curl.exe -L -o condapack.tar.gz $CondaPack
        Write-Host "tar xf condapack.tar.gz"
        tar.exe xf condapack.tar.gz
        Remove-Item -LiteralPath "condapack.tar.gz" -Force
    }

    "P" {
        # Set up Conda environment from environment.yml
        $condaInfo = conda info 2>$null | Select-String "base environment"
        if (-not $condaInfo) {
            Write-Host "Anaconda may not be installed; python setup cannot continue"
            Write-Host "Exiting."
            exit 1
        }

        conda deactivate
        conda env create -f (Join-Path $ModelFolder "environment.yml")

        # Read env name from first line of environment.yml (e.g. "name: myenv")
        $firstLine = Get-Content (Join-Path $ModelFolder "environment.yml") | Select-Object -First 1
        $ModelName = ($firstLine -split '\s+')[1]
        Write-Host "Created Conda environment: $ModelName"
    }

    "U" {
        Write-Host "uv environment install option specified"
        Set-Location -LiteralPath $ModelFolder

        $ConfigFile    = "uv_config.txt"
        $PythonVersion = ""
        $ExtraUvFlags  = ""

        if (Test-Path -LiteralPath $ConfigFile) {
            $pvLine = Select-String -Path $ConfigFile -Pattern '^python_version=' | Select-Object -First 1
            if ($pvLine) {
                $PythonVersion = ($pvLine.Line -replace '^python_version=', '').Trim()
            }

            $flLine = Select-String -Path $ConfigFile -Pattern '^uv_flags=' | Select-Object -First 1
            if ($flLine) {
                $ExtraUvFlags = ($flLine.Line -replace '^uv_flags=', '').Trim()
            }
        }

        if (-not [string]::IsNullOrEmpty($PythonVersion)) {
            Write-Host "Creating uv virtual environment with specified Python version: $PythonVersion"
            uv venv .venv --python $PythonVersion
        }
        else {
            uv venv .venv
        }

        # Install each requirements file under requirements\
        $reqFiles = Get-ChildItem -Path "requirements\*.txt" -ErrorAction SilentlyContinue
        foreach ($req in $reqFiles) {
            if (-not [string]::IsNullOrEmpty($ExtraUvFlags)) {
                # Split flags into individual tokens so they pass correctly
                $flagArgs = $ExtraUvFlags -split '\s+'
                uv pip install -p .venv @flagArgs -r $req.FullName
            }
            else {
                uv pip install -p .venv -r $req.FullName
            }
        }
    }

    "N" {
        Write-Host "No Python setup selected."
    }

    default {
        Write-Host "No Python setup selected."
    }
}   # <-- closes the switch ($PythonOption) block

Write-Host " "
Write-Host "Installation complete."