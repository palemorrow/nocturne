{-# OPTIONS --safe --without-K #-}
module Nocturne.Coverage where

open import Nocturne.Model
open import Nocturne.Enumeration
open import Data.Bool.Base using (Bool; true; false)
open import Data.List.Base using (List; []; _∷_; map; concatMap; length)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.List.Membership.Propositional.Properties using (∈-map⁺; ∈-concat⁺′)
open import Data.List.Relation.Unary.Any using (here; there)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

join-member : ∀ {A B : Set} (f : A → List B) {x xs y} →
  x ∈ xs → y ∈ f x → y ∈ concatMap f xs
join-member f member inner = ∈-concat⁺′ inner (∈-map⁺ f member)

domains-complete : ∀ d → d ∈ domains
domains-complete monitor = here refl
domains-complete guest = there (here refl)

booleans-complete : ∀ b → b ∈ booleans
booleans-complete false = here refl
booleans-complete true = there (here refl)

phases-complete : ∀ p → p ∈ phases
phases-complete stable = here refl
phases-complete staged = there (here refl)
phases-complete ordered = there (there (here refl))
phases-complete invalidated = there (there (there (here refl)))
phases-complete synchronized = there (there (there (there (here refl))))

policies-complete : ∀ s → s ∈ policies
policies-complete (policy d t c p) =
  join-member (λ d → concatMap (λ t → concatMap (λ c → map (policy d t c) phases) booleans) booleans)
    (domains-complete d)
    (join-member (λ t → concatMap (λ c → map (policy d t c) phases) booleans)
      (booleans-complete t)
      (join-member (λ c → map (policy d t c) phases) (booleans-complete c)
        (∈-map⁺ (policy d t c) (phases-complete p))))

operations-complete : ∀ op → op ∈ operations
operations-complete grant = here refl
operations-complete revoke = there (here refl)
operations-complete order = there (there (here refl))
operations-complete invalidate = there (there (there (here refl)))
operations-complete synchronize = there (there (there (there (here refl))))
operations-complete reset = there (there (there (there (there (here refl)))))

rows-complete : ∀ s op → row s op ∈ rows
rows-complete s op = join-member (λ s → map (row s) operations) (policies-complete s)
  (∈-map⁺ (row s) (operations-complete op))

policy-count : length policies ≡ 40
policy-count = refl

transition-count : length rows ≡ 240
transition-count = refl
