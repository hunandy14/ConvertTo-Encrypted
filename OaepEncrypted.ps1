using namespace System.Security.Cryptography


function ConvertTo-OaepEncrypted {
    [CmdletBinding(DefaultParameterSetName = "String")]
    param (
        # 輸入 string
        [Parameter(ValueFromPipeline, ParameterSetName = "String", Mandatory)]
        [string]$InputString,
        [Text.Encoding]$Encoding = [Text.Encoding]::UTF8,
        # 輸入 byte
        [Parameter(ValueFromPipeline, ParameterSetName = "Bytes", Mandatory)]
        [byte[]]$InputBytes,
        # 輸出
        [Parameter(Position = 0)]
        [string]$OutputFilePath,
        # 證書
        [Parameter(Mandatory)]
        [string]$Thumbprint,
        [string]$CertificatePath = "Cert:\CurrentUser\My\",
        [RSAEncryptionPadding]$RSAEncryptionPadding = [RSAEncryptionPadding]::OaepSHA256
    )
    
    begin {
        
        # 獲取證書
        $certificate = Get-ChildItem -Path $CertificatePath | Where-Object { $_.Thumbprint -eq $Thumbprint }
        if (-not $certificate) {
            Write-Error "Certificate with thumbprint '$Thumbprint' not found at '$CertificatePath' location." -EA Stop
        }
        
        # 預處理輸入的路上境
        if ($OutputFilePath) {
            # 同步 .Net 環境工作目錄
            [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
            # 建立資料夾
            $OutputFilePath = [IO.Path]::GetFullPath($OutputFilePath)
            $dirPath = Split-Path $OutputFilePath
            if (-not (Test-Path $dirPath)) { mkdir $dirPath -EA Stop |Out-Null }
        }
        
        # 用來累積多行數據
        $inputData = @()
        
        # 從第二行開始在開頭加上換行
        $secLine = $false
        
    } process {
        
        # 從管道獲取輸入資料
        if ($PSCmdlet.ParameterSetName -eq "String") {
            if ($secLine) { $inputData += "`r`n" } else { $secLine = $true }
            $inputData += $InputString
            
        } elseif ($PSCmdlet.ParameterSetName -eq "Bytes") {
            $inputData += $InputBytes
        }
        
    } end {
        
        # 轉換為二禁制
        if ($PSCmdlet.ParameterSetName -eq "String") {
            $byte = $Encoding.GetBytes($inputData)
        } elseif ($PSCmdlet.ParameterSetName -eq "Bytes") {
            $byte = $inputData
        }
        
        # 加密文字 (CNG::OaepSHA256)
        $rsaPublicKey = [X509Certificates.RSACertificateExtensions]::GetRSAPublicKey($certificate)
        $encryptedData = $rsaPublicKey.Encrypt($byte,$RSAEncryptionPadding)
        
        # 將加密的數據寫入檔案
        if ($OutputFilePath) {
            Set-Content -Path $OutputFilePath -Value $encryptedData -Encoding Byte -EA Stop
            Write-Host "Text encrypted and saved to '$OutputFilePath'"
        } else {
            $encryptedData
        }
    }
} # Get-Content config.json -Encoding Byte | ConvertTo-OaepEncrypted -OutputFilePath config.bin -Thumbprint d6b454009909890d0fd22751a8139cfd6b2f16ab


function ConvertFrom-OaepEncrypted {
    param (
        # 輸入
        [Parameter(ValueFromPipeline, Mandatory)]
        [byte[]]$InputByte,
        # 輸出
        [switch]$EncodingToUTF8,
        # 證書
        [Parameter(Mandatory)]
        [string]$Thumbprint,
        [string]$CertificatePath = "Cert:\CurrentUser\My\",
        [RSAEncryptionPadding]$RSAEncryptionPadding = [RSAEncryptionPadding]::OaepSHA256
    )
    
    begin {
        
        # 獲取證書
        $certificate = Get-ChildItem -Path $CertificatePath | Where-Object { $_.Thumbprint -eq $Thumbprint }
        if (-not $certificate) {
            Write-Error "Certificate with thumbprint '$Thumbprint' not found at '$CertificatePath' location." -EA Stop
        } if (-not $certificate.HasPrivateKey) {
            Write-Error "The selected certificate with thumbprint '$Thumbprint' does not have a private key and cannot perform decryption." -EA Stop
        }
        
        # 用來累積Byte數據
        $encryptedData = @()
        
    } process {
        
        # 累加每行輸入的數據
        $encryptedData += $InputByte
        
    } end {
        
        # 解密數據(CNG::OaepSHA256)
        $rsaPrivateKey = [X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)
        $decryptedData = $rsaPrivateKey.Decrypt($encryptedData, $RSAEncryptionPadding)
        
        # 將解密的數據轉回文字格式
        if ($EncodingToUTF8) {
            [Text.Encoding]::UTF8.GetString($decryptedData)
        } else{
            $decryptedData
        }
        
    }
} # Get-Content -Path config.bin -Encoding Byte | ConvertFrom-OaepEncrypted -Thumbprint d6b454009909890d0fd22751a8139cfd6b2f16ab -EncodingToUTF8
