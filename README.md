KiCad EDA Mac OS X builder
==========================

Q & A
-----
**Q:** Yet another KiCad OS X builder? Why?  
**A:** The other ones, I could find, are either hopelessly outdated or incomplete. This one is just a small Makefile utilizing the OS X dependency builder already present in the KiCad source.

**Q:** What does it do, exactly?  
**A:** It downloads and compiles the few dependencies needed by the KiCad build environment (bzr, cmake, wxWidgets), then proceeds with building kicad.app and (optionally) packages the kicad.app as a disk image (DMG) for easy distribution. Furthermore, it downloads the kicad-library (common symbols for KiCad eechema) and packages it as tarball.

**Q:** What are the prerequisites for using this builder?  
**A:** As opposed to many other KiCad OS X builders out there, this one only requires the user to manually install the XCode Command Line Tools (compilers etc.). All other dependencies are downloaded and compiled automatically.

**Q:** Why not just commit these fixes/enhancements upstream?  
**A:** I certainly intend to submit all the patches, I can - but my main focus was getting a working kicad.app

Instructions
------------
To build a disk image containing the kicad.app and KiCad demos along with a tarball containing the KiCad eeschema symbols, run the following command:

    make dmg

The resulting tarball with eeschema symbols can either be unpacked to `/` (all users) or to `$HOME` (current user only):

    sudo tar xf kicad-library_*.tar.gz -C /

or:

    tar xf kicad-library_*.tar.gz -C $HOME

Next, copy the `*.app` files/links from the disk image (DMG) to either `/Applications/` (all users) or `$HOME/Applications/` (current user only).
