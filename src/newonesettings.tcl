package provide newonesettings 1.0
class NewOnesettings {
    inherit itk::Widget Settings2
    constructor { args } { }
}
body NewOnesettings::constructor { args } {
    eval itk_initialize $args
}
usual NewOnesettings { 
}
