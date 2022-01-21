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
  -> Step me u h1 s StringHeaders a b
  -> io $ Step me u h1 Status StringHeaders a (Publisher IO e Buffer)
sendError st str step = do
  text str step >>= status st

%language ElabReflection

record Example where
  constructor MkExample
  field : String
  opt : Maybe Int

%runElab derive "Example" [Generic, Meta, Show, Eq, RecordFromJSON]

hReturnExample : Error e
  => HasIO m
  => Step me u h1 s StringHeaders Example ()
  -> m $ Step me u h1 Status StringHeaders Example (Publisher IO e Buffer)
hReturnExample step = do
  let payload = show step.request.body
  text payload step >>= status OK

hRouting : Error e
  => Step Method String StringHeaders Status StringHeaders (Publisher IO e Buffer) ()
  -> Promise e IO $ Step Method String StringHeaders Status StringHeaders (Publisher IO e Buffer) (Publisher IO e Buffer)
hRouting =
  let routingError = sendError NOT_FOUND "Resource could not be found"
      urlError = \err => sendError BAD_REQUEST "URL has invalid format"
      uriError = sendError BAD_REQUEST "URI decode has failed"
      parseError = \s => sendError BAD_REQUEST "Content cannot be parsed: \{s.request.body}" s
  in
    uri' uriError :> url' urlError :> routes' routingError
        [ post $ pattern "/json" $ consumes' [JSON] parseError :> hReturnExample
        ]

main : IO ()
main = eitherT putStrLn pure $ do
  http <- HTTP.require
  ignore $ HTTP.listen' $ hRouting

