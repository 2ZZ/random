# Converts XML export from Thycotic SecretServer to Bitwarden JSON import format
# Ref: https://bitwarden.com/help/condition-bitwarden-import/

$secretServerExportXML = "$HOME\Downloads\export.xml"
$bitwardenImportJSON = "$HOME\Desktop\bitwarden-import.json"
$items = @()

Select-Xml -Path $secretServerExportXML -XPath '//Secrets/Secret' | ForEach-Object {
    $item = [PSCustomObject]@{
        "type" = 1
        "name" = $_.Node.SecretName
        "notes" = ($_.Node.SecretItems.SecretItem | Where-Object { $_.FieldName -eq "Notes" }).Value
        "login" = @{
            "username" = ($_.Node.SecretItems.SecretItem | Where-Object { $_.FieldName -eq "Username" }).Value
            "password" = ($_.Node.SecretItems.SecretItem | Where-Object { $_.FieldName -eq "Password" }).Value
            "uris" = @()
        }
        "fields" = @()
    }
    # Map "Resource" to URI field if it looks like a URL
    [String]$resource = ($_.Node.SecretItems.SecretItem | Where-Object { $_.FieldName -eq "Resource" }).Value
    if ($resource) {
        if ($resource.StartsWith("http")) {
            $item.login.uris += @{
                "uri" = $resource
                "match" = $null
            }
        } else {
            $item.fields += @{
                "name" = "Resource"
                "value" = $resource
                "type" = 0
            }
        }
    }
    $items += $item
}

[PSCustomObject]@{
    "folders" = @()
    "items" = $items
} | Convertto-Json -Depth 99 | Set-Content -Path $bitwardenImportJSON
