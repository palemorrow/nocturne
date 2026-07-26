{-# OPTIONS --safe --without-K #-}
module Nocturne.Routing where

open import Nocturne.Model
open import Nocturne.Enumeration using (booleans; bool-code)
open import Data.Bool.Base using (Bool)
open import Data.List.Base using (List; []; _∷_; concatMap; map)
open import Data.Nat.Base using (ℕ)
open import Data.Nat.Show using (show)
open import Data.String.Base using (String; _++_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

exceptions : List Exception
exceptions = hvc ∷ svc ∷ stage₂-abort ∷ id-register ∷ physical-irq ∷ []

destination-code : Destination → ℕ
destination-code el₁ = 0
destination-code el₂ = 1
destination-code direct = 2
destination-code pending = 3

exception-code : Exception → ℕ
exception-code hvc = 0
exception-code svc = 1
exception-code stage₂-abort = 2
exception-code id-register = 3
exception-code physical-irq = 4

routing-row : Bool → Bool → Bool → Exception → String
routing-row irq trap mask event = "route " ++ show (bool-code irq) ++ " " ++
  show (bool-code trap) ++ " " ++ show (bool-code mask) ++ " " ++
  show (exception-code event) ++ " " ++ show (destination-code (route (controls irq trap) mask event))

routing-rows : List String
routing-rows = concatMap (λ irq → concatMap (λ trap → concatMap
  (λ mask → map (routing-row irq trap mask) exceptions) booleans) booleans) booleans

routing-count : Data.List.Base.length routing-rows ≡ 40
routing-count = refl
