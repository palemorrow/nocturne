{-# OPTIONS --without-K --guardedness #-}
module Oracle where

open import Nocturne.Enumeration using (rows)
open import IO
open import Data.Unit.Polymorphic using (⊤)

main : Main
main = run (List.mapM′ putStrLn rows)
