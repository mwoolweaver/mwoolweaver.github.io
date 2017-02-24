echo Creating New .deb’s

dpkg-deb -Zlzma -b raw/FixBrokenClassicDock deb/
dpkg-deb -Zlzma -b raw/FixBrokenModernDock deb/
