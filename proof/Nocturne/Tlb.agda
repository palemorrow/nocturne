{-# OPTIONS --safe --without-K #-}
module Nocturne.Tlb where

open import Nocturne.Permissions using (Mode)
open import Data.Empty using (⊥-elim)
open import Data.Maybe.Base using (Maybe; nothing)
open import Data.Nat.Base using (ℕ)
open import Data.Nat.Properties using (_≟_)
open import Relation.Binary.PropositionalEquality using (_≡_; _≢_; refl; trans; sym)
open import Relation.Nullary.Decidable.Core using (yes; no)

Cache : Set
Cache = ℕ → Maybe Mode

invalidate-page : Cache → ℕ → Cache
invalidate-page cache page query with page ≟ query
... | yes equal = nothing
... | no unequal = cache query

selected-invalidated : ∀ cache page → invalidate-page cache page page ≡ nothing
selected-invalidated cache page with page ≟ page
... | yes equal = refl
... | no unequal = ⊥-elim (unequal refl)

neighbor-preserved : ∀ cache page query → page ≢ query →
  invalidate-page cache page query ≡ cache query
neighbor-preserved cache page query unequal with page ≟ query
... | yes equal = ⊥-elim (unequal equal)
... | no other = refl

invalidation-idempotent : ∀ cache page query →
  invalidate-page (invalidate-page cache page) page query ≡ invalidate-page cache page query
invalidation-idempotent cache page query with page ≟ query
... | yes equal = refl
... | no unequal = neighbor-preserved cache page query unequal

invalidations-commute : ∀ cache first second query →
  invalidate-page (invalidate-page cache first) second query ≡
  invalidate-page (invalidate-page cache second) first query
invalidations-commute cache first second query with first ≟ query | second ≟ query
... | yes refl | yes refl = refl
... | yes refl | no unequal = selected-invalidated cache query
... | no unequal | yes refl = sym (selected-invalidated cache query)
... | no unequal | no other = trans (neighbor-preserved cache first query unequal)
  (sym (neighbor-preserved cache second query other))
