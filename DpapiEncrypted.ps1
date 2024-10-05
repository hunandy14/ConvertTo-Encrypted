function ConvertTo-DpapiEncrypted {
    param (
        [Parameter(ValueFromPipeline)]
        [string]$InputObject,
        [Parameter(Position = 0)]
        [string]$OutputFilePath
    )
    
    begin {
        
        # 建立資料夾
        if ($OutputFilePath) {
            $dirPath = Split-Path $OutputFilePath
            if (-not (Test-Path $dirPath)) { mkdir $dirPath -EA 1 |Out-Null }
        }
        
        # 用來累積多行數據
        $inputData = @()
        
        # 從第二行開始在開頭加上換行
        $secLine = $false
        
    } process {
        
        # 第二行開始再開頭加換行符
        if ($secLine) {
            $inputData += "`r`n"
        } else {
            $secLine = $true
        }
        
        # 累加輸入數據
        $inputData += $InputObject
        
    } end {
        
        # 加密文字 (DPAPI)
        Add-Type -AssemblyName System.Security
        $encryptedData = [Security.Cryptography.ProtectedData]::Protect(
            [Text.Encoding]::UTF8.GetBytes($inputData), 
            $null, 
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        
        # 將加密的數據寫入檔案
        if ($OutputFilePath) {
            Set-Content -Path $OutputFilePath -Value $encryptedData -Encoding Byte -EA 1
            Write-Host "Text encrypted and saved to $OutputFilePath"
        } else {
            $encryptedData
        }
    }
} # Get-Content .\config.json -Encoding UTF8 | ConvertTo-DpapiEncrypted -OutputFilePath .\config.bin


function ConvertFrom-DpapiEncrypted {
    param (
        [Parameter(ValueFromPipeline)]
        [byte[]]$InputObject
    )
    
    begin {
        
        # 用來累積Byte數據
        $encryptedData = @()
        
    } process {
        
        # 累加每行輸入的數據
        $encryptedData += $InputObject
        
    } end {
        
        # 解密數據(DPAPI)
        Add-Type -AssemblyName System.Security
        $decryptedData = [Security.Cryptography.ProtectedData]::Unprotect(
            $encryptedData, 
            $null, 
            [Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        
        # 將解密的數據轉回文字格式
        [Text.Encoding]::UTF8.GetString($decryptedData)
        
    }
} # Get-Content -Path "config.bin" -Encoding Byte | ConvertFrom-DpapiEncrypted
