package com.runway.backend.domain.community.controller;

import com.runway.backend.domain.community.dto.request.CreateCommentRequest;
import com.runway.backend.domain.community.dto.request.UpdateCommentRequest;
import com.runway.backend.domain.community.dto.response.CommentCreateResponse;
import com.runway.backend.domain.community.dto.response.CommentDeleteResponse;
import com.runway.backend.domain.community.dto.response.CommentListResponse;
import com.runway.backend.domain.community.dto.response.CommentUpdateResponse;
import com.runway.backend.domain.community.service.CommentService;
import com.runway.backend.global.auth.CurrentUserIdResolver;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;
    private final CurrentUserIdResolver currentUserIdResolver;

    @GetMapping("/api/v1/posts/{postId}/comments")
    public CommentListResponse list(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long postId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return commentService.list(userId, postId);
    }

    @PostMapping("/api/v1/posts/{postId}/comments")
    @ResponseStatus(HttpStatus.CREATED)
    public CommentCreateResponse create(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long postId,
            @RequestBody(required = false) CreateCommentRequest request) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return commentService.create(userId, postId, request);
    }

    @PatchMapping("/api/v1/comments/{commentId}")
    public CommentUpdateResponse update(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long commentId,
            @RequestBody(required = false) UpdateCommentRequest request) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return commentService.update(userId, commentId, request);
    }

    @DeleteMapping("/api/v1/comments/{commentId}")
    public CommentDeleteResponse delete(
            @RequestHeader(value = CurrentUserIdResolver.HEADER, required = false)
                    String userIdHeader,
            @PathVariable long commentId) {
        long userId = currentUserIdResolver.requireUserId(userIdHeader);
        return commentService.delete(userId, commentId);
    }
}
