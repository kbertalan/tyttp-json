module TyTTP.HTTP.Consumer.JSON

import Data.Buffer.Ext
import JSON
import Language.JSON as LJ
import TyTTP.HTTP.Consumer

%hide Language.JSON.Data.JSON

export
data JSON : Type where

export
implementation Accept JSON where
  contentType _ = [ "application/json" ]

export
implementation FromJSON a => Consumer a JSON where
  consumeRaw _ ct raw = 
    mapFst show $ decode $ show raw
