PowerShell 實現 CNG 使用證書加密與解密 
===

快速使用

```ps1
# 載入模組
irm bit.ly/PsEncrypted|iex

# 設置證書姆印
$thumbprint = 'd6b454009909890d0fd22751a8139cfd6b2f16ab'

# 加密檔案
$byte = [System.Text.Encoding]::UTF8.GetBytes(@"
{
    "AppName": "ConvertTo-Encrypted",
    "Comment": "測試編碼ㄅㄆㄇあいう"
}
"@) | ConvertTo-OaepEncrypted -Thumbprint $thumbprint

# 解密檔案
$byte | ConvertFrom-OaepEncrypted -Thumbprint $thumbprint -EncodingToUTF8

```
