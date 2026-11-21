# Kobci Construction ERP for Windows — Desktop Preview 2

The 64-bit installer includes the native Kobci window, the ERP application and embedded PostgreSQL. Local use requires no ERP subscription, Docker installation or external database account.

**Upgrading from Preview 1.** Close the earlier Kobci server window if it is running. Run the new installer under the same Windows account. Setup uses the same data folder and updates the existing Start menu shortcut. Leave your previous installation and its data in place.

1. Download the Windows installer and SHA256SUMS.txt. In PowerShell, use the command below to check the download against the published SHA-256.
2. Run Setup and select **Open Kobci Construction ERP** on the last screen, or open **Kobci Construction ERP** from Start.
3. Keep the Kobci window open. It displays database and server startup progress, then loads the ERP in that window once the local server is ready. The desktop app uses Microsoft Edge WebView2. Setup includes the Microsoft-signed x64 WebView2 offline installer and runs it when the runtime is missing.
4. If the server exits during startup, the window displays the failure and offers **Copy details**, **Open log folder** and **Repair**. The launcher log is in `%LOCALAPPDATA%\Kobci Construction ERP\Data\logs\desktop-launcher.log`. Review error details before sharing them.
5. On closing Kobci, the native launcher requests a graceful shutdown of the server it started. Windows Settings → Apps can remove the application. Project data remains in `%LOCALAPPDATA%\Kobci Construction ERP\Data`.

~~~powershell
Get-FileHash .\Kobci-Construction-ERP-Windows-x64-Preview-2.exe -Algorithm SHA256
~~~

**Publisher status.** The release notes report the Windows publisher signature status of the downloadable installer. GitHub signs a build provenance attestation for the final executable. Keep SmartScreen and organizational device protections enabled. This is a community preview for evaluation. The bilingual English/Somali project cost report and USD/Somaliland-shilling project accounting are included. Warehouse and direct payroll posting, wider Somali localization and commercial acceptance are still in progress. The package excludes proprietary CAD converters.

Built on OpenConstructionERP. This product is not affiliated with, endorsed by, or sponsored by DataDrivenConstruction. Corresponding source is available under the GNU Affero General Public License. [Source and build workflow](https://github.com/Muhyadiin/Construction-ERP-System/tree/kobci-windows-preview-2) · [Upstream notices](https://github.com/Muhyadiin/Construction-ERP-System/blob/kobci-windows-preview-2/NOTICE) · [Microsoft WebView2 distribution](https://learn.microsoft.com/microsoft-edge/webview2/concepts/distribution)
