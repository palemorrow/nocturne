{-# OPTIONS --safe --without-K #-}
module Nocturne.Permissions where

open import Nocturne.Model using (Domain; monitor; guest; Phase; stable; staged; ordered; invalidated; synchronized)
open import Data.Bool.Base using (Bool; true; false; _∨_; _∧_; T)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data Mode : Set where
  none read-only read-write read-execute : Mode

data Access : Set where
  read-access write-access execute-access : Access

allows : Mode → Access → Bool
allows none access = false
allows read-only read-access = true
allows read-only write-access = false
allows read-only execute-access = false
allows read-write read-access = true
allows read-write write-access = true
allows read-write execute-access = false
allows read-execute read-access = true
allows read-execute write-access = false
allows read-execute execute-access = true

Allowed : Mode → Access → Set
Allowed mode access = T (allows mode access)

record Translation : Set where
  constructor translation
  field
    owner : Domain
    table cache : Mode
    phase : Phase
open Translation public

effective : Translation → Access → Bool
effective (translation monitor t c p) access = false
effective (translation guest t c p) access = allows t access ∨ allows c access

begin-revoke : Translation → Translation
begin-revoke (translation d t c p) = translation d none c staged

order-tables : Translation → Translation
order-tables (translation d t c staged) = translation d t c ordered
order-tables state = state

invalidate-cache : Translation → Translation
invalidate-cache (translation d t c ordered) = translation d t c invalidated
invalidate-cache state = state

complete : Translation → Translation
complete (translation d t c invalidated) = translation d t none synchronized
complete state = state

revoke-all : Translation → Translation
revoke-all state = complete (invalidate-cache (order-tables (begin-revoke state)))

no-writable-executable-mode : ∀ mode →
  allows mode write-access ∧ allows mode execute-access ≡ false
no-writable-executable-mode none = refl
no-writable-executable-mode read-only = refl
no-writable-executable-mode read-write = refl
no-writable-executable-mode read-execute = refl

private-access-denied : ∀ t c phase access →
  effective (translation monitor t c phase) access ≡ false
private-access-denied t c phase access = refl

revocation-result : ∀ d t c phase →
  revoke-all (translation d t c phase) ≡ translation d none none synchronized
revocation-result d t c phase = refl

revocation-denies-all : ∀ state access → effective (revoke-all state) access ≡ false
revocation-denies-all (translation monitor t c phase) access = refl
revocation-denies-all (translation guest t c phase) access = refl

cache-persists-until-completion : ∀ t c phase access →
  effective (invalidate-cache (order-tables (begin-revoke (translation guest t c phase)))) access ≡
  allows c access
cache-persists-until-completion t c phase access = refl

premature-completion : ∀ d t c →
  complete (begin-revoke (translation d t c stable)) ≡ translation d none c staged
premature-completion d t c = refl

premature-invalidation : ∀ d t c →
  invalidate-cache (begin-revoke (translation d t c stable)) ≡ translation d none c staged
premature-invalidation d t c = refl

cache-empty-after-completion : ∀ d t c phase →
  cache (revoke-all (translation d t c phase)) ≡ none
cache-empty-after-completion d t c phase = refl

ownership-after-revocation : ∀ state → owner (revoke-all state) ≡ owner state
ownership-after-revocation (translation d t c phase) = refl
