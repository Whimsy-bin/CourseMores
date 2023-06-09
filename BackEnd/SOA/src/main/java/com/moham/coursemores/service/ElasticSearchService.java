package com.moham.coursemores.service;

import com.moham.coursemores.domain.document.CourseDocument;
import com.moham.coursemores.domain.document.CourseLocationDocument;
import com.moham.coursemores.domain.document.HashtagDocument;
import com.moham.coursemores.dto.elasticsearch.IndexDataReqDTO;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public interface ElasticSearchService {

    Boolean index(CourseDocument courseDocument);

    Boolean indexLoction(CourseLocationDocument courseLocationDocument);

    Boolean indexHashtag(HashtagDocument hashtagDocument);

    void addIndex(IndexDataReqDTO indexDataReqDTO);

    Map<String, List<Integer>> search(String value) throws IOException;

    void updateIndex(IndexDataReqDTO indexDataReqDTO) throws IOException;

    void updateCli(String id, String index, String value) throws IOException;

    void deleteIndex(String id) throws IOException;

    void deleteCli(String id, String index) throws IOException;

}