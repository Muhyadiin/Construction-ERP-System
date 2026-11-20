# Kobci Construction ERP for Windows

This community preview runs on 64-bit Windows. Setup installs the web application, its local server and embedded PostgreSQL for the current user. No ERP subscription, Docker installation, or external database account is required.

**Publisher warning.** The installer has no Windows publisher signature. Keep SmartScreen and your organization's device policies enabled. Use a test computer for evaluation until a publisher-signed build is available.

1. Download the installer and SHA256SUMS.txt from the release page. In PowerShell, run the command below from the download directory and compare the hash with the installer entry in SHA256SUMS.txt.
2. On an evaluation machine that permits this package, run Setup. Open **Kobci Construction ERP** from Start. Leave its server window open.
3. The app opens in your browser at http://127.0.0.1:8765. First startup initializes the database. Register the first account to create the workspace administrator. Keep its password private.
4. Close the browser and press Ctrl+C in the server window to stop. Windows Settings → Apps can remove the program. Your project data remains under %LOCALAPPDATA%\Kobci Construction ERP\Data.

~~~powershell
Get-FileHash .\Kobci-Construction-ERP-Windows-x64-Preview-1.exe -Algorithm SHA256
~~~

The preview includes the bilingual English/Somali project cost report and USD/Somaliland-shilling project accounting. Warehouse and direct payroll posting, wider Somali localization, and commercial acceptance are still in progress. The application uses the browser interface. Proprietary CAD converters are excluded. Obtain optional converters from their publisher under the terms that apply to your use.

Built on OpenConstructionERP. This product is not affiliated with, endorsed by, or sponsored by DataDrivenConstruction. The source, build instructions, upstream notices and GNU Affero General Public License accompany this release. [Corresponding source](https://github.com/Muhyadiin/Construction-ERP-System/tree/kobci-windows-preview-1) · [Upstream notices](https://github.com/Muhyadiin/Construction-ERP-System/blob/kobci-windows-preview-1/NOTICE) · [Converter licence](https://github.com/datadrivenconstruction/cad2data-Revit-IFC-DWG/blob/v2026.10.0/LICENSE-PROPRIETARY)
