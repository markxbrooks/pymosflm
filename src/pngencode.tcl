#!/usr/local/bin/wish8.4
# $Id: pngencode.tcl,v 1.3 2011/01/19 16:44:38 ojohnson Exp $

foreach i_image [glob [file join / lmb home ojohnson docs icons *.png]] {
    puts "Encoding $i_image"
    exec echo "image create photo ::img::[file rootname [file tail $i_image]] -data \"" >> new_pngs.data
    exec /usr/bin/base64 $i_image >> new_pngs.data
    exec echo "\""  >> new_pngs.data
}
foreach i_image [glob [file join / lmb home ojohnson docs icons *.gif]] {
    puts "Encoding $i_image"
    exec echo "image create photo ::img::[file rootname [file tail $i_image]] -data \"" >> new_gifs.data
    exec /usr/bin/base64 $i_image >> new_gifs.data
    exec echo "\""  >> new_gifs.data
}
exit
