{-# OPTIONS --safe --without-K #-}
module Nocturne.Vmid where

open import Nocturne.Permissions using (Mode)
open import Data.Empty using (⊥-elim)
open import Data.Maybe.Base using (Maybe; nothing)
open import Data.Nat.Base using (ℕ)
open import Data.Nat.Properties using (_≟_)
open import Relation.Binary.PropositionalEquality using (_≡_; _≢_; refl)
open import Relation.Nullary.Decidable.Core using (yes; no)

record Context : Set where
  constructor context
  field
    root vmid : ℕ
open Context public

TaggedCache : Set
TaggedCache = ℕ → ℕ → Maybe Mode

lookup : TaggedCache → Context → ℕ → Maybe Mode
lookup cache state page = cache (vmid state) page

flush-vmid : TaggedCache → ℕ → TaggedCache
flush-vmid cache selected query page with selected ≟ query
... | yes equal = nothing
... | no unequal = cache query page

reuse : TaggedCache → Context → TaggedCache
reuse cache state = flush-vmid cache (vmid state)

root-change-keeps-old-cache : ∀ cache tag first second page →
  lookup cache (context first tag) page ≡ lookup cache (context second tag) page
root-change-keeps-old-cache cache tag first second page = refl

reused-vmid-empty : ∀ cache state page → lookup (reuse cache state) state page ≡ nothing
reused-vmid-empty cache (context root tag) page with tag ≟ tag
... | yes equal = refl
... | no unequal = ⊥-elim (unequal refl)

other-vmid-preserved : ∀ cache selected query page → selected ≢ query →
  flush-vmid cache selected query page ≡ cache query page
other-vmid-preserved cache selected query page unequal with selected ≟ query
... | yes equal = ⊥-elim (unequal equal)
... | no other = refl

switch-back-cannot-resurrect : ∀ cache tag first second page →
  lookup (reuse cache (context second tag)) (context first tag) page ≡ nothing
switch-back-cannot-resurrect cache tag first second page =
  reused-vmid-empty cache (context first tag) page
