module Main

import Generics.Derive
import JSON
import TyTTP.Adapter.Node.HTTP
import TyTTP.Adapter.Node.URI
import TyTTP.HTTP
import TyTTP.HTTP.Consumer.JSON
import TyTTP.HTTP.Producer.JSON
import TyTTP.URL

%language ElabReflection

%hide JSON.Parser.JSON

record Example where
  constructor MkExample
  field : String
  opt : Maybe Int

%runElab derive "Example" [Generic, Meta, Show, Eq, RecordToJSON, RecordFromJSON]

main : IO ()
main = do
  http <- HTTP.require
  ignore $ HTTP.listen'
    $ (\next, ctx => mapFailure message (next ctx))
    $ parseUrl' (const $ sendText "URL has invalid format" >=> status BAD_REQUEST)
    :> routes' (sendText "Resource could not be found" >=> status NOT_FOUND) { m = Promise Error IO }
        [ post
            $ pattern "/json"
            $ consumes' [JSON]
                { a = Example }
                (\ctx => sendText "Content cannot be parsed: \{ctx.request.body}" ctx >>= status BAD_REQUEST)
            $ \ctx => sendJSON ctx.request.body ctx >>= status OK
        ]
