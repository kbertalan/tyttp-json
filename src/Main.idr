module Main

import Data.Buffer
import Data.List.Quantifiers
import Control.Monad.Either
import Control.Monad.Maybe
import Generics.Derive
import JSON
import Node.HTTP.Server
import TyTTP.Adapter.Node.HTTP
import TyTTP.Adapter.Node.URI
import TyTTP.HTTP
import TyTTP.HTTP.Consumer
import TyTTP.HTTP.Consumer.JSON
import TyTTP.HTTP.Producer
import TyTTP.HTTP.Producer.JSON
import TyTTP.HTTP.Routing
import TyTTP.URL
import TyTTP.URL.Path
import TyTTP.URL.Search

%language ElabReflection

record Example where
  constructor MkExample
  field : String
  opt : Maybe Int

%runElab derive "Example" [Generic, Meta, Show, Eq, RecordToJSON, RecordFromJSON]

main : IO ()
main = do
  http <- HTTP.require
  ignore $ HTTP.listen'
    $ (\next, ctx => mapFailure Node.Error.message (next ctx))
    $ parseUrl' (const $ text "URL has invalid format" >=> status BAD_REQUEST)
    :> routes' (text "Resource could not be found" >=> status NOT_FOUND) { m = Promise NodeError IO }
        [ post
            $ path "/json"
            $ consumes' [JSON]
                { a = Example }
                (\ctx => text "Content cannot be parsed: \{ctx.request.body}" ctx >>= status BAD_REQUEST)
            $ \ctx => json ctx.request.body ctx >>= status OK
        ]
