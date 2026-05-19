                                   .-----------------------.
                                   |  n o c t u r n e      |
                                   '-----------------------'

              nocturne is a WIP  arm64 hypervisor that runs an el1 guest
              beneath a standalone el2 monitor to study exception routing and
              privileged memory access with an agda model of page ownership,
              writable translations and permission revocation

                                           mechanism

             the guest makes a page writable through stage 1 while el2 keeps its
             stage-2 mapping read-only. an attempted store faults at el2 where
             the monitor checks the syndrome and reads the backing bytes directly.
             replacing the guest pte or disabling stage 1 still leaves those bytes
             unchanged because neither operation changes the stage 2 permissions

                     guest va             guest ipa              machine pa
                         |                    |                      ^
                         v                    v                      |
                   +-----------+        +-----------+           +-----------+
                   | stage 1   |------->| stage 2   |---------->| backing   |
                   | guest rw  |        | el2 ro    |           | unchanged |
                   +-----------+        +-----+-----+           +-----------+
                                             |
                                       write denied
                                             |
                                             v
                                     el2 vector -> trace

             ten fixtures exercise hvc return addresses, el0 svc delivery at el1,
             write and execute denial, guest remapping, stage-1 disablement,
             private memory access, live revocation, id-register traps and a
             physical timer routed to el2 while the guest irq mask remains set.
             repaired stores retry their original pc while denied fixture accesses
             resume at an explicit continuation rather than a generic pc increment

                                         proof boundary

            the agda model proves that monitor  cells reject guest writes,
            stage 1 permissions can't bypass a denied stage 2 write and completed
            revocation removes cached write authority after ordering, invalidation,
            and synchronization. it deliberately retains stale authority before
            completion so editing a descriptor alone doesnt establish revocation