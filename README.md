# Introduction
This repo contains file used for testing DLP.

The initial dataset was downloaded from:


<a href="https://dlptest.com/sample-data/"><img src="https://dlptest.com/dlp-test-logo.png" alt="Description" width="200px"></a>


All values are synthetic — safe to use as DLP detection targets. Identity document images are publicly available samples suitable for OCR and image-based DLP testing.

# PII / PCI Test Datasets
All values are fabricated test data — not real PII or PCO.


# Document Library Files
Sample identity document images for OCR-based and image-content DLP testing, plus large files for throughput and upload-limit testing.

# create-large-testfile.ps1
The script creates a temporary file containing random data to fill the ZIP to approximately the requested size, while accounting for the additional files.
PowerShell script: `create-large-testfile.ps1`


## Usage examples
Create a 100 MB ZIP:
```powershell
.\create-large-testfile.ps1 -SizeMB 100 -OutputPath "C:\Temp\test.zip"
```

Create a 500 MB ZIP containing two additional files:
```powershell
.\create-large-testfile.ps1 `
    -SizeMB 500 `
    -OutputPath "C:\Temp\test.zip" `
    -Files "C:\Temp\report.pdf", "C:\Temp\config.json"
```

Create a 1 GB ZIP:
```powershell
.\create-large-testfile.ps1 -SizeMB 1024 -OutputPath "C:\Temp\test.zip"
```

## Behavior
The ZIP will contain your specified files along with a padding.bin file containing random data.

The script targets the total compressed ZIP size, not the uncompressed contents. The result may exceed the requested size slightly because of ZIP metadata and compression overhead.

If your additional files already exceed the requested size, the script includes them without adding padding.

One implementation detail: this script requires PowerShell 5.1 or newer, and the destination ZIP must not already exist.