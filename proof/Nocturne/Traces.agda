{-# OPTIONS --safe --without-K #-}
module Nocturne.Traces where

open import Nocturne.Model
open import Nocturne.Properties using (ownership-preserved; stage₁-cannot-bypass)
open import Data.Bool.Base using (Bool; false)
open import Data.List.Base using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; trans)

execute : List Operation → Policy → Policy
execute [] state = state
execute (op ∷ ops) state = execute ops (step op state)

trace-ownership : ∀ ops state → owner (execute ops state) ≡ owner state
trace-ownership [] state = refl
trace-ownership (op ∷ ops) state =
  trans (trace-ownership ops (step op state)) (ownership-preserved op state)

owned-denied : ∀ state → owner state ≡ monitor → writable state ≡ false
owned-denied (policy monitor t c p) owned = refl
owned-denied (policy guest t c p) ()

trace-isolation : ∀ ops state → owner state ≡ monitor →
  writable (execute ops state) ≡ false
trace-isolation ops state owned =
  owned-denied (execute ops state) (trans (trace-ownership ops state) owned)

trace-write-unchanged : ∀ ops state s₁ value old → owner state ≡ monitor →
  contents (write s₁ value (cell (execute ops state) old)) ≡ old
trace-write-unchanged ops state s₁ value old owned =
  stage₁-cannot-bypass s₁ value old (execute ops state)
    (trace-isolation ops state owned)

execute-append : ∀ xs ys state → execute (xs Data.List.Base.++ ys) state ≡
  execute ys (execute xs state)
execute-append [] ys state = refl
execute-append (op ∷ ops) ys state = execute-append ops ys (step op state)
