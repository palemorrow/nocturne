{-# OPTIONS --safe --without-K #-}
module Nocturne.Enumeration where

open import Nocturne.Model
open import Data.Bool.Base using (Bool; true; false)
open import Data.List.Base using (List; []; _∷_; concatMap; map)
open import Data.Nat.Base using (ℕ)
open import Data.Nat.Show using (show)
open import Data.String.Base using (String; _++_)

bool-code : Bool → ℕ
bool-code false = 0
bool-code true = 1

domain-code : Domain → ℕ
domain-code monitor = 0
domain-code guest = 1

phase-code : Phase → ℕ
phase-code stable = 0
phase-code staged = 1
phase-code ordered = 2
phase-code invalidated = 3
phase-code synchronized = 4

operation-code : Operation → ℕ
operation-code grant = 0
operation-code revoke = 1
operation-code order = 2
operation-code invalidate = 3
operation-code synchronize = 4
operation-code reset = 5

policies : List Policy
policies = concatMap (λ d → concatMap (λ t → concatMap (λ c →
  map (policy d t c) (stable ∷ staged ∷ ordered ∷ invalidated ∷ synchronized ∷ []))
  (false ∷ true ∷ [])) (false ∷ true ∷ [])) (monitor ∷ guest ∷ [])

operations : List Operation
operations = grant ∷ revoke ∷ order ∷ invalidate ∷ synchronize ∷ reset ∷ []

encode : Policy → String
encode (policy d t c p) = show (domain-code d) ++ " " ++ show (bool-code t) ++ " " ++
  show (bool-code c) ++ " " ++ show (phase-code p)

row : Policy → Operation → String
row s op = encode s ++ " " ++ show (operation-code op) ++ " " ++ encode (step op s) ++
  " " ++ show (bool-code (writable (step op s)))

rows : List String
rows = concatMap (λ s → map (row s) operations) policies
