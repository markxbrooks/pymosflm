#!/usr/local/bin/wish8.4
# $Id: png2gif.tcl,v 1.1.1.1 2006/08/21 11:19:53 harry Exp $

package require Img

lappend auto_path .
source iconlibrary.tcl

# Create new iconlibrary file
set file [open giflibrary.tcl w]
puts $file "package provide giflibrary 1.0"
puts $file ""
puts $file "package require Img"
puts $file ""
puts $file "namespace eval img {}"
puts $file ""

# Loop through images
foreach i_image [lsort [image names]] {

    puts $file "image create photo $i_image -data \"[$i_image data -format gif]\""
    puts $file ""
}

close $file

exit
