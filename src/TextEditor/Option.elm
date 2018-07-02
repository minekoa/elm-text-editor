module TextEditor.Option exposing
    ( Option
    , editorLikeOptions
    , notepadLikeOptions
    )
{-|
@docs Option

@docs notepadLikeOptions, editorLikeOptions
-}


{-| Editor Options, for Command and Rendering
-}
type alias Option =
    { tabOrder : Int
    , indentTabsMode : Bool
    , showControlCharactor : Bool
    }


{-| Create Editor Options (notepad like style)

* tabOrder = 8
* indentTabsMode = True
* showControlCharactor = False
-}
notepadLikeOptions : Option
notepadLikeOptions =
    { tabOrder = 8
    , indentTabsMode = True
    , showControlCharactor = False
    }

{-| Create Editor Options (text editor like)

* tabOrder = 4
* indentTabsMode = False
* showControlCharactor = False
-}
editorLikeOptions : Option
editorLikeOptions =
    { tabOrder = 4
    , indentTabsMode = False
    , showControlCharactor = True
    }



