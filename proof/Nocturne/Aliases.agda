{-# OPTIONS --safe --without-K #-}
module Nocturne.Aliases where

open import Nocturne.Model using (Domain; monitor; guest)
open import Nocturne.Permissions
open import Data.Bool.Base using (Bool; true; false)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Fin.Base using (Fin)
import Data.Fin.Properties as Fin
open import Data.Maybe.Base using (Maybe; nothing; just)
open import Data.Nat.Base using (ℕ)
open import Data.Nat.Properties using (_≟_)
open import Data.Product.Base using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; _≢_; refl; cong; sym)
open import Relation.Nullary.Decidable.Core using (Dec; yes; no)

record Address : Set where
  constructor address
  field
    page : ℕ
    offset : Fin 4096
open Address public

address-equality : (a b : Address) → Dec (a ≡ b)
address-equality (address p o) (address q n) with p ≟ q | o Fin.≟ n
... | yes refl | yes refl = yes refl
... | no unequal | _ = no (λ equal → unequal (cong page equal))
... | yes equal | no unequal = no (λ equal → unequal (cong offset equal))

Stage₁ : Set
Stage₁ = ℕ → Maybe ℕ

Stage₂ : Set
Stage₂ = ℕ → Translation

Memory : Set
Memory = Address → ℕ

translate : Stage₁ → Bool → Address → Maybe Address
translate mappings false virtual = just virtual
translate mappings true (address virtual offset) with mappings virtual
... | nothing = nothing
... | just physical = just (address physical offset)

permitted : Stage₁ → Bool → Stage₂ → Address → Access → Bool
permitted s₁ enabled s₂ virtual access with translate s₁ enabled virtual
... | nothing = false
... | just physical = effective (s₂ (page physical)) access

replace : Address → ℕ → Memory → Memory
replace target value memory query with address-equality target query
... | yes equal = value
... | no unequal = memory query

replace-self : ∀ target value memory → replace target value memory target ≡ value
replace-self target value memory with address-equality target target
... | yes equal = refl
... | no unequal = ⊥-elim (unequal refl)

replace-other : ∀ target value memory query → target ≢ query →
  replace target value memory query ≡ memory query
replace-other target value memory query unequal with address-equality target query
... | yes equal = ⊥-elim (unequal equal)
... | no other = refl

store : Stage₁ → Bool → Stage₂ → Address → ℕ → Memory → Memory
store s₁ enabled s₂ virtual value memory with translate s₁ enabled virtual
... | nothing = memory
... | just physical with effective (s₂ (page physical)) write-access
...   | false = memory
...   | true = replace physical value memory

unmapped-store : ∀ s₁ enabled s₂ virtual value memory →
  translate s₁ enabled virtual ≡ nothing →
  ∀ query → store s₁ enabled s₂ virtual value memory query ≡ memory query
unmapped-store s₁ enabled s₂ virtual value memory absent query rewrite absent = refl

denied-store : ∀ s₁ enabled s₂ virtual physical value memory →
  translate s₁ enabled virtual ≡ just physical →
  effective (s₂ (page physical)) write-access ≡ false →
  ∀ query → store s₁ enabled s₂ virtual value memory query ≡ memory query
denied-store s₁ enabled s₂ virtual physical value memory translated denied query
  rewrite translated | denied = refl

private-denied : ∀ state access → owner state ≡ monitor → effective state access ≡ false
private-denied (translation monitor t c phase) access owned = refl
private-denied (translation guest t c phase) access ()

private-store : ∀ s₁ enabled s₂ virtual physical value memory →
  translate s₁ enabled virtual ≡ just physical →
  owner (s₂ (page physical)) ≡ monitor →
  ∀ query → store s₁ enabled s₂ virtual value memory query ≡ memory query
private-store s₁ enabled s₂ virtual physical value memory translated owned =
  denied-store s₁ enabled s₂ virtual physical value memory translated
    (private-denied (s₂ (page physical)) write-access owned)

alias-denial : ∀ s₁ enabled s₂ first second physical value memory →
  translate s₁ enabled first ≡ just physical →
  translate s₁ enabled second ≡ just physical →
  effective (s₂ (page physical)) write-access ≡ false →
  ∀ query →
    (store s₁ enabled s₂ first value memory query ≡ memory query) ×
    (store s₁ enabled s₂ second value memory query ≡ memory query)
alias-denial s₁ enabled s₂ first second physical value memory first-map second-map denied query =
  denied-store s₁ enabled s₂ first physical value memory first-map denied query ,
  denied-store s₁ enabled s₂ second physical value memory second-map denied query

remap : Stage₁ → ℕ → ℕ → Stage₁
remap mappings virtual physical query with virtual ≟ query
... | yes equal = just physical
... | no unequal = mappings query

remap-here : ∀ mappings virtual physical →
  remap mappings virtual physical virtual ≡ just physical
remap-here mappings virtual physical with virtual ≟ virtual
... | yes equal = refl
... | no unequal = ⊥-elim (unequal refl)

remap-other : ∀ mappings virtual physical query → virtual ≢ query →
  remap mappings virtual physical query ≡ mappings query
remap-other mappings virtual physical query unequal with virtual ≟ query
... | yes equal = ⊥-elim (unequal equal)
... | no other = refl

remap-translation : ∀ mappings virtual physical offset →
  translate (remap mappings virtual physical) true (address virtual offset) ≡
    just (address physical offset)
remap-translation mappings virtual physical offset
  rewrite remap-here mappings virtual physical = refl

remapping-cannot-bypass : ∀ mappings s₂ virtual physical offset value memory →
  effective (s₂ physical) write-access ≡ false →
  ∀ query → store (remap mappings virtual physical) true s₂
    (address virtual offset) value memory query ≡ memory query
remapping-cannot-bypass mappings s₂ virtual physical offset value memory denied =
  denied-store (remap mappings virtual physical) true s₂ (address virtual offset)
    (address physical offset) value memory
    (remap-translation mappings virtual physical offset) denied

disabling-cannot-bypass : ∀ mappings s₂ physical value memory →
  effective (s₂ (page physical)) write-access ≡ false →
  ∀ query → store mappings false s₂ physical value memory query ≡ memory query
disabling-cannot-bypass mappings s₂ physical value memory denied =
  denied-store mappings false s₂ physical physical value memory refl denied

just-injective : ∀ {A : Set} {a b : A} → just a ≡ just b → a ≡ b
just-injective refl = refl

nothing-not-just : ∀ {A : Set} {a : A} → nothing ≡ just a → ⊥
nothing-not-just ()

translation-preserves-offset : ∀ mappings enabled virtual physical →
  translate mappings enabled virtual ≡ just physical → offset physical ≡ offset virtual
translation-preserves-offset mappings false virtual .virtual refl = refl
translation-preserves-offset mappings true (address p o) physical equal with mappings p
... | nothing = ⊥-elim (nothing-not-just equal)
... | just q = cong offset (sym (just-injective equal))
