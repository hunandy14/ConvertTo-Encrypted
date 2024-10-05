PowerShell 實現 CNG 使用證書加密與解密 
===

快速使用1

```ps1
# 載入模組
irm bit.ly/PsEncrypted|iex

# 設置證書姆印
$thumbprint = 'd6b454009909890d0fd22751a8139cfd6b2f16ab'

# 加密信息
$byte = @"
{
    "AppName": "ConvertTo-Encrypted",
    "Comment": "測試編碼-ㄅㄆㄇあいう"
}
"@ | ConvertTo-OaepEncrypted -Thumbprint $thumbprint

# 解密信息
$byte | ConvertFrom-OaepEncrypted -Thumbprint $thumbprint -EncodingToUTF8

```

<br><br>

快速使用2 (從檔案)

```ps1
&{
    # 載入模組
    irm bit.ly/PsEncrypted|iex
    
    # 設置證書姆印
    $thumbprint = 'd6b454009909890d0fd22751a8139cfd6b2f16ab'
    
    # 加密信息並除存到檔案
    Get-Content "config.json" -Encoding Byte | 
      ConvertTo-OaepEncrypted -OutputFilePath "config.bin" -Thumbprint $thumbprint
    
    # 從檔案解密信息 (省略 `-EncodingToUTF8` 程序會直接輸出二進制流出來)
    Get-Content -Path "config.bin" -Encoding Byte |
      ConvertFrom-OaepEncrypted -Thumbprint $thumbprint -EncodingToUTF8
}

```
