package com.moham.coursemores.service.impl;

import com.moham.coursemores.common.exception.CustomErrorCode;
import com.moham.coursemores.common.exception.CustomException;
import com.moham.coursemores.domain.Comment;
import com.moham.coursemores.domain.CommentImage;
import com.moham.coursemores.domain.Course;
import com.moham.coursemores.domain.User;
import com.moham.coursemores.dto.comment.*;
import com.moham.coursemores.dto.profile.UserSimpleInfoResDto;
import com.moham.coursemores.repository.CommentImageRepository;
import com.moham.coursemores.repository.CommentRepository;
import com.moham.coursemores.repository.CourseRepository;
import com.moham.coursemores.repository.UserRepository;
import com.moham.coursemores.service.CommentService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CommentServiceImpl implements CommentService {

    private final FileUploadService fileUploadService;
    private final CommentRepository commentRepository;
    private final CommentImageRepository commentImageRepository;
    private final UserRepository userRepository;
    private final CourseRepository courseRepository;

    private static final String DEFAULT_NICKNAME = "(알 수 없음)";
    private static final String DEFAULT_IMAGE_URL = "https://coursemores.s3.amazonaws.com/default_profile.png";

    @Override
    public List<CommentResDTO> getCommentList(Long courseId, Long userId, int page, String sortby) {
        // user를 불러와서 그 유저가 작성한 코멘트인지 확인하기
        User user = userRepository.findByIdAndDeleteTimeIsNull(userId)
                .orElseThrow(() -> new CustomException(userId, CustomErrorCode.USER_NOT_FOUND));

        // 한 페이지에 보여줄 댓글의 수
        final int size = 50;

        // Sort 정렬 기준
        Sort sort = ("Like".equals(sortby)) ?
                Sort.by("likeCount").descending() :
                Sort.by("createTime").descending();
        Pageable pageable = PageRequest.of(page, size, sort);

        List<Long> userLikeComment = user.getCommentLikeList()
                .stream()
                .map(like -> like.isFlag() ? like.getComment().getId() : null)
                .collect(Collectors.toList());

        return commentRepository.findByCourseIdAndDeleteTimeIsNull(courseId, pageable)
                .stream()
                .map(comment -> CommentResDTO.builder()
                        .commentId(comment.getId())
                        .content(comment.getContent())
                        .people(comment.getPeople())
                        .likeCount(comment.getLikeCount())
                        .imageList(comment.getCommentImageList()
                                .stream()
                                .map(commentImage -> CommentImageResDTO.builder()
                                        .commentImageId(commentImage.getId())
                                        .image(commentImage.getImage())
                                        .build())
                                        .collect(Collectors.toList()))
                        .createTime(comment.getCreateTime())
                        .isWrite(Objects.equals(comment.getUser().getId(), user.getId()))
                        .isLike(userLikeComment.contains(comment.getId()))
                        .writeUser(UserSimpleInfoResDto.builder()
                                .nickname(comment.getUser().getDeleteTime() != null ? DEFAULT_NICKNAME : comment.getUser().getNickname())
                                .profileImage(comment.getUser().getDeleteTime() != null ? DEFAULT_IMAGE_URL : comment.getUser().getProfileImage())
                                .build())
                        .build()
                )
                .collect(Collectors.toList());
    }

    @Override
    public List<MyCommentResDto> getMyCommentList(Long userId) {
        // 유저 정보 가져오기
        User user = userRepository.findByIdAndDeleteTimeIsNull(userId)
                .orElseThrow(() -> new CustomException(userId,CustomErrorCode.USER_NOT_FOUND));

        // userId가 작성한 댓글 중 deletetime이 null이 아닌 댓글(삭제되지 않은 댓글)
        return commentRepository.findByUserIdAndDeleteTimeIsNull(user.getId())
                .stream()
                .map(comment -> MyCommentResDto.builder()
                        .commentId(comment.getId())
                        .content(comment.getContent())
                        .people(comment.getPeople())
                        .likeCount(comment.getLikeCount())
                        .imageList(comment.getCommentImageList()
                                .stream()
                                .map(CommentImage::getImage)
                                .collect(Collectors.toList()))
                        .createTime(comment.getCreateTime())
                        .courseId(comment.getCourse().getId())
                        .courseTitle(comment.getCourse().getTitle())
                        .build()
                )
                .sorted((o1, o2) -> Long.compare(o2.getCommentId(), Objects.requireNonNull(o1).getCommentId()))
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public void createComment(Long courseId, Long userId, CommentCreateReqDTO commentCreateReqDTO, List<MultipartFile> imageList) {
        // userId의 User 가져오기
        User user = userRepository.findByIdAndDeleteTimeIsNull(userId)
                .orElseThrow(() -> new CustomException(userId,CustomErrorCode.USER_NOT_FOUND));

        //courseId의 Course 가져오기
        Course course = courseRepository.findByIdAndDeleteTimeIsNull(courseId)
                .orElseThrow(() -> new CustomException(courseId,CustomErrorCode.COURSE_NOT_FOUND));

        // courseId의 course가 있다면 course + DTO를 기반으로 새로운 댓글 생성
        Comment comment = Comment.builder()
                .content(commentCreateReqDTO.getContent())
                .people(commentCreateReqDTO.getPeople())
                .user(user)
                .course(course)
                .build();

        commentRepository.save(comment);

        if (imageList != null) {
            // commentImage table에도 사진 추가
            for (MultipartFile multipartFile : imageList) {
                String imagePath = fileUploadService.uploadImage(multipartFile);
                commentImageRepository.save(CommentImage.builder()
                        .image(imagePath)
                        .comment(comment)
                        .build());
            }
        }
        // 코스의 댓글 수 증가
        course.increaseCommentCount();
    }

    @Override
    @Transactional
    public void updateComment(Long commentId, Long userId, CommentUpdateReqDTO commentUpdateReqDTO, List<MultipartFile> imageList) {
        // userId의 User 가져오기
        User user = userRepository.findByIdAndDeleteTimeIsNull(userId)
                .orElseThrow(() -> new CustomException(userId,CustomErrorCode.USER_NOT_FOUND));

        // commentId의 Comment 가져오기
        Comment comment = commentRepository.findByIdAndUserIdAndDeleteTimeIsNull(commentId, user.getId())
                .orElseThrow(() -> new CustomException(commentId,CustomErrorCode.COMMENT_NOT_FOUND));

        // commentId의 comment가 있다면 comment를 가져와서 수정
        comment.update(commentUpdateReqDTO.getContent(), commentUpdateReqDTO.getPeople());

        // 기존에 있었던 commentImage 삭제
        for (long courseImageId : commentUpdateReqDTO.getDeleteImageList()) {
            CommentImage commentImage = commentImageRepository.findById(courseImageId)
                    .orElseThrow(() -> new CustomException(courseImageId,CustomErrorCode.COMMENT_IMAGE_NOT_FOUND));
            commentImageRepository.delete(commentImage);
        }

        if (imageList != null) {
            // 이미지 새롭게 추가
            for (MultipartFile multipartFile : imageList) {
                String imagePath = fileUploadService.uploadImage(multipartFile);
                commentImageRepository.save(CommentImage.builder()
                        .image(imagePath)
                        .comment(comment)
                        .build());
            }
        }

    }

    @Override
    @Transactional
    public void deleteComment(Long commentId, Long userId) {
        // userId의 User 가져오기
        User user = userRepository.findByIdAndDeleteTimeIsNull(userId)
                .orElseThrow(() -> new CustomException(userId,CustomErrorCode.USER_NOT_FOUND));

        // commentId의 Comment 가져오기
        Comment comment = commentRepository.findByIdAndUserIdAndDeleteTimeIsNull(commentId, user.getId())
                .orElseThrow(() -> new CustomException(commentId,CustomErrorCode.COMMENT_NOT_FOUND));

        // commentId의 comment가 있다면 comment를 가져와서 수정
        comment.delete();

        // 코스의 댓글 수 감소
        comment.getCourse().decreaseCommentCount();
    }

}