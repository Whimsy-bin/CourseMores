package com.moham.coursemores.domain;

import com.moham.coursemores.domain.time.DeleteTimeEntity;
import com.moham.coursemores.dto.course.CourseUpdateReqDto;
import java.time.LocalDateTime;
import java.util.List;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.OneToMany;
import javax.persistence.Table;
import javax.validation.constraints.NotNull;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Entity
@Table(name = "course")
@Getter
@ToString
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class Course extends DeleteTimeEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "course_id")
    private Long id;

    @NotNull
    @Column
    private String title;

    @Column(length = 5000)
    private String content;

    @Column
    private int people;

    @Column
    private int time;

    @NotNull
    @Column
    private boolean visited;

    @NotNull
    @Column
    private int viewCount;

    @NotNull
    @Column
    private int likeCount;

    @NotNull
    @Column
    private int interestCount;

    @NotNull
    @Column
    private int commentCount;

    @NotNull
    @Column(length = 1000)
    private String image;

    @NotNull
    @Column
    private String locationName;

    @NotNull
    @Column
    private double latitude;

    @NotNull
    @Column
    private double longitude;

    @NotNull
    @Column
    private String sido;

    @NotNull
    @Column
    private String gugun;

    @NotNull
    @Column
    private int locationSize;

    @NotNull
    @ManyToOne(targetEntity = User.class, fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CourseLocation> courseLocationList;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<HashtagOfCourse> courseHashtagList;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ThemeOfCourse> themeOfCourseList;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CourseLike> courseLikeList;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Interest> interestList;

    @OneToMany(mappedBy = "course", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Comment> commentList;

    @Builder
    public Course(String title,
            String content,
            int people,
            int time,
            boolean visited,
            int viewCount,
            int likeCount,
            int interestCount,
            int commentCount,
            String image,
            String locationName,
            double latitude,
            double longitude,
            String sido,
            String gugun,
            int locationSize,
            User user) {
        this.title = title;
        this.content = content;
        this.people = people;
        this.time = time;
        this.visited = visited;
        this.viewCount = viewCount;
        this.interestCount = interestCount;
        this.likeCount = likeCount;
        this.commentCount = commentCount;
        this.locationName = locationName;
        this.image = image;
        this.latitude = latitude;
        this.longitude = longitude;
        this.sido = sido;
        this.gugun = gugun;
        this.locationSize = locationSize;
        this.user = user;
    }

    public void setMainImage(String image) {
        this.image = image;
    }

    public void increaseViewCount() {
        this.viewCount++;
    }

    public void increaseInterestCount() {
        this.interestCount++;
    }

    public void decreaseInterestCount() {
        this.interestCount--;
    }

    public void increaseLikeCount() {
        this.likeCount++;
    }

    public void decreaseLikeCount() {
        this.likeCount--;
    }

    public void increaseCommentCount() {
        this.commentCount++;
    }

    public void decreaseCommentCount() {
        this.commentCount--;
    }

    public void update(CourseUpdateReqDto courseUpdateReqDto) {
        this.title = courseUpdateReqDto.getTitle();
        this.content = courseUpdateReqDto.getContent();
        this.people = courseUpdateReqDto.getPeople();
        this.time = courseUpdateReqDto.getTime();
        this.visited = courseUpdateReqDto.getVisited();
        this.locationName = courseUpdateReqDto.getLocationList().get(0).getName();
    }

    public void delete() {
        this.deleteTime = LocalDateTime.now();
    }

}