/*
 * <vectors.S>
 *
 * Sparc V9 Trap Table(s) with SpitFire/Cheetah extensions.
 *
 *   Copyright (C) 1996, 2001 David S. Miller (davem@caip.rutgers.edu)
 *
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License
 *   version 2 as published by the Free Software Foundation.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with this program; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *   MA  02110-1301, USA.
 *   This program is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU General Public License V2
 *   as published by the Free Software Foundation
 */

#define __ASSEMBLY__
#include "cpustate.h"
#include "pstate.h"
#include <asm/asi.h>
#define ASI_BP ASI_PHYS_BYPASS_EC_E
#define PROM_ADDR 0x1fff0000000
#define SER_ADDR 0x1fe020003f8
#define TICK_INT_DIS 0x8000000000000000
#define TICK_INTERVAL 1*1000*1000

        .section ".text.vectors", "ax"
        .align 16384
/* Sparc64 trap table */
        .globl trap_table, __divide_error, softint_irq, softint_irq_tl1
        .register %g2, #scratch
        .register %g3, #scratch
        .register %g6, #scratch
        .register %g7, #scratch
trap_table:
#define SPILL_WINDOW                                    \
        btst    1, %sp;                                 \
        be      spill_32bit;                            \
         nop;                                           \
        stx     %l0, [%sp + STACK_BIAS + 0x00];         \
        stx     %l1, [%sp + STACK_BIAS + 0x08];         \
        stx     %l2, [%sp + STACK_BIAS + 0x10];         \
        stx     %l3, [%sp + STACK_BIAS + 0x18];         \
        stx     %l4, [%sp + STACK_BIAS + 0x20];         \
        stx     %l5, [%sp + STACK_BIAS + 0x28];         \
        stx     %l6, [%sp + STACK_BIAS + 0x30];         \
        stx     %l7, [%sp + STACK_BIAS + 0x38];         \
        stx     %i0, [%sp + STACK_BIAS + 0x40];         \
        stx     %i1, [%sp + STACK_BIAS + 0x48];         \
        stx     %i2, [%sp + STACK_BIAS + 0x50];         \
        stx     %i3, [%sp + STACK_BIAS + 0x58];         \
        stx     %i4, [%sp + STACK_BIAS + 0x60];         \
        stx     %i5, [%sp + STACK_BIAS + 0x68];         \
        stx     %i6, [%sp + STACK_BIAS + 0x70];         \
        stx     %i7, [%sp + STACK_BIAS + 0x78];         \
        saved; retry; nop; nop; nop; nop; nop; nop;     \
        nop; nop; nop; nop; nop;

#define FILL_WINDOW                                     \
        btst    1, %sp;                                 \
        be      fill_32bit;                             \
         nop;                                           \
        ldx     [%sp + STACK_BIAS + 0x00], %l0;         \
        ldx     [%sp + STACK_BIAS + 0x08], %l1;         \
        ldx     [%sp + STACK_BIAS + 0x10], %l2;         \
        ldx     [%sp + STACK_BIAS + 0x18], %l3;         \
        ldx     [%sp + STACK_BIAS + 0x20], %l4;         \
        ldx     [%sp + STACK_BIAS + 0x28], %l5;         \
        ldx     [%sp + STACK_BIAS + 0x30], %l6;         \
        ldx     [%sp + STACK_BIAS + 0x38], %l7;         \
        ldx     [%sp + STACK_BIAS + 0x40], %i0;         \
        ldx     [%sp + STACK_BIAS + 0x48], %i1;         \
        ldx     [%sp + STACK_BIAS + 0x50], %i2;         \
        ldx     [%sp + STACK_BIAS + 0x58], %i3;         \
        ldx     [%sp + STACK_BIAS + 0x60], %i4;         \
        ldx     [%sp + STACK_BIAS + 0x68], %i5;         \
        ldx     [%sp + STACK_BIAS + 0x70], %i6;         \
        ldx     [%sp + STACK_BIAS + 0x78], %i7;         \
        restored; retry; nop; nop; nop; nop; nop; nop;  \
        nop; nop; nop; nop; nop;

#define CLEAN_WINDOW                                                    \
        rdpr    %cleanwin, %l0;         add     %l0, 1, %l0;            \
        wrpr    %l0, 0x0, %cleanwin;                                    \
        clr     %o0;    clr     %o1;    clr     %o2;    clr     %o3;    \
        clr     %o4;    clr     %o5;    clr     %o6;    clr     %o7;    \
        clr     %l0;    clr     %l1;    clr     %l2;    clr     %l3;    \
        clr     %l4;    clr     %l5;    clr     %l6;    clr     %l7;    \
        retry;                                                          \
        nop;nop;nop;nop;nop;nop;nop;nop;nop;nop;nop;nop;

#define TRAP_IRQ(routine, level)                        \
                ba routine;  mov level, %g1; nop; nop; nop; nop; nop; nop;
#define BTRAP(lvl)                                      \
                 ba bug; mov lvl, %g1; nop; nop; nop; nop; nop; nop;
#define BTRAPTL1(lvl) BTRAP(lvl)
#define BTRAPS(x) BTRAP(x) BTRAP(x+1) BTRAP(x+2) BTRAP(x+3) BTRAP(x+4) BTRAP(x+5) BTRAP(x+6) BTRAP(x+7)
#define BTRAPS4(x) BTRAP(x) BTRAP(x+1) BTRAP(x+2) BTRAP(x+3)
#define TRAP_HANDLER(routine) ba routine; nop; nop; nop; nop; nop; nop; nop;

#define STACK_BIAS		2047
	.globl	sparc64_ttable_tl0, sparc64_ttable_tl1
sparc64_ttable_tl0:
                ba entry; nop; nop; nop; nop; nop; nop; nop;! XXX remove
                ba entry; nop; nop; nop; nop; nop; nop; nop;! Power-on reset
                ba entry; nop; nop; nop; nop; nop; nop; nop;! Watchdog reset
                ba entry; nop; nop; nop; nop; nop; nop; nop;! External reset
                ba entry; nop; nop; nop; nop; nop; nop; nop;! Software reset
                ba entry; nop; nop; nop; nop; nop; nop; nop;! RED state
                BTRAP(0x06) BTRAP(0x07) BTRAPS(0x08)
		BTRAPS(0x10) BTRAPS(0x18)
		BTRAP(0x20) BTRAP(0x21) BTRAP(0x22) BTRAP(0x23)
		CLEAN_WINDOW ! 24-27
		BTRAPS(0x28)
		BTRAPS(0x30) BTRAPS(0x38)
		BTRAP(0x40) BTRAP(0x41) BTRAP(0x42) BTRAP(0x43)
tl0_irq4:	TRAP_IRQ(handler_irq, 4)
tl0_irq5:	TRAP_IRQ(handler_irq, 5)  TRAP_IRQ(handler_irq, 6)
tl0_irq7:	TRAP_IRQ(handler_irq, 7)  TRAP_IRQ(handler_irq, 8)
tl0_irq9:	TRAP_IRQ(handler_irq, 9)  TRAP_IRQ(handler_irq, 10)
tl0_irq11:	TRAP_IRQ(handler_irq, 11) TRAP_IRQ(handler_irq, 12)
tl0_irq13:	TRAP_IRQ(handler_irq, 13)
tl0_irq14:	TRAP_IRQ(softint_irq, 14)
tl0_irq15:	TRAP_IRQ(handler_irq, 15)
		BTRAPS(0x50) BTRAPS(0x58)
		BTRAPS4(0x60)
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x64 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x65 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x66 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x67 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x68 : data_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x69 : data_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x6A : data_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x6B : data_access_MMU_miss
		BTRAPS4(0x6C)    ! data_access_protection
		BTRAPS(0x70) BTRAPS(0x78)
tl0_s0n:        SPILL_WINDOW
tl0_s1n:        SPILL_WINDOW
tl0_s2n:        SPILL_WINDOW
tl0_s3n:        SPILL_WINDOW
tl0_s4n:        SPILL_WINDOW
tl0_s5n:        SPILL_WINDOW
tl0_s6n:        SPILL_WINDOW
tl0_s7n:        SPILL_WINDOW
tl0_s0o:        SPILL_WINDOW
tl0_s1o:        SPILL_WINDOW
tl0_s2o:        SPILL_WINDOW
tl0_s3o:        SPILL_WINDOW
tl0_s4o:        SPILL_WINDOW
tl0_s5o:        SPILL_WINDOW
tl0_s6o:        SPILL_WINDOW
tl0_s7o:        SPILL_WINDOW
tl0_f0n:        FILL_WINDOW
tl0_f1n:        FILL_WINDOW
tl0_f2n:        FILL_WINDOW
tl0_f3n:        FILL_WINDOW
tl0_f4n:        FILL_WINDOW
tl0_f5n:        FILL_WINDOW
tl0_f6n:        FILL_WINDOW
tl0_f7n:        FILL_WINDOW
tl0_f0o:        FILL_WINDOW
tl0_f1o:        FILL_WINDOW
tl0_f2o:        FILL_WINDOW
tl0_f3o:        FILL_WINDOW
tl0_f4o:        FILL_WINDOW
tl0_f5o:        FILL_WINDOW
tl0_f6o:        FILL_WINDOW
tl0_f7o:        FILL_WINDOW
tl0_resv100:	BTRAPS(0x100) BTRAPS(0x108)
tl0_resv110:	BTRAPS(0x110) BTRAPS(0x118)
tl0_resv120:	BTRAPS(0x120) BTRAPS(0x128)
tl0_resv130:	BTRAPS(0x130) BTRAPS(0x138)
tl0_resv140:	BTRAPS(0x140) BTRAPS(0x148)
tl0_resv150:	BTRAPS(0x150) BTRAPS(0x158)
tl0_resv160:	BTRAPS(0x160) BTRAPS(0x168)
tl0_resv170:	BTRAPS(0x170) BTRAPS(0x178)
tl0_resv180:	BTRAPS(0x180) BTRAPS(0x188)
tl0_resv190:	BTRAPS(0x190) BTRAPS(0x198)
tl0_resv1a0:	BTRAPS(0x1a0) BTRAPS(0x1a8)
tl0_resv1b0:	BTRAPS(0x1b0) BTRAPS(0x1b8)
tl0_resv1c0:	BTRAPS(0x1c0) BTRAPS(0x1c8)
tl0_resv1d0:	BTRAPS(0x1d0) BTRAPS(0x1d8)
tl0_resv1e0:	BTRAPS(0x1e0) BTRAPS(0x1e8)
tl0_resv1f0:	BTRAPS(0x1f0) BTRAPS(0x1f8)

#undef BTRAPS
#define BTRAPS(x) BTRAPTL1(x) BTRAPTL1(x+1) BTRAPTL1(x+2) BTRAPTL1(x+3) BTRAPTL1(x+4) BTRAPTL1(x+5) BTRAPTL1(x+6) BTRAPTL1(x+7)

#define SKIP_IRQ(routine, level) \
                retry;  nop; nop; nop; nop; nop; nop; nop;

sparc64_ttable_tl1:
		BTRAPS(0x00) BTRAPS(0x08)
		BTRAPS(0x10) BTRAPS(0x18)
		BTRAPTL1(0x20) BTRAPTL1(0x21) BTRAPTL1(0x22) BTRAPTL1(0x23)
		CLEAN_WINDOW ! 24-27
		BTRAPS(0x28)
		BTRAPS(0x30) BTRAPS(0x38)
		BTRAPTL1(0x40) BTRAPTL1(0x41) BTRAPTL1(0x42) BTRAPTL1(0x43)
tl1_irq4:	TRAP_IRQ(handler_irq, 4)
tl1_irq5:	TRAP_IRQ(handler_irq, 5)  TRAP_IRQ(handler_irq, 6)
tl1_irq7:	TRAP_IRQ(handler_irq, 7)  TRAP_IRQ(handler_irq, 8)
tl1_irq9:	TRAP_IRQ(handler_irq, 9)  TRAP_IRQ(handler_irq, 10)
tl1_irq11:	TRAP_IRQ(handler_irq, 11) TRAP_IRQ(handler_irq, 12)
tl1_irq13:	TRAP_IRQ(handler_irq, 13)
tl1_irq14:	SKIP_IRQ(softint_irq, 14)
tl1_irq15:	TRAP_IRQ(handler_irq, 15)
		BTRAPS(0x50) BTRAPS(0x58)
		BTRAPS4(0x60)
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x64 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x65 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x66 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_IMMU_tlb)    ! 0x67 : instruction_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x68 : data_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x69 : data_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x6A : data_access_MMU_miss
		TRAP_HANDLER(reload_DMMU_tlb)    ! 0x6B : data_access_MMU_miss
		BTRAPS4(0x6C)    ! data_access_protection
		BTRAPS(0x70) BTRAPS(0x78)
tl1_s0n:        SPILL_WINDOW
tl1_s1n:        SPILL_WINDOW
tl1_s2n:        SPILL_WINDOW
tl1_s3n:        SPILL_WINDOW
tl1_s4n:        SPILL_WINDOW
tl1_s5n:        SPILL_WINDOW
tl1_s6n:        SPILL_WINDOW
tl1_s7n:        SPILL_WINDOW
tl1_s0o:        SPILL_WINDOW
tl1_s1o:        SPILL_WINDOW
tl1_s2o:        SPILL_WINDOW
tl1_s3o:        SPILL_WINDOW
tl1_s4o:        SPILL_WINDOW
tl1_s5o:        SPILL_WINDOW
tl1_s6o:        SPILL_WINDOW
tl1_s7o:        SPILL_WINDOW
tl1_f0n:        FILL_WINDOW
tl1_f1n:        FILL_WINDOW
tl1_f2n:        FILL_WINDOW
tl1_f3n:        FILL_WINDOW
tl1_f4n:        FILL_WINDOW
tl1_f5n:        FILL_WINDOW
tl1_f6n:        FILL_WINDOW
tl1_f7n:        FILL_WINDOW
tl1_f0o:        FILL_WINDOW
tl1_f1o:        FILL_WINDOW
tl1_f2o:        FILL_WINDOW
tl1_f3o:        FILL_WINDOW
tl1_f4o:        FILL_WINDOW
tl1_f5o:        FILL_WINDOW
tl1_f6o:        FILL_WINDOW
tl1_f7o:        FILL_WINDOW
tl1_resv100:	BTRAPS(0x100) BTRAPS(0x108)
tl1_resv110:	BTRAPS(0x110) BTRAPS(0x118)
tl1_resv120:	BTRAPS(0x120) BTRAPS(0x128)
tl1_resv130:	BTRAPS(0x130) BTRAPS(0x138)
tl1_resv140:	BTRAPS(0x140) BTRAPS(0x148)
tl1_resv150:	BTRAPS(0x150) BTRAPS(0x158)
tl1_resv160:	BTRAPS(0x160) BTRAPS(0x168)
tl1_resv170:	BTRAPS(0x170) BTRAPS(0x178)
tl1_resv180:	BTRAPS(0x180) BTRAPS(0x188)
tl1_resv190:	BTRAPS(0x190) BTRAPS(0x198)
tl1_resv1a0:	BTRAPS(0x1a0) BTRAPS(0x1a8)
tl1_resv1b0:	BTRAPS(0x1b0) BTRAPS(0x1b8)
tl1_resv1c0:	BTRAPS(0x1c0) BTRAPS(0x1c8)
tl1_resv1d0:	BTRAPS(0x1d0) BTRAPS(0x1d8)
tl1_resv1e0:	BTRAPS(0x1e0) BTRAPS(0x1e8)
tl1_resv1f0:	BTRAPS(0x1f0) BTRAPS(0x1f8)

	.section ".data"
	.align 8
	.globl obp_ticks_pointer


	! Pointer to current tick value
obp_ticks_pointer:
	.xword 0

        .section ".text", "ax"

spill_32bit:
        srl     %sp, 0, %sp
        stw     %l0, [%sp + 0x00]
        stw     %l1, [%sp + 0x04]
        stw     %l2, [%sp + 0x08]
        stw     %l3, [%sp + 0x0c]
        stw     %l4, [%sp + 0x10]
        stw     %l5, [%sp + 0x14]
        stw     %l6, [%sp + 0x18]
        stw     %l7, [%sp + 0x1c]
        stw     %i0, [%sp + 0x20]
        stw     %i1, [%sp + 0x24]
        stw     %i2, [%sp + 0x28]
        stw     %i3, [%sp + 0x2c]
        stw     %i4, [%sp + 0x30]
        stw     %i5, [%sp + 0x34]
        stw     %i6, [%sp + 0x38]
        stw     %i7, [%sp + 0x3c]
        saved
        retry

fill_32bit:
        srl     %sp, 0, %sp
        lduw    [%sp + 0x00], %l0
        lduw    [%sp + 0x04], %l1
        lduw    [%sp + 0x08], %l2
        lduw    [%sp + 0x0c], %l3
        lduw    [%sp + 0x10], %l4
        lduw    [%sp + 0x14], %l5
        lduw    [%sp + 0x18], %l6
        lduw    [%sp + 0x1c], %l7
        lduw    [%sp + 0x20], %i0
        lduw    [%sp + 0x24], %i1
        lduw    [%sp + 0x28], %i2
        lduw    [%sp + 0x2c], %i3
        lduw    [%sp + 0x30], %i4
        lduw    [%sp + 0x34], %i5
        lduw    [%sp + 0x38], %i6
        lduw    [%sp + 0x3c], %i7
        restored
        retry


        .globl reload_DMMU_tlb, reload_IMMU_tlb, bug

reload_DMMU_tlb:
	
	/* Save CPU state to stack */
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g1
	add	%g1, -CONTEXT_STATE_SIZE, %g1
	stx	%g1, [%g7]
	
	SAVE_CPU_STATE(dtlb)
	
	RESET_CPU_WINDOW_STATE(dtlb)
	
	/* Switch to 8K TLB locked OpenBIOS stack (note we add an additional 192 bytes required for
	   gcc to save its arguments when building with -O0) */
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g6
	setx	CONTEXT_STACK_SIZE, %g4, %g5
	sub	%g6, %g5, %g6
	stx	%g6, [%g7]
	
	setx	- 2047 - 192, %g6, %g7
	add	%g1, %g7, %g7
	mov	%g7, %sp

	/* Enable interrupts for window spill/fill traps */
	rdpr	%pstate, %g7
	or	%g7, PSTATE_IE, %g7
	wrpr	%g7, %pstate	

	call	dtlb_miss_handler
	 nop

	/* Disable interrupts */
	rdpr	%pstate, %g7
	andn	%g7, PSTATE_IE, %g7
	wrpr	%g7, %pstate
	
	/* Restore CPU state from stack */
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g1
	setx	CONTEXT_STACK_SIZE, %g4, %g5
	add	%g1, %g5, %g1
	stx	%g1, [%g7]
	
	RESTORE_CPU_STATE(dtlb)
	
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g1
	add	%g1, CONTEXT_STATE_SIZE, %g1
	stx	%g1, [%g7]
	
        retry

reload_IMMU_tlb:
	
	/* Save CPU state to stack */
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g1
	add	%g1, -CONTEXT_STATE_SIZE, %g1
	stx	%g1, [%g7]
	
	SAVE_CPU_STATE(itlb)
	
	RESET_CPU_WINDOW_STATE(itlb)
	
	/* Switch to 8K TLB locked OpenBIOS stack (note we add an additional 192 bytes required for
	   gcc to save its arguments when building with -O0) */
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g6
	setx	CONTEXT_STACK_SIZE, %g4, %g5
	sub	%g6, %g5, %g6
	stx	%g6, [%g7]
	
	setx	- 2047 - 192, %g6, %g7
	add	%g1, %g7, %g7
	mov	%g7, %sp

	/* Enable interrupts for window spill/fill traps */
	rdpr	%pstate, %g7
	or	%g7, PSTATE_IE, %g7
	wrpr	%g7, %pstate	

	call	itlb_miss_handler
	 nop

	/* Disable interrupts */
	rdpr	%pstate, %g7
	andn	%g7, PSTATE_IE, %g7
	wrpr	%g7, %pstate
	
	/* Restore CPU state from stack */
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g1
	setx	CONTEXT_STACK_SIZE, %g4, %g5
	add	%g1, %g5, %g1
	stx	%g1, [%g7]
	
	RESTORE_CPU_STATE(itlb)
	
	setx	_fcstack_ptr, %g6, %g7
	ldx	[%g7], %g1
	add	%g1, CONTEXT_STATE_SIZE, %g1
	stx	%g1, [%g7]

        retry

softint_irq_tl1:
softint_irq:
        mov     1, %g2
        /* clear tick interrupt */
        wr      %g2, 0x0, %clear_softint
        sll     %g2, %g1, %g2
        sra     %g2, 0, %g2
        /* clear softint interrupt */
        wr      %g2, 0x0, %clear_softint

        setx    TICK_INT_DIS, %g2, %g1
        rd      %tick, %g2
        and     %g1, %g2, %g1
        brnz,pn %g1, tick_compare_disabled
         nop

        /* update tick value if pointer set */
        setx    obp_ticks_pointer, %g3, %g1
        ldx     [%g1], %g3
        brz     %g3, tick_rearm
         nop

        ldx     [%g3], %g1
        add     %g1, 10, %g1    ! 100Hz = 10ms
        stx     %g1, [%g3]
         
tick_rearm:         
        set     TICK_INTERVAL, %g1
        add     %g1, %g2, %g1
        wr      %g1, 0, %tick_cmpr
tick_compare_disabled:
        retry

handler_irq:
__divide_error:
bug:
        /* Dump the exception and its context */
        ! Set up CPU state
        ! Don't change the global register set or we lose %g1 (exception level)
        rdpr    %pstate, %g2
        or      %g2, PSTATE_PRIV, %g2
        wrpr    %g2, %pstate
        wr      %g0, 0, %fprs

        ! Jump to ROM ...
        setx    _start, %g2, %g3
        setx    highmem, %g2, %g4
        sub     %g4, %g3, %g4
        setx    PROM_ADDR, %g2, %g3
        add     %g4, %g3, %g3
        jmp     %g3
        ! ... while disabling I/D MMUs and caches
         stxa    %g0, [%g0] ASI_LSU_CONTROL

highmem:
        ! Extract NWINDOWS from %ver
        rdpr    %ver, %g2
        and     %g2, 0xf, %g2
        wrpr    %g2, 0, %cleanwin
        wrpr    %g2, 0, %cansave
        wrpr    %g0, 0, %canrestore
        wrpr    %g0, 0, %otherwin
        wrpr    %g0, 0, %wstate

        b       dump_exception
         nop

outstr:
        /* void outstr (unsigned long port, const unsigned char *str);
         * Writes a string on an IO port.
         */
1:      ldub    [%o1], %o3
        cmp     %o3, 0
        be      2f
         nop
        stba    %o3, [%o0] ASI_BP
        b       1b
         inc    %o1
2:      retl
         nop

outdigit:
        /* void outdigit (unsigned long port, uint8_t digit);
         * Dumps a single digit on serial port.
         */
        add     %o1, '0', %o1
        retl
         stba   %o1, [%o0] ASI_BP

outhex:
        /* void outhex (unsigned long port, uint64_t value);
         * Dumps a 64 bits hex number on serial port
         */
        mov     %o1, %o2
        set     60, %o3
        srlx    %o2, %o3, %o1
1:      and     %o1, 0xf, %o1
        cmp     %o1, 9
        bgt     2f
         nop
        b       3f
         add    %o1, '0', %o1
2:      add     %o1, 'a' - 10, %o1
3:      stba    %o1, [%o0] ASI_BP
        subcc   %o3, 4, %o3
        bge     1b
         srlx   %o2, %o3, %o1
        retl
         nop

        /* void dump_exception ();
         *
         * Dump a message when catching an exception
         */
dump_exception:
        setx    SER_ADDR, %o3, %o0
        set     _start, %g3
        set     (_BUG_message_0), %o1
        sub     %o1, %g3, %g4
        setx    PROM_ADDR, %g2, %g3
        add     %g4, %g3, %g3
        call    outstr
         mov    %g3, %o1

        call    outhex
         mov    %g1, %o1

        call    outstr
         add    %g3, (_BUG_message_1 -  _BUG_message_0), %o1

        call    outhex
         rdpr   %tpc, %o1

        call    outstr
         add    %g3, (_BUG_message_2 -  _BUG_message_0), %o1

        call    outhex
         rdpr   %tnpc, %o1

        call    outstr
         add    %g3, (_BUG_message_3 -  _BUG_message_0), %o1

_forever:
        /* Loop forever */
        b       _forever                                  ;
         nop

        .section .rodata
_BUG_message_0:
        .string "Unhandled Exception 0x"
_BUG_message_1:
        .string "\nPC = 0x"
_BUG_message_2:
        .string " NPC = 0x"
_BUG_message_3:
        .string "\nStopping execution\n"
