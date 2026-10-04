# ============================================================
# File:    racing_analyzer.asm
# Author:  Vatsal Sagar
# Course:  CIS126 - Computer Architecture & Organization
# Date:    April 2026
# Purpose: Racing Lap Time Analyzer - CIS126 Capstone Project
#          Analyzes lap times for 4 F1 drivers across 5 laps.
#          Computes totals, averages, fastest/slowest laps,
#          and ranks drivers by total race time using
#          selection sort.
# Run in:  MARS 4.5  (Assemble -> Run)
# ============================================================

.data
    # --------------------------------------------------------
    # Data Structure 1: Name pointer array
    #   nameAddrs[i] = address of driver i's name string
    # --------------------------------------------------------
    name0:      .asciiz "Hamilton"
    name1:      .asciiz "Verstappen"
    name2:      .asciiz "Leclerc"
    name3:      .asciiz "Norris"
    nameAddrs:  .word name0, name1, name2, name3

    # --------------------------------------------------------
    # Data Structure 2: 2D lap-time array (row-major)
    #   lapTimes[driver][lap]  (4 drivers x 5 laps)
    #   Values in tenths of seconds  (e.g. 845 = 84.5 sec)
    #   Address = lapTimes + (driver*5 + lap) * 4
    # --------------------------------------------------------
    lapTimes:   .word 845, 832, 829, 841, 836   # Hamilton
                .word 851, 848, 844, 853, 847   # Verstappen
                .word 838, 843, 835, 840, 831   # Leclerc
                .word 856, 849, 852, 858, 845   # Norris

    # --------------------------------------------------------
    # Computed result arrays (filled at runtime)
    # --------------------------------------------------------
    totalTimes: .word 0, 0, 0, 0    # total race time per driver
    avgTimes:   .word 0, 0, 0, 0    # avg lap time per driver
    rankOrder:  .word 0, 1, 2, 3    # driver indices sorted by total

    # --------------------------------------------------------
    # Fastest / Slowest tracking globals
    # --------------------------------------------------------
    fastestTime:   .word 9999
    fastestDriver: .word 0
    fastestLapNum: .word 0
    slowestTime:   .word 0
    slowestDriver: .word 0
    slowestLapNum: .word 0

    # --------------------------------------------------------
    # UI / output strings
    # --------------------------------------------------------
    banner:     .asciiz "========================================\n"
    title:      .asciiz "       RACING LAP TIME ANALYZER\n"
    subtitle:   .asciiz "    CIS126 Capstone - Vatsal Sagar\n"
    divider:    .asciiz "----------------------------------------\n"
    newline:    .asciiz "\n"
    str_rank:   .asciiz "Rank "
    str_col:    .asciiz ": "
    str_total:  .asciiz "   Total : "
    str_avg:    .asciiz "   Avg   : "
    str_laps:   .asciiz "   Laps  : "
    str_sec:    .asciiz " sec\n"
    str_dot:    .asciiz "."
    str_space:  .asciiz "  "
    str_fastest:.asciiz "FASTEST LAP:  "
    str_slowest:.asciiz "SLOWEST LAP:  "
    str_by:     .asciiz " by "
    str_lap:    .asciiz " (Lap "
    str_rparen: .asciiz ")\n"
    str_done:   .asciiz "\n===== Analysis Complete =====\n"

.text
.globl main

# ============================================================
# Procedure: main
# Purpose:   Program entry point. Calls all sub-procedures
#            in order to produce the full race analysis.
# Arguments: none
# Returns:   none  (terminates with syscall 10)
# Caller-saved used: $t0 (temp for syscall)
# Callee-saved saved: $ra
# Stack: -4 bytes  |  0($sp) = $ra
# ============================================================
main:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    # Print banner
    li   $v0, 4
    la   $a0, banner
    syscall
    la   $a0, title
    syscall
    la   $a0, subtitle
    syscall
    la   $a0, banner
    syscall

    jal  computeTotals       # Step 1: sum lap times
    jal  computeAverages     # Step 2: average lap times
    jal  findFastestLap      # Step 3: find best lap
    jal  findSlowestLap      # Step 4: find worst lap
    jal  sortDrivers         # Step 5: rank by total time
    jal  printReport         # Step 6: print ranked table
    jal  printHighlights     # Step 7: print fastest/slowest

    li   $v0, 4
    la   $a0, str_done
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    li   $v0, 10
    syscall


# ============================================================
# Procedure: computeTotals
# Purpose:   Nested loop over all drivers and laps. Sums each
#            driver's 5 lap times and stores in totalTimes[].
# Arguments: none
# Returns:   none  (writes to totalTimes[] in memory)
# Caller-saved used: $t0-$t4
# Callee-saved saved: $ra, $s0 (outer counter), $s1 (inner)
# Stack: -12 bytes  |  8($sp)=$ra  4($sp)=$s0  0($sp)=$s1
# ============================================================
computeTotals:
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    li   $s0, 0                     # driver index = 0

ct_outer:
    li   $t0, 4                     # NUM_DRIVERS = 4
    bge  $s0, $t0, ct_done

    li   $s1, 0                     # lap index = 0
    li   $t1, 0                     # running total = 0

ct_inner:
    li   $t0, 5                     # NUM_LAPS = 5
    bge  $s1, $t0, ct_store

    # byte offset = (driver*5 + lap) * 4
    li   $t2, 5
    mul  $t3, $s0, $t2              # t3 = driver * 5
    add  $t3, $t3, $s1              # t3 = driver*5 + lap
    sll  $t3, $t3, 2                # t3 = offset in bytes
    la   $t4, lapTimes
    add  $t4, $t4, $t3
    lw   $t4, 0($t4)                # load lapTimes[driver][lap]
    add  $t1, $t1, $t4              # accumulate into total

    addi $s1, $s1, 1
    j    ct_inner

ct_store:
    la   $t2, totalTimes
    sll  $t3, $s0, 2                # driver * 4
    add  $t2, $t2, $t3
    sw   $t1, 0($t2)                # totalTimes[driver] = total

    addi $s0, $s0, 1
    j    ct_outer

ct_done:
    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra


# ============================================================
# Procedure: computeAverages
# Purpose:   Divides each driver's totalTimes entry by
#            NUM_LAPS (5) to get avg lap time in tenths.
# Arguments: none
# Returns:   none  (writes to avgTimes[] in memory)
# Caller-saved used: $t0-$t5
# Callee-saved saved: $ra, $s0 (driver counter)
# Stack: -8 bytes  |  4($sp)=$ra  0($sp)=$s0
# ============================================================
computeAverages:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)

    li   $s0, 0                     # driver index

ca_loop:
    li   $t0, 4
    bge  $s0, $t0, ca_done

    sll  $t1, $s0, 2                # byte offset = driver * 4
    la   $t2, totalTimes
    add  $t2, $t2, $t1
    lw   $t3, 0($t2)                # load totalTimes[driver]

    li   $t4, 5                     # divide by NUM_LAPS
    div  $t3, $t4
    mflo $t5                        # quotient = average

    la   $t2, avgTimes
    add  $t2, $t2, $t1
    sw   $t5, 0($t2)                # avgTimes[driver] = average

    addi $s0, $s0, 1
    j    ca_loop

ca_done:
    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra


# ============================================================
# Procedure: findFastestLap
# Purpose:   Scans every lap time in the 2D array, tracking
#            the single minimum value seen. Stores the result
#            into fastestTime, fastestDriver, fastestLapNum.
# Arguments: none
# Returns:   none  (updates globals)
# Caller-saved used: $t0-$t9
# Callee-saved saved: $ra, $s0 (driver), $s1 (lap)
# Stack: -12 bytes  |  8($sp)=$ra  4($sp)=$s0  0($sp)=$s1
# ============================================================
findFastestLap:
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    li   $s0, 0                     # driver index

ffl_outer:
    li   $t0, 4
    bge  $s0, $t0, ffl_done

    li   $s1, 0                     # lap index

ffl_inner:
    li   $t0, 5
    bge  $s1, $t0, ffl_next_drv

    li   $t2, 5
    mul  $t3, $s0, $t2
    add  $t3, $t3, $s1
    sll  $t3, $t3, 2
    la   $t4, lapTimes
    add  $t4, $t4, $t3
    lw   $t4, 0($t4)                # current lap time

    la   $t5, fastestTime
    lw   $t6, 0($t5)
    bge  $t4, $t6, ffl_skip         # not a new fastest

    sw   $t4, 0($t5)                # update fastestTime
    la   $t5, fastestDriver
    sw   $s0, 0($t5)                # update fastestDriver
    la   $t5, fastestLapNum
    sw   $s1, 0($t5)                # update fastestLapNum

ffl_skip:
    addi $s1, $s1, 1
    j    ffl_inner

ffl_next_drv:
    addi $s0, $s0, 1
    j    ffl_outer

ffl_done:
    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra


# ============================================================
# Procedure: findSlowestLap
# Purpose:   Scans every lap time in the 2D array, tracking
#            the single maximum value seen. Stores result
#            into slowestTime, slowestDriver, slowestLapNum.
# Arguments: none
# Returns:   none  (updates globals)
# Caller-saved used: $t0-$t6
# Callee-saved saved: $ra, $s0 (driver), $s1 (lap)
# Stack: -12 bytes  |  8($sp)=$ra  4($sp)=$s0  0($sp)=$s1
# ============================================================
findSlowestLap:
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s0, 4($sp)
    sw   $s1, 0($sp)

    li   $s0, 0                     # driver index

fsl_outer:
    li   $t0, 4
    bge  $s0, $t0, fsl_done

    li   $s1, 0                     # lap index

fsl_inner:
    li   $t0, 5
    bge  $s1, $t0, fsl_next_drv

    li   $t2, 5
    mul  $t3, $s0, $t2
    add  $t3, $t3, $s1
    sll  $t3, $t3, 2
    la   $t4, lapTimes
    add  $t4, $t4, $t3
    lw   $t4, 0($t4)                # current lap time

    la   $t5, slowestTime
    lw   $t6, 0($t5)
    ble  $t4, $t6, fsl_skip         # not a new slowest

    sw   $t4, 0($t5)                # update slowestTime
    la   $t5, slowestDriver
    sw   $s0, 0($t5)
    la   $t5, slowestLapNum
    sw   $s1, 0($t5)

fsl_skip:
    addi $s1, $s1, 1
    j    fsl_inner

fsl_next_drv:
    addi $s0, $s0, 1
    j    fsl_outer

fsl_done:
    lw   $s1, 0($sp)
    lw   $s0, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra


# ============================================================
# Procedure: sortDrivers
# Purpose:   Selection sort on rankOrder[] by totalTimes.
#            After sorting, rankOrder[0] = fastest driver,
#            rankOrder[3] = slowest driver.
# Arguments: none
# Returns:   none  (modifies rankOrder[] in place)
# Caller-saved used: $t0-$t7
# Callee-saved saved: $ra, $s0 (i), $s1 (j), $s2 (min_pos)
# Stack: -16 bytes  | 12=$ra  8=$s2  4=$s1  0=$s0
# ============================================================
sortDrivers:
    addi $sp, $sp, -16
    sw   $ra, 12($sp)
    sw   $s2, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    li   $s0, 0                     # outer loop i = 0

sd_outer:
    li   $t0, 3                     # loop while i < 3
    bge  $s0, $t0, sd_done

    move $s2, $s0                   # min_pos = i
    addi $s1, $s0, 1                # inner j = i + 1

sd_inner:
    li   $t0, 4                     # loop while j < 4
    bge  $s1, $t0, sd_swap

    # Load totalTimes[rankOrder[j]]
    la   $t1, rankOrder
    sll  $t2, $s1, 2
    add  $t1, $t1, $t2
    lw   $t3, 0($t1)                # t3 = rankOrder[j]
    la   $t4, totalTimes
    sll  $t5, $t3, 2
    add  $t4, $t4, $t5
    lw   $t6, 0($t4)                # t6 = totalTimes[rankOrder[j]]

    # Load totalTimes[rankOrder[min_pos]]
    la   $t1, rankOrder
    sll  $t2, $s2, 2
    add  $t1, $t1, $t2
    lw   $t3, 0($t1)                # t3 = rankOrder[min_pos]
    la   $t4, totalTimes
    sll  $t5, $t3, 2
    add  $t4, $t4, $t5
    lw   $t7, 0($t4)                # t7 = totalTimes[rankOrder[min_pos]]

    bge  $t6, $t7, sd_no_upd        # j is not better, skip
    move $s2, $s1                   # min_pos = j

sd_no_upd:
    addi $s1, $s1, 1
    j    sd_inner

sd_swap:
    # Swap rankOrder[i] and rankOrder[min_pos]
    la   $t0, rankOrder
    sll  $t1, $s0, 2
    add  $t1, $t0, $t1
    lw   $t2, 0($t1)                # save rankOrder[i]

    sll  $t3, $s2, 2
    add  $t3, $t0, $t3
    lw   $t4, 0($t3)                # save rankOrder[min_pos]

    sw   $t4, 0($t1)                # rankOrder[i] = old min_pos val
    sw   $t2, 0($t3)                # rankOrder[min_pos] = old i val

    addi $s0, $s0, 1
    j    sd_outer

sd_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $s2, 8($sp)
    lw   $ra, 12($sp)
    addi $sp, $sp, 16
    jr   $ra


# ============================================================
# Procedure: printReport
# Purpose:   Iterates through sorted rankOrder[] and prints
#            each driver's rank, name, total, average, and
#            all 5 lap times using helper procedures.
# Arguments: none
# Returns:   none
# Caller-saved used: $t0-$t4
# Callee-saved saved: $ra, $s0 (rank), $s1 (driver index)
# Stack: -12 bytes  |  8=$ra  4=$s1  0=$s0
# ============================================================
printReport:
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    li   $v0, 4
    la   $a0, divider
    syscall
    la   $a0, newline
    syscall

    li   $s0, 0                     # rank = 0

pr_loop:
    li   $t0, 4
    bge  $s0, $t0, pr_done

    # $s1 = rankOrder[rank]
    la   $t1, rankOrder
    sll  $t2, $s0, 2
    add  $t1, $t1, $t2
    lw   $s1, 0($t1)                # driver index at this rank

    # Print "Rank N: "
    li   $v0, 4
    la   $a0, str_rank
    syscall
    li   $v0, 1
    addi $a0, $s0, 1                # display as 1-based rank
    syscall
    li   $v0, 4
    la   $a0, str_col
    syscall

    # Print driver name
    la   $t3, nameAddrs
    sll  $t4, $s1, 2
    add  $t3, $t3, $t4
    lw   $a0, 0($t3)
    li   $v0, 4
    syscall
    la   $a0, newline
    syscall

    # Print total time
    la   $a0, str_total
    syscall
    la   $t3, totalTimes
    sll  $t4, $s1, 2
    add  $t3, $t3, $t4
    lw   $a0, 0($t3)
    jal  printTime

    # Print average time
    li   $v0, 4
    la   $a0, str_avg
    syscall
    la   $t3, avgTimes
    sll  $t4, $s1, 2
    add  $t3, $t3, $t4
    lw   $a0, 0($t3)
    jal  printTime

    # Print all lap times
    li   $v0, 4
    la   $a0, str_laps
    syscall
    move $a0, $s1                   # pass driver index as argument
    jal  printLaps

    li   $v0, 4
    la   $a0, newline
    syscall

    addi $s0, $s0, 1
    j    pr_loop

pr_done:
    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra


# ============================================================
# Procedure: printTime
# Purpose:   Prints a tenths-of-seconds value as "XX.X sec".
#            E.g. 845 is printed as "84.5 sec"
# Arguments: $a0 = time value in tenths of seconds
# Returns:   none
# Caller-saved used: $t1-$t3
# Callee-saved saved: $ra
# Stack: -4 bytes  |  0($sp) = $ra
# ============================================================
printTime:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t1, 10
    div  $a0, $t1
    mflo $t2                        # whole seconds
    mfhi $t3                        # tenths digit

    li   $v0, 1
    move $a0, $t2
    syscall

    li   $v0, 4
    la   $a0, str_dot
    syscall

    li   $v0, 1
    move $a0, $t3
    syscall

    li   $v0, 4
    la   $a0, str_sec
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# ============================================================
# Procedure: printLaps
# Purpose:   Prints all 5 lap times for one driver separated
#            by spaces. E.g. "84.5  83.2  82.9  84.1  83.6"
# Arguments: $a0 = driver index (0-3)
# Returns:   none
# Caller-saved used: $t0-$t4
# Callee-saved saved: $ra, $s0 (driver index), $s1 (lap i)
# Stack: -12 bytes  |  8=$ra  4=$s1  0=$s0
# ============================================================
printLaps:
    addi $sp, $sp, -12
    sw   $ra, 8($sp)
    sw   $s1, 4($sp)
    sw   $s0, 0($sp)

    move $s0, $a0                   # $s0 = driver index
    li   $s1, 0                     # lap index = 0

pl_loop:
    li   $t0, 5
    bge  $s1, $t0, pl_done

    # Load lapTimes[$s0][$s1]
    li   $t1, 5
    mul  $t2, $s0, $t1
    add  $t2, $t2, $s1
    sll  $t2, $t2, 2
    la   $t3, lapTimes
    add  $t3, $t3, $t2
    lw   $t4, 0($t3)                # lap time in tenths

    # Print "XX.X"
    li   $t1, 10
    div  $t4, $t1
    mflo $t2                        # seconds
    mfhi $t3                        # tenths

    li   $v0, 1
    move $a0, $t2
    syscall
    li   $v0, 4
    la   $a0, str_dot
    syscall
    li   $v0, 1
    move $a0, $t3
    syscall

    # Print separator between laps (not after last)
    li   $t0, 4
    beq  $s1, $t0, pl_no_sep
    li   $v0, 4
    la   $a0, str_space
    syscall

pl_no_sep:
    addi $s1, $s1, 1
    j    pl_loop

pl_done:
    li   $v0, 4
    la   $a0, newline
    syscall

    lw   $s0, 0($sp)
    lw   $s1, 4($sp)
    lw   $ra, 8($sp)
    addi $sp, $sp, 12
    jr   $ra


# ============================================================
# Procedure: printHighlights
# Purpose:   Prints the fastest and slowest lap summary with
#            driver name and lap number.
# Arguments: none
# Returns:   none
# Caller-saved used: $t0-$t3
# Callee-saved saved: $ra
# Stack: -4 bytes  |  0($sp) = $ra
# ============================================================
printHighlights:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $v0, 4
    la   $a0, divider
    syscall

    # --- Fastest Lap ---
    la   $a0, str_fastest
    syscall
    la   $t0, fastestTime
    lw   $a0, 0($t0)
    jal  printTimeInline            # prints "XX.X" (no newline)

    li   $v0, 4
    la   $a0, str_by
    syscall

    la   $t0, fastestDriver
    lw   $t1, 0($t0)                # driver index
    la   $t2, nameAddrs
    sll  $t3, $t1, 2
    add  $t2, $t2, $t3
    lw   $a0, 0($t2)
    li   $v0, 4
    syscall

    la   $a0, str_lap
    syscall
    la   $t0, fastestLapNum
    lw   $t1, 0($t0)
    li   $v0, 1
    addi $a0, $t1, 1                # 1-based lap number
    syscall
    li   $v0, 4
    la   $a0, str_rparen
    syscall

    # --- Slowest Lap ---
    la   $a0, str_slowest
    syscall
    la   $t0, slowestTime
    lw   $a0, 0($t0)
    jal  printTimeInline

    li   $v0, 4
    la   $a0, str_by
    syscall

    la   $t0, slowestDriver
    lw   $t1, 0($t0)
    la   $t2, nameAddrs
    sll  $t3, $t1, 2
    add  $t2, $t2, $t3
    lw   $a0, 0($t2)
    li   $v0, 4
    syscall

    la   $a0, str_lap
    syscall
    la   $t0, slowestLapNum
    lw   $t1, 0($t0)
    li   $v0, 1
    addi $a0, $t1, 1
    syscall
    li   $v0, 4
    la   $a0, str_rparen
    syscall

    la   $a0, divider
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra


# ============================================================
# Procedure: printTimeInline
# Purpose:   Prints a time value as "XX.X" with NO newline
#            or " sec" suffix. Used inside printHighlights.
# Arguments: $a0 = time value in tenths of seconds
# Returns:   none
# Caller-saved used: $t1-$t3
# Callee-saved saved: $ra
# Stack: -4 bytes  |  0($sp) = $ra
# ============================================================
printTimeInline:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t1, 10
    div  $a0, $t1
    mflo $t2                        # whole seconds
    mfhi $t3                        # tenths

    li   $v0, 1
    move $a0, $t2
    syscall

    li   $v0, 4
    la   $a0, str_dot
    syscall

    li   $v0, 1
    move $a0, $t3
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra