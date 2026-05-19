{-# OPTIONS --safe --without-K #-}
module Nocturne.Model where

open import Data.Bool.Base using (Bool; true; false; _∧_; _∨_)
open import Data.Nat.Base using (ℕ)

data Domain : Set where
  monitor guest : Domain

data Phase : Set where
  stable staged ordered invalidated synchronized : Phase

data Operation : Set where
  grant revoke order invalidate synchronize reset : Operation

record Policy : Set where
  constructor policy
  field
    owner : Domain
    table cached : Bool
    phase : Phase
open Policy public

writable : Policy → Bool
writable (policy monitor t c p) = false
writable (policy guest t c p) = t ∨ c

step : Operation → Policy → Policy
step grant (policy guest t c stable) = policy guest true true stable
step grant (policy guest t c synchronized) = policy guest true true stable
step grant s = s
step revoke (policy d t c p) = policy d false c staged
step order (policy d t c staged) = policy d t c ordered
step order s = s
step invalidate (policy d t c ordered) = policy d t c invalidated
step invalidate s = s
step synchronize (policy d t c invalidated) = policy d t false synchronized
step synchronize s = s
step reset (policy d t c synchronized) = policy d t c stable
step reset s = s

revoke-completely : Policy → Policy
revoke-completely s = step synchronize (step invalidate (step order (step revoke s)))

record Cell : Set where
  constructor cell
  field
    access : Policy
    contents : ℕ
open Cell public

write : Bool → ℕ → Cell → Cell
write stage₁ value (cell p old) with stage₁ ∧ writable p
... | true = cell p value
... | false = cell p old

map-guest : Policy → Policy
map-guest = step grant

unmap-guest : Policy → Policy
unmap-guest = revoke-completely

handle-fault : Cell → Cell
handle-fault s = s

record Controls : Set where
  constructor controls
  field
    irq-to-el₂ trap-id : Bool
open Controls public

data Exception : Set where
  hvc svc stage₂-abort id-register physical-irq : Exception

data Destination : Set where
  el₁ el₂ direct pending : Destination

route : Controls → Bool → Exception → Destination
route c masked hvc = el₂
route c masked svc = el₁
route c masked stage₂-abort = el₂
route (controls i true) masked id-register = el₂
route (controls i false) masked id-register = direct
route (controls true t) masked physical-irq = el₂
route (controls false t) true physical-irq = pending
route (controls false t) false physical-irq = el₁
