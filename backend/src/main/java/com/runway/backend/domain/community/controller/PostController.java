package com.runway.backend.domain.community.controller;

import com.runway.backend.domain.community.dto.request.CreatePostRequest;
import com.runway.backend.domain.community.dto.request.UpdatePostRequest;
import com.runway.backend.domain.community.dto.response.PostCreateResponse;
import com.runway.backend.domain.community.dto.response.PostDeleteResponse;
import com.runway.backend.domain.community.dto.response.PostDetailResponse;
import com.runway.backend.domain.community.dto.response.PostListResponse;
import com.runway.backend.domain.community.dto.response.PostUpdateResponse;
import com.runway.backend.domain.community.service.PostService;
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
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;
    private final CurrentUserIdResolver currentUserIdResolver;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public PostCreateResponse create(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @Valid @RequestBody CreatePostRequest request) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return postService.create(userId, request);
    }

    @GetMapping
    public PostListResponse list(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @RequestParam(required = false) String scope,
            @RequestParam(required = false) Long authorId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return postService.list(userId, scope, authorId);
    }

    @GetMapping("/{postId}")
    public PostDetailResponse getDetail(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long postId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return postService.getDetail(userId, postId);
    }

    @PatchMapping("/{postId}")
    public PostUpdateResponse update(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long postId,
            @Valid @RequestBody UpdatePostRequest request) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return postService.update(userId, postId, request);
    }

    @DeleteMapping("/{postId}")
    public PostDeleteResponse delete(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long postId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return postService.delete(userId, postId);
    }
}
