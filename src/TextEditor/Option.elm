module TextEditor.Option exposing
    ( Option
    , defaultOptions
    )
{-|
@docs Option, defaultOptions
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
defaultOptions : Option
defaultOptions =
    { tabOrder = 4
    , indentTabsMode = False
    , showControlCharactor = False
    }

