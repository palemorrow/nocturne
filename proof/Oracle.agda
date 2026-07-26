{-# OPTIONS --without-K --guardedness #-}
module Oracle where

open import Nocturne.Enumeration using (rows)
open import Nocturne.Routing using (routing-rows)
open import Data.List.Base using (_++_)
open import IO
open import Data.Unit.Polymorphic using (⊤)

main : Main
main = run (List.mapM′ putStrLn (rows ++ routing-rows))
