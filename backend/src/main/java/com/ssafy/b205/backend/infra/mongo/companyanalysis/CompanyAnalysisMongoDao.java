package com.ssafy.b205.backend.infra.mongo.companyanalysis;

import com.ssafy.b205.backend.infra.mongo.companyanalysis.doc.CompanyAnalysisDoc;
import com.ssafy.b205.backend.infra.mongo.companyanalysis.doc.InvestingNewsDoc;
import com.ssafy.b205.backend.infra.mongo.companyanalysis.doc.NewsPersonaAnalysisDoc;
import org.bson.types.ObjectId;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.aggregation.Aggregation;
import org.springframework.data.mongodb.core.aggregation.AggregationResults;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Repository;
import org.springframework.util.StringUtils;

import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

@Repository
public class CompanyAnalysisMongoDao {

    private static final String COLLECTION_INVESTING_NEWS = "investing_news";
    private static final String COLLECTION_COMPANY_ANALYSIS = "company_analysis";
    private static final String COLLECTION_NEWS_PERSONA = "news_persona_analysis";

    private final MongoTemplate mongoTemplate;

    public CompanyAnalysisMongoDao(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    public List<InvestingNewsDoc> sampleInvestingNews(int size) {
        Aggregation agg = Aggregation.newAggregation(Aggregation.sample(size));
        AggregationResults<InvestingNewsDoc> result =
                mongoTemplate.aggregate(agg, COLLECTION_INVESTING_NEWS, InvestingNewsDoc.class);
        return result.getMappedResults();
    }

    public List<CompanyAnalysisDoc> sampleCompanyAnalyses(int size) {
        Aggregation agg = Aggregation.newAggregation(Aggregation.sample(size));
        AggregationResults<CompanyAnalysisDoc> result =
                mongoTemplate.aggregate(agg, COLLECTION_COMPANY_ANALYSIS, CompanyAnalysisDoc.class);
        return result.getMappedResults();
    }

    public Optional<CompanyAnalysisDoc> sampleCompanyAnalysisWithPersonaComment(String personaField) {
        if (!StringUtils.hasText(personaField)) {
            return Optional.empty();
        }
        Criteria criteria = Criteria.where(personaField).ne(null).ne("");
        Aggregation agg = Aggregation.newAggregation(
                Aggregation.match(criteria),
                Aggregation.sample(1)
        );
        AggregationResults<CompanyAnalysisDoc> result =
                mongoTemplate.aggregate(agg, COLLECTION_COMPANY_ANALYSIS, CompanyAnalysisDoc.class);
        List<CompanyAnalysisDoc> docs = result.getMappedResults();
        if (docs.isEmpty()) {
            return Optional.empty();
        }
        return Optional.of(docs.get(0));
    }

    public List<InvestingNewsDoc> findInvestingNews(String ticker, int page, int size) {
        Query query = buildTickerQuery(ticker);
        query.with(Sort.by(Sort.Direction.DESC, "date", "_id"));
        query.skip((long) page * size).limit(size);
        return mongoTemplate.find(query, InvestingNewsDoc.class, COLLECTION_INVESTING_NEWS);
    }

    public List<InvestingNewsDoc> findInvestingNewsByTicker(String ticker, int size) {
        Query query = buildTickerQuery(ticker);
        query.with(Sort.by(Sort.Direction.DESC, "date", "_id"));
        query.limit(size);
        return mongoTemplate.find(query, InvestingNewsDoc.class, COLLECTION_INVESTING_NEWS);
    }

    public long countInvestingNews(String ticker) {
        Query query = buildTickerQuery(ticker);
        return mongoTemplate.count(query, COLLECTION_INVESTING_NEWS);
    }

    public Optional<InvestingNewsDoc> findInvestingNewsById(String id) {
        if (!StringUtils.hasText(id)) {
            return Optional.empty();
        }
        return Optional.ofNullable(mongoTemplate.findById(id, InvestingNewsDoc.class, COLLECTION_INVESTING_NEWS));
    }

    public Optional<NewsPersonaAnalysisDoc> findNewsPersonaByNewsId(String newsId) {
        if (!StringUtils.hasText(newsId)) {
            return Optional.empty();
        }

        Criteria criteria;
        if (ObjectId.isValid(newsId)) {
            // Support both string-stored IDs and true ObjectId references.
            criteria = Criteria.where("news_id").in(newsId, new ObjectId(newsId));
        } else {
            criteria = Criteria.where("news_id").is(newsId);
        }

        Query query = new Query(criteria);
        return Optional.ofNullable(
                mongoTemplate.findOne(query, NewsPersonaAnalysisDoc.class, COLLECTION_NEWS_PERSONA)
        );
    }

    private static Query buildTickerQuery(String ticker) {
        Query query = new Query();
        if (StringUtils.hasText(ticker)) {
            String pattern = "^" + Pattern.quote(ticker) + "$";
            Criteria criteria = new Criteria().orOperator(
                    Criteria.where("ticker").is(ticker),
                    Criteria.where("related_companies").regex(pattern, "i")
            );
            query.addCriteria(criteria);
        }
        return query;
    }
}
