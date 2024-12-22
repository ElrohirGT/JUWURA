module Theme exposing (colors, cssColors, cssSpacing, fontFamilies, fontSizes, locale, spacing)

import Css exposing (hex, px)
import FormatNumber.Locales exposing (Decimals(..), usLocale)


colors =
    { red_50 = "#faebec"
    , red_100 = "#efbfc3"
    , red_200 = "#e7a1a6"
    , red_300 = "#db767d"
    , red_400 = "#d55b64"
    , red_500 = "#ca323d"
    , red_600 = "#b82e38"
    , red_700 = "#8f242b"
    , red_800 = "#6f1c22"
    , red_900 = "#55151a"
    , white_50 = "#fdfdfd"
    , white_400 = "#efefeb"
    , white_700 = "#a7a7a3"
    , black_300 = "#6e6e6e"
    , black_400 = "#515151"
    , black_450 = "#282828"
    , black_470 = "#363636"
    , black_490 = "#191919"
    , black_500 = "#010101"
    }


cssColors =
    { red_50 = hex (String.dropLeft 1 colors.red_50)
    , red_100 = hex (String.dropLeft 1 colors.red_100)
    , red_200 = hex (String.dropLeft 1 colors.red_200)
    , red_300 = hex (String.dropLeft 1 colors.red_300)
    , red_400 = hex (String.dropLeft 1 colors.red_400)
    , red_500 = hex (String.dropLeft 1 colors.red_500)
    , red_600 = hex (String.dropLeft 1 colors.red_600)
    , red_700 = hex (String.dropLeft 1 colors.red_700)
    , red_800 = hex (String.dropLeft 1 colors.red_800)
    , red_900 = hex (String.dropLeft 1 colors.red_900)
    , white_50 = hex (String.dropLeft 1 colors.white_50)
    , white_400 = hex (String.dropLeft 1 colors.white_400)
    , white_700 = hex (String.dropLeft 1 colors.white_700)
    , black_300 = hex (String.dropLeft 1 colors.black_300)
    , black_400 = hex (String.dropLeft 1 colors.black_400)
    , black_450 = hex (String.dropLeft 1 colors.black_450)
    , black_470 = hex (String.dropLeft 1 colors.black_470)
    , black_490 = hex (String.dropLeft 1 colors.black_490)
    , black_500 = hex (String.dropLeft 1 colors.black_500)
    }


locale =
    { usLocale
        | decimals = Exact 2
    }


{-| The gaps used on the webpage
-}
spacing =
    { xs_3 = "2px"
    , xs_2 = "4px"
    , xs = "8px"
    , s = "12px"
    , m = "16px"
    , l = "20px"
    , xl = "24px"
    , xl_2 = "32px"
    , xl_3 = "40px"
    , xl_4 = "48px"
    , xl_5 = "64px"
    , xl_6 = "80px"
    , xl_7 = "96px"
    , xl_8 = "128px"
    }


{-| The gaps transformed into values that elm-css can use. This assumes all gaps are rem values
-}
cssSpacing =
    { xs_3 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xs_3)))
    , xs_2 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xs_2)))
    , xs = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xs)))
    , s = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.s)))
    , m = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.m)))
    , l = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.l)))
    , xl = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl)))
    , xl_2 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_2)))
    , xl_3 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_3)))
    , xl_4 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_4)))
    , xl_5 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_5)))
    , xl_6 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_6)))
    , xl_7 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_7)))
    , xl_8 = px (Maybe.withDefault 0.0 (String.toFloat (String.dropRight 2 spacing.xl_8)))
    }


parkinsans =
    "Parkinsans"


ibm =
    "IBM Plex Mono"


{-| The fonts used on the website for each type of text
-}
fontFamilies =
    { display = parkinsans
    , headline = parkinsans
    , title = parkinsans
    , body = parkinsans
    , label = ibm
    }


{-| The font sizes to use in the application
-}
fontSizes =
    { display_large = "57pt"
    , display_medium = "45pt"
    , display_small = "36pt"
    , headline_large = "32pt"
    , headline_medium = "28pt"
    , headline_small = "24pt"
    , title_large = "22pt"
    , title_medium = "16pt"
    , title_small = "14pt"
    , body_large = "16pt"
    , body_medium = "14pt"
    , body_small = "12pt"
    , label_extraLarge = "16pt"
    , label_large = "14pt"
    , label_medium = "12pt"
    , label_small = "11pt"
    }
