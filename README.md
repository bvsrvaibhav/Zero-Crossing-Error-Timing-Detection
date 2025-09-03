# QPSK Symbol Timing Synchronization

This project implements a symbol timing synchronization loop for a Quadrature Phase Shift Keying (QPSK) receiver in Verilog.
It uses a Zero-Crossing Timing Error Detector (ZCTED), loop filter, interpolator, and Numerically Controlled Oscillator (NCO) to align the sampling instants with the incoming symbol stream.

🔹 What is ZCTED?

ZCTED stands for Zero-Crossing Timing Error Detector.
It is a widely used timing error detection technique in digital communication receivers.

In QPSK and other modulation schemes, the In-phase (I) or Quadrature (Q) components of the signal cross zero at known intervals depending on symbol timing.

If the receiver samples too early or too late, these zero-crossing instants shift, introducing timing errors.

The ZCTED measures this misalignment and produces an error signal (eₖ) used to correct the receiver’s sampling phase.

🔹 How ZCTED Works in This Design

In this implementation:

Interpolator
Produces fractional sample values of the incoming I/Q signals, allowing fine adjustments of sampling time.

ZCTED Calculation
The detector uses the formula:

𝑒
(
𝑘
)
=
𝐼
[
𝑛
−
1
]
⋅
(
sgn
(
𝐼
[
𝑛
]
)
−
sgn
(
𝐼
[
𝑛
−
2
]
)
)
e(k)=I[n−1]⋅(sgn(I[n])−sgn(I[n−2]))

𝐼
[
𝑛
]
I[n]: Current interpolated sample

𝐼
[
𝑛
−
1
]
,
𝐼
[
𝑛
−
2
]
I[n−1],I[n−2]: Delayed samples

sgn(x): Sign function (+1, -1, or 0)

This measures whether the samples are aligned with the expected zero-crossings.

Zero Stuffer
Passes the error signal only when the NCO signals a valid symbol boundary (underflow condition).

Loop Filter + NCO

The loop filter smooths the error signal.

The NCO updates µ (mu), the fractional timing phase, to re-align the sampling instants.

Output
Corrected symbols are produced on I_out and Q_out, with valid_out indicating valid timing-corrected samples.

🔹 Constellation Diagram Explanation

The image you provided shows a QPSK Constellation Diagram:

Axes:

X-axis = In-Phase (I)

Y-axis = Quadrature (Q)

Clusters:

Four distinct clusters represent the 4 possible QPSK symbols:

(+I, +Q), (+I, -Q), (-I, +Q), (-I, -Q)

Spread of Points:

The scatter around each cluster is caused by channel noise and imperfect synchronization.

With proper timing synchronization using ZCTED, the clusters become tighter and more separated, improving bit error rate (BER).

🔹 Why ZCTED is Useful

Simple to implement in hardware (only sign detection and multiplication).

Works well with QPSK and other linear modulation schemes.

Provides good performance in moderate noise conditions.

Ensures the receiver samples at the optimal point, reducing symbol errors.
