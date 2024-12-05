module Pages.NotFound exposing (view)

import Html.Styled exposing (div, h1, text)



{-
   Exercises:
   - Try to use assets from the project! How do I render the JS image inside Home.elm?
-}


view : { title : String, body : List (Html.Styled.Html msg) }
view =
    { title = "Not found"
    , body = body
    }


body : List (Html.Styled.Html msg)
body =
    [ div []
        [ h1 [] [ text "¡Not found page!" ]
        ]
    ]
