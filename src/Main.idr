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
import TyTTP.HTTP.Routing
import TyTTP.URL
import TyTTP.URL.Path
import TyTTP.URL.Search

sendError :
  Error e
  => HasIO io
  => Status
  -> String
  -> Context me u h1 s StringHeaders a b
  -> io $ Context me u h1 Status StringHeaders a (Publisher IO e Buffer)
sendError st str ctx = do
  text str ctx >>= status st

%language ElabReflection

record Example where
  constructor MkExample
  field : String
  opt : Maybe Int

%runElab derive "Example" [Generic, Meta, Show, Eq, RecordFromJSON]

hReturnExample : Error e
  => HasIO m
  => Context me u h1 s StringHeaders Example ()
  -> m $ Context me u h1 Status StringHeaders Example (Publisher IO e Buffer)
hReturnExample ctx = do
  let payload = show ctx.request.body
  text payload ctx >>= status OK

hRouting : Error e
  => Context Method String StringHeaders Status StringHeaders (Publisher IO e Buffer) ()
  -> Promise e IO $ Context Method String StringHeaders Status StringHeaders (Publisher IO e Buffer) (Publisher IO e Buffer)
hRouting =
  let routingError = sendError NOT_FOUND "Resource could not be found"
      parseUrlError = \err => sendError BAD_REQUEST "URL has invalid format"
      decodeUriError = sendError BAD_REQUEST "URI decode has failed"
      jsonParseError = \s => sendError BAD_REQUEST "Content cannot be parsed: \{s.request.body}" s
  in
    decodeUri' decodeUriError :> parseUrl' parseUrlError :> routes' routingError
        [ post $ path "/json" $ consumes' [JSON] jsonParseError :> hReturnExample
        ]

main : IO ()
main = eitherT putStrLn pure $ do
  http <- HTTP.require
  ignore $ HTTP.listen' $ hRouting

