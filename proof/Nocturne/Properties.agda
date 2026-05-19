{-# OPTIONS --safe --without-K #-}
module Nocturne.Properties where

open import Nocturne.Model
open import Data.Bool.Base using (Bool; true; false)
open import Data.Nat.Base using (ℕ)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

private-denied : ∀ t c p → writable (policy monitor t c p) ≡ false
private-denied t c p = refl

private-write-unchanged : ∀ s₁ value old t c p →
  contents (write s₁ value (cell (policy monitor t c p) old)) ≡ old
private-write-unchanged false value old t c p = refl
private-write-unchanged true value old t c p = refl

stage₁-cannot-bypass : ∀ s₁ value old p → writable p ≡ false →
  contents (write s₁ value (cell p old)) ≡ old
stage₁-cannot-bypass false value old p denied = refl
stage₁-cannot-bypass true value old p denied rewrite denied = refl

fault-preserves : ∀ s → contents (handle-fault s) ≡ contents s
fault-preserves s = refl

revocation-state : ∀ d t c p →
  revoke-completely (policy d t c p) ≡ policy d false false synchronized
revocation-state d t c p = refl

revocation-denies : ∀ s → writable (revoke-completely s) ≡ false
revocation-denies (policy monitor t c p) = refl
revocation-denies (policy guest t c p) = refl

revocation-write-unchanged : ∀ s₁ value old p →
  contents (write s₁ value (cell (revoke-completely p) old)) ≡ old
revocation-write-unchanged s₁ value old p =
  stage₁-cannot-bypass s₁ value old (revoke-completely p) (revocation-denies p)

stale-before-completion : ∀ t p →
  writable (step invalidate (step order (step revoke (policy guest t true p)) )) ≡ true
stale-before-completion t p = refl

ownership-preserved : ∀ op p → owner (step op p) ≡ owner p
ownership-preserved grant (policy monitor t c p) = refl
ownership-preserved grant (policy guest t c stable) = refl
ownership-preserved grant (policy guest t c staged) = refl
ownership-preserved grant (policy guest t c ordered) = refl
ownership-preserved grant (policy guest t c invalidated) = refl
ownership-preserved grant (policy guest t c synchronized) = refl
ownership-preserved revoke p = refl
ownership-preserved order (policy d t c stable) = refl
ownership-preserved order (policy d t c staged) = refl
ownership-preserved order (policy d t c ordered) = refl
ownership-preserved order (policy d t c invalidated) = refl
ownership-preserved order (policy d t c synchronized) = refl
ownership-preserved invalidate (policy d t c stable) = refl
ownership-preserved invalidate (policy d t c staged) = refl
ownership-preserved invalidate (policy d t c ordered) = refl
ownership-preserved invalidate (policy d t c invalidated) = refl
ownership-preserved invalidate (policy d t c synchronized) = refl
ownership-preserved synchronize (policy d t c stable) = refl
ownership-preserved synchronize (policy d t c staged) = refl
ownership-preserved synchronize (policy d t c ordered) = refl
ownership-preserved synchronize (policy d t c invalidated) = refl
ownership-preserved synchronize (policy d t c synchronized) = refl
ownership-preserved reset (policy d t c stable) = refl
ownership-preserved reset (policy d t c staged) = refl
ownership-preserved reset (policy d t c ordered) = refl
ownership-preserved reset (policy d t c invalidated) = refl
ownership-preserved reset (policy d t c synchronized) = refl

private-grant-denied : ∀ t c p →
  writable (map-guest (policy monitor t c p)) ≡ false
private-grant-denied t c p = refl

write-requires-ownership : ∀ p → writable p ≡ true → owner p ≡ guest
write-requires-ownership (policy guest t c p) allowed = refl
write-requires-ownership (policy monitor t c p) ()

masked-physical-irq : ∀ trap masked →
  route (controls true trap) masked physical-irq ≡ el₂
masked-physical-irq trap masked = refl

svc-stays-at-el₁ : ∀ control masked → route control masked svc ≡ el₁
svc-stays-at-el₁ control masked = refl

stage₂-abort-target : ∀ control masked → route control masked stage₂-abort ≡ el₂
stage₂-abort-target control masked = refl
