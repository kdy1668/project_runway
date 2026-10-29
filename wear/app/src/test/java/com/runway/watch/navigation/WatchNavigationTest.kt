package com.runway.watch.navigation

import com.runway.watch.run.RunMode
import com.runway.watch.run.RunSnapshot
import com.runway.watch.run.RunState
import org.junit.Assert.*
import org.junit.Test

class WatchNavigationTest {
    private fun snapshot(state: RunState?, phone: Boolean = true, mode: RunMode = RunMode.PERSONAL) =
        RunSnapshot(state = state, mode = mode, phoneConnected = phone)

    @Test fun confirmedStateDecidesTheScreen() {
        val nav = NavState()
        assertEquals(WatchRoute.STANDBY, WatchNavigation.route(snapshot(null), nav))
        assertEquals(WatchRoute.STANDBY, WatchNavigation.route(snapshot(RunState.READY), nav))
        assertEquals(WatchRoute.RUNNING, WatchNavigation.route(snapshot(RunState.RUNNING), nav))
        assertEquals(WatchRoute.PAUSED, WatchNavigation.route(snapshot(RunState.PAUSED), nav))
        assertEquals(WatchRoute.RESULT, WatchNavigation.route(snapshot(RunState.COMPLETED), nav))
        assertEquals(WatchRoute.RESULT, WatchNavigation.route(snapshot(RunState.INTERRUPTED), nav))
        assertEquals(WatchRoute.STANDBY, WatchNavigation.route(snapshot(RunState.CANCELLED), nav))
    }

    @Test fun pendingStartDoesNotLeaveStandby() {
        val pending = snapshot(RunState.READY).copy(pendingCommand = true)
        assertEquals(WatchRoute.STANDBY, WatchNavigation.route(pending, NavState()))
    }

    @Test fun phoneDisconnectOnlyReplacesScreensBeforeTheRun() {
        assertEquals(WatchRoute.CONNECTION_ISSUE, WatchNavigation.route(snapshot(RunState.READY, phone = false), NavState()))
        assertEquals(WatchRoute.CONNECTION_ISSUE, WatchNavigation.route(snapshot(null, phone = false), NavState()))
        assertEquals(WatchRoute.RUNNING, WatchNavigation.route(snapshot(RunState.RUNNING, phone = false), NavState()))
        assertEquals(WatchRoute.PAUSED, WatchNavigation.route(snapshot(RunState.PAUSED, phone = false), NavState()))
    }

    @Test fun endConfirmIsOnlyReachableWhilePaused() {
        val open = NavState(endConfirmOpen = true)
        assertEquals(WatchRoute.END_CONFIRM, WatchNavigation.route(snapshot(RunState.PAUSED), open))
        assertEquals(WatchRoute.RUNNING, WatchNavigation.route(snapshot(RunState.RUNNING), open))
        assertEquals(NavState(), WatchNavigation.reconcile(snapshot(RunState.RUNNING), open))
    }

    @Test fun leavingRunningResetsThePager() {
        val paged = NavState(page = 2)
        assertEquals(2, WatchNavigation.reconcile(snapshot(RunState.RUNNING), paged).page)
        assertEquals(0, WatchNavigation.reconcile(snapshot(RunState.PAUSED), paged).page)
    }

    @Test fun pagesDifferOnlyByModeAfterTheStatusPage() {
        assertEquals(listOf(RunPage.STATUS, RunPage.PACE_COACHING, RunPage.RECORD_COMPARE), WatchNavigation.pages(RunMode.PERSONAL))
        assertEquals(listOf(RunPage.STATUS, RunPage.GROUP_PACE, RunPage.GROUP_POSITION), WatchNavigation.pages(RunMode.GROUP))
    }

    @Test fun backNeverLeavesAnActiveRun() {
        val running = snapshot(RunState.RUNNING)
        assertEquals(BackResult(NavState(page = 0), handled = true), WatchNavigation.back(running, NavState(page = 2)))
        assertEquals(BackResult(NavState(), handled = true), WatchNavigation.back(running, NavState()))
        assertEquals(BackResult(NavState(), handled = true), WatchNavigation.back(snapshot(RunState.PAUSED), NavState()))
    }

    @Test fun backFromEndConfirmReturnsToPauseWithoutEnding() {
        val result = WatchNavigation.back(snapshot(RunState.PAUSED), NavState(endConfirmOpen = true))
        assertEquals(BackResult(NavState(), handled = true), result)
    }

    @Test fun backOutsideARunLetsTheSystemCloseTheApp() {
        assertFalse(WatchNavigation.back(snapshot(RunState.READY), NavState()).handled)
        assertFalse(WatchNavigation.back(snapshot(null, phone = false), NavState()).handled)
        assertFalse(WatchNavigation.back(snapshot(RunState.COMPLETED), NavState()).handled)
    }

    @Test fun swipeToCloseOnlyOutsideARun() {
        val exits = WatchRoute.entries.filter(WatchNavigation::canExit)
        assertEquals(listOf(WatchRoute.STANDBY, WatchRoute.CONNECTION_ISSUE, WatchRoute.RESULT), exits)
    }
}
