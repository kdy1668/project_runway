package com.runway.backend.domain.crew.controller;

import com.runway.backend.domain.crew.dto.request.CreateCrewRequest;
import com.runway.backend.domain.crew.dto.request.DecideJoinRequest;
import com.runway.backend.domain.crew.dto.response.CrewCreateResponse;
import com.runway.backend.domain.crew.dto.response.CrewDetailResponse;
import com.runway.backend.domain.crew.dto.response.CrewListResponse;
import com.runway.backend.domain.crew.dto.response.DecideJoinResponse;
import com.runway.backend.domain.crew.dto.response.JoinRequestListResponse;
import com.runway.backend.domain.crew.dto.response.JoinRequestResponse;
import com.runway.backend.domain.crew.dto.response.MemberLeaveResponse;
import com.runway.backend.domain.crew.dto.response.MemberListResponse;
import com.runway.backend.domain.crew.service.CrewService;
import com.runway.backend.global.auth.CurrentUserIdResolver;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/crews")
@RequiredArgsConstructor
public class CrewController {

    private final CrewService crewService;
    private final CurrentUserIdResolver currentUserIdResolver;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CrewCreateResponse create(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @Valid @RequestBody CreateCrewRequest request) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.create(userId, request);
    }

    @GetMapping("/{crewId}")
    public CrewDetailResponse getDetail(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.getDetail(userId, crewId);
    }

    @GetMapping
    public CrewListResponse search(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String regionCode) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.search(userId, q, regionCode);
    }

    @PostMapping("/{crewId}/join-requests")
    public JoinRequestResponse createJoinRequest(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.createJoinRequest(userId, crewId);
    }

    @GetMapping("/{crewId}/join-requests")
    public JoinRequestListResponse listJoinRequests(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId,
            @RequestParam(required = false) String status) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.listJoinRequests(userId, crewId, status);
    }

    @PatchMapping("/{crewId}/join-requests/{userId}")
    public DecideJoinResponse decideJoinRequest(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId,
            @PathVariable long userId,
            @Valid @RequestBody DecideJoinRequest request) {
        long ownerUserId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.decideJoinRequest(ownerUserId, crewId, userId, request);
    }

    @GetMapping("/{crewId}/members")
    public MemberListResponse listMembers(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.listMembers(userId, crewId);
    }

    @DeleteMapping("/{crewId}/members/me")
    public MemberLeaveResponse leave(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.leave(userId, crewId);
    }

    @DeleteMapping("/{crewId}/members/{userId}")
    public MemberLeaveResponse removeMember(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long crewId,
            @PathVariable long userId) {
        long ownerUserId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.removeMember(ownerUserId, crewId, userId);
    }
}
