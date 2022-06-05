module TyTTP.HTTP.Producer.JSON

import Data.Buffer.Ext
import TyTTP
import TyTTP.HTTP

export
json :
  Applicative m
  => String
  -> Context me u v h1 s StringHeaders a b
  -> m $ Context me u v h1 s StringHeaders a (Publisher IO e Buffer)
json str ctx = do
  let stream : Publisher IO e Buffer = Stream.singleton $ fromString str
  pure $ { response.body := stream
         , response.headers :=
           [ ("Content-Type", "application/json")
           , ("Content-Length", show $ length str)
           ]
         } ctx
