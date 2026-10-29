package com.runway.watch.run

import kotlinx.coroutines.flow.StateFlow

/** Session states confirmed in docs/design/api/sessions.md. A pending command never changes them. */
enum class RunState { READY, RUNNING, PAUSED, COMPLETED, CANCELLED, INTERRUPTED }

enum class RunMode { PERSONAL, GROUP }

/** Measured wrist heart rate. Kept apart from [RhythmBpm] so the two are never shown interchangeably. */
@JvmInline value class HeartRate(val bpm: Int)

/** Step rhythm cue tempo. */
@JvmInline value class RhythmBpm(val beatsPerMinute: Int)

data class RunMetrics(
    val distanceMeters: Double? = null,
    val elapsedMs: Long? = null,
    val paceSecondsPerKm: Int? = null,
    val guidePaceSecondsPerKm: Int? = null,
    val heartRate: HeartRate? = null,
    val cadenceSpm: Int? = null,
    val rhythm: RhythmBpm? = null,
    /** Distance progress toward the goal, 0..1, or null when there is no distance goal. */
    val goalProgress: Float? = null,
    val feeds: MetricFeeds = MetricFeeds(),
)

data class RunSnapshot(
    /** Null until the phone has handed over a prepared session. */
    val state: RunState? = null,
    val mode: RunMode = RunMode.PERSONAL,
    val phoneConnected: Boolean = true,
    /** A command was accepted but its real application is not confirmed yet. */
    val pendingCommand: Boolean = false,
    val title: String? = null,
    val metrics: RunMetrics = RunMetrics(),
)

/** User requests. Only these reach the run controller; screen changes follow the confirmed state. */
enum class RunIntent { START, PAUSE, RESUME, END, RECONNECT_PHONE }

interface RunControl {
    val snapshot: StateFlow<RunSnapshot>
    fun send(intent: RunIntent)
}
