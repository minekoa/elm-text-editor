module TextEditor.Option exposing
    ( Option
    , defaulOptions
    )
{-|
@docs Option, defaulOptions

-}


{-| Editor Options, for Command and Rendering
-}
type alias Option =
    { tabOrder : Int
    , indentTabsMode : Bool
    , showControlCharactor : Bool
    }

{-| Create Editor Options by default.

* tabOrder = 4
* indentTabsMode = False
* showControlCharactor = False
-}
defaulOptions : Option
defaulOptions =
    { tabOrder = 4
    , indentTabsMode = False
    , showControlCharactor = False
    }

    
