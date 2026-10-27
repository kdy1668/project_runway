package com.runway.backend.domain.crew.controller;

import com.runway.backend.domain.crew.dto.response.MyCrewListResponse;
import com.runway.backend.domain.crew.service.CrewService;
import com.runway.backend.global.auth.CurrentUserIdResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users/me/crews")
@RequiredArgsConstructor
public class MyCrewController {

    private final CrewService crewService;
    private final CurrentUserIdResolver currentUserIdResolver;

    @GetMapping
    public MyCrewListResponse listMyCrews(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @RequestParam(required = false) String membershipStatus) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return crewService.listMyCrews(userId, membershipStatus);
    }
}
