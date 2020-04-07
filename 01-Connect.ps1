$TenantName = "cpsglobaldev"
$TenantAdminUrl = "https://$TenantName-admin.sharepoint.com"
$TenantUrl = "https://$TenantName.sharepoint.com"

Write-Host "Connecting ..." -ForegroundColor Cyan
Connect-SPOService $TenantAdminUrl
Connect-PnPOnline $TenantUrl
