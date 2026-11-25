# Security and Disk Safety Policy

1. Never erase, format, repartition, or overwrite a user drive without explicit approval.
2. Live mode must not mount internal disks read-write automatically.
3. Installer must display the exact destination device, model, and capacity before destructive actions.
4. Require a separate confirmation step before changing partition tables.
5. Preserve Secure Boot where supported; document any limitation rather than casually instructing users to disable it.
6. Keep SELinux enforcing.
7. Keep firewall defaults enabled.
8. Do not embed credentials, API keys, private signing keys, or user passwords in source control or images.
9. Sign production artifacts and publish checksums.
10. Keep a software bill of materials and license inventory.
11. Keep Stable, Beta, and Experimental release channels separate.
