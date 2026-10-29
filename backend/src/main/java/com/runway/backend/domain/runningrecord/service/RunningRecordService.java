package com.runway.backend.domain.runningrecord.service;

import com.runway.backend.domain.runningrecord.dto.response.RunningRecordDetailResponse;
import com.runway.backend.domain.runningrecord.dto.response.RunningRecordListItemResponse;
import com.runway.backend.domain.runningrecord.dto.response.RunningRecordListResponse;
import com.runway.backend.domain.runningrecord.dto.response.RunningRecordSplitItemResponse;
import com.runway.backend.domain.runningrecord.dto.response.RunningRecordSplitsResponse;
import com.runway.backend.domain.runningrecord.helper.RunningRecordAccessHelper;
import com.runway.backend.domain.runningrecord.repository.RunningRecordJdbcRepository;
import com.runway.backend.domain.runningrecord.repository.RunningRecordJdbcRepository.ListCursor;
import com.runway.backend.domain.runningrecord.repository.RunningRecordJdbcRepository.ListItemRow;
import com.runway.backend.domain.runningrecord.repository.RunningRecordJdbcRepository.RunTypeFilter;
import com.runway.backend.domain.runningrecord.repository.RunningRecordJdbcRepository.SessionRow;
import com.runway.backend.domain.runningrecord.repository.RunningRecordJdbcRepository.SortType;
import com.runway.backend.global.exception.ApiException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.Base64;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RunningRecordService {

    private static final int DEFAULT_LIMIT = 20;
    private static final int MAX_LIMIT = 50;

    /**
     * Opaque cursor payload: {@code SORT|sortValue|id}. sortValue is ISO-8601 Instant (LATEST) or
     * plain decimal (DISTANCE/PACE); empty sortValue means NULL sort key.
     */
    private static final Pattern CURSOR_PATTERN =
            Pattern.compile("(LATEST|DISTANCE|PACE)\\|([^|]*)\\|(\\d+)");

    private final RunningRecordJdbcRepository runningRecordJdbcRepository;
    private final RunningRecordAccessHelper runningRecordAccessHelper;

    /**
     * H01 목록. {@code from}/{@code to}는 ISO-8601 Instant이며, 둘 다 있으면 {@code started_at >= from AND
     * started_at < to} (from inclusive, to exclusive).
     */
    @Transactional(readOnly = true)
    public RunningRecordListResponse list(
            long userId,
            String cursor,
            Integer limit,
            String from,
            String to,
            Long courseId,
            String runType,
            String sort) {
        requireExistingUser(userId);

        int pageSize = resolveLimit(limit);
        Instant fromInclusive = parseInstantParam(from, "from");
        Instant toExclusive = parseInstantParam(to, "to");
        if (fromInclusive != null && toExclusive != null && !fromInclusive.isBefore(toExclusive)) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_FILTER",
                    "from은 to보다 이전이어야 합니다.");
        }
        RunTypeFilter runTypeFilter = parseRunType(runType);
        SortType sortType = parseSort(sort);
        ListCursor listCursor = parseCursor(cursor, sortType);

        List<ListItemRow> rows =
                runningRecordJdbcRepository.findCompletedRecords(
                        userId,
                        fromInclusive,
                        toExclusive,
                        courseId,
                        runTypeFilter,
                        sortType,
                        listCursor,
                        pageSize + 1);

        boolean hasMore = rows.size() > pageSize;
        List<ListItemRow> pageRows = hasMore ? rows.subList(0, pageSize) : rows;

        List<RunningRecordListItemResponse> items =
                pageRows.stream()
                        .map(
                                row ->
                                        new RunningRecordListItemResponse(
                                                row.id(),
                                                row.courseId(),
                                                row.startedAt(),
                                                row.totalDistance(),
                                                row.movingDuration(),
                                                row.averagePace(),
                                                row.goalAchieved()))
                        .toList();

        String nextPage =
                hasMore ? encodeCursor(sortType, pageRows.get(pageRows.size() - 1)) : null;
        return new RunningRecordListResponse(items, nextPage);
    }

    @Transactional(readOnly = true)
    public RunningRecordDetailResponse getDetail(long userId, long sessionId) {
        requireExistingUser(userId);
        SessionRow session = runningRecordAccessHelper.requireOwnedSession(userId, sessionId);
        return new RunningRecordDetailResponse(
                session.id(),
                session.goalDistance(),
                session.goalDuration(),
                session.totalDistance(),
                session.movingDuration(),
                session.elapsedDuration(),
                session.averagePace(),
                session.averageHeartRate(),
                session.averageCadence(),
                session.goalAchieved(),
                session.courseId(),
                session.goalPace(),
                session.comparisonSessionId());
    }

    @Transactional(readOnly = true)
    public RunningRecordSplitsResponse getSplits(long userId, long sessionId) {
        requireExistingUser(userId);
        runningRecordAccessHelper.requireOwnedSession(userId, sessionId);
        List<RunningRecordSplitItemResponse> splits =
                runningRecordJdbcRepository.findSplitsBySessionId(sessionId).stream()
                        .map(
                                row ->
                                        new RunningRecordSplitItemResponse(
                                                row.startDistance(),
                                                row.endDistance(),
                                                row.pace(),
                                                row.averageHeartRate(),
                                                row.averageCadence()))
                        .toList();
        return new RunningRecordSplitsResponse(splits);
    }

    private void requireExistingUser(long userId) {
        if (!runningRecordJdbcRepository.existsUserById(userId)) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", "인증이 필요합니다.");
        }
    }

    private static int resolveLimit(Integer limit) {
        if (limit == null) {
            return DEFAULT_LIMIT;
        }
        if (limit < 1 || limit > MAX_LIMIT) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    "limit은 1 이상 " + MAX_LIMIT + " 이하여야 합니다.");
        }
        return limit;
    }

    private static Instant parseInstantParam(String raw, String name) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Instant.parse(raw.trim());
        } catch (DateTimeParseException ex) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "VALIDATION_ERROR",
                    name + "은 ISO-8601 Instant 형식이어야 합니다.");
        }
    }

    private static RunTypeFilter parseRunType(String runType) {
        if (runType == null || runType.isBlank()) {
            return RunTypeFilter.ALL;
        }
        try {
            return RunTypeFilter.valueOf(runType.trim());
        } catch (IllegalArgumentException ex) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_FILTER",
                    "runType은 ALL, SOLO, GROUP만 허용됩니다.");
        }
    }

    private static SortType parseSort(String sort) {
        if (sort == null || sort.isBlank()) {
            return SortType.LATEST;
        }
        try {
            return SortType.valueOf(sort.trim());
        } catch (IllegalArgumentException ex) {
            throw new ApiException(
                    HttpStatus.BAD_REQUEST,
                    "INVALID_FILTER",
                    "sort는 LATEST, DISTANCE, PACE만 허용됩니다.");
        }
    }

    private static ListCursor parseCursor(String cursor, SortType expectedSort) {
        if (cursor == null || cursor.isBlank()) {
            return null;
        }
        try {
            String decoded =
                    new String(
                            Base64.getUrlDecoder().decode(cursor.trim()), StandardCharsets.UTF_8);
            Matcher matcher = CURSOR_PATTERN.matcher(decoded);
            if (!matcher.matches()) {
                throw invalidCursor();
            }
            SortType sort = SortType.valueOf(matcher.group(1));
            if (sort != expectedSort) {
                throw invalidCursor();
            }
            String sortValue = matcher.group(2);
            long id = Long.parseLong(matcher.group(3));
            if (id < 1) {
                throw invalidCursor();
            }
            return switch (sort) {
                case LATEST ->
                        ListCursor.forLatest(
                                sortValue.isEmpty() ? null : Instant.parse(sortValue), id);
                case DISTANCE ->
                        ListCursor.forDistance(
                                sortValue.isEmpty() ? null : new BigDecimal(sortValue), id);
                case PACE ->
                        ListCursor.forPace(
                                sortValue.isEmpty() ? null : new BigDecimal(sortValue), id);
            };
        } catch (IllegalArgumentException | DateTimeParseException | ArithmeticException ex) {
            throw invalidCursor();
        }
    }

    private static String encodeCursor(SortType sort, ListItemRow row) {
        String sortValue =
                switch (sort) {
                    case LATEST ->
                            row.startedAt() == null ? "" : row.startedAt().toString();
                    case DISTANCE ->
                            row.totalDistance() == null
                                    ? ""
                                    : row.totalDistance().toPlainString();
                    case PACE ->
                            row.averagePace() == null ? "" : row.averagePace().toPlainString();
                };
        String raw = sort.name() + "|" + sortValue + "|" + row.id();
        return Base64.getUrlEncoder()
                .withoutPadding()
                .encodeToString(raw.getBytes(StandardCharsets.UTF_8));
    }

    private static ApiException invalidCursor() {
        return new ApiException(
                HttpStatus.BAD_REQUEST, "VALIDATION_ERROR", "cursor 형식이 올바르지 않습니다.");
    }
}
