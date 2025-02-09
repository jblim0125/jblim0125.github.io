
# 트러블슈팅가이드

* Dashboard, Studio Token 오류 발생 시 확인 사항  
    Brick, IWP : 시간 확인  

* 인터넷 연결 불가능 상태  
    CoreDNS에서 외부 DNS 서버를 모르는 상태인 경우  
    /etc/resolve.conf 변경 후 CoreDNS 재 시작  

* NBP 환경 : 네이버 비즈니스 파트너스  
    K8S 환경 구축 시 Calico VXLAN으로 환경을 구성해야 한다.  
    IPinIP 환경으로 구성하는 경우 서로 다른 노드의 POD 간 통신이 불가능하다.  

* 업로드 1메가 이상 불가  
    k8s환경에서 도메인 접속을 위해 ingress를 사용하는 경우  

  * 조치  
      아래와 같이 annotations에서 설정하는 부분을 변경하고, ingress를 다시 생성한다.  

        ```yaml
        ...
        metadata:
        annotations:
            nginx.ingress.kubernetes.io/proxy-body-size: 1g
        ...
        ```

```java

@Getter
@Setter
@JsonInclude(JsonInclude.Include.NON_NULL)
public class Metadata {
    @JsonProperty("id")
    private UUID id;
    @JsonProperty("name")
    private String name;
    @JsonProperty("displayName")
    private String displayName;
    @JsonProperty("description")
    private String description;
    @JsonProperty("updatedAt")
    @JsonPropertyDescription("Timestamp in Unix epoch time milliseconds.")
    private Long updatedAt;
    @JsonProperty("updatedBy")
    @JsonPropertyDescription("User who made the update.")
    private String updatedBy;
    @JsonProperty("dataType")
    @JsonPropertyDescription("Data Type : structured, unstructured, semi-structured")
    private String dataType;
    @JsonProperty("tableType")
    @JsonPropertyDescription("Table Type : regular, view, fusion")
    private String tableType;
    @JsonProperty("fileFormat")
    @JsonPropertyDescription("File format(csv, xlsx, ...).")
    private String fileFormat;
    @JsonProperty("fullPath")
    @JsonPropertyDescription("Full path of the container/file.")
    private String fullPath;
    @JsonProperty("size")
    @JsonPropertyDescription("The total size KB.")
    private Double size = null;
    @JsonProperty("columns")
    private List<Column> columns = null;
    @JsonProperty("tableConstraints")
    private List<TableConstraint> tableConstraints = null;
    @JsonProperty("owner")
    private UUID owner;
    @JsonProperty("databaseSchema")
    private EntityReference databaseSchema;
    @JsonProperty("database")
    private EntityReference database;
    @JsonProperty("service")
    private EntityReference service;
    @JsonProperty("serviceType")
    @JsonPropertyDescription("Type of database service such as MySQL, Postgres, MinIO, ...")
    private String serviceType;
    @JsonProperty("schemaDefinition")
    @JsonPropertyDescription("SQL query statement. Example - 'select * from orders'.")
    private String schemaDefinition;
    @JsonProperty("tags")
    private List<TagLabel> tags = null;
    @JsonProperty("followers")
    private List<EntityReference> followers = null;
    @JsonProperty("votes")
    private Votes votes;
    @JsonProperty("profile")
    @JsonPropertyDescription("table's data profile.")
    private TableProfile profile;
    @JsonProperty("sampleData")
    @JsonPropertyDescription("Data Format : TableData or String")
    private Object sampleData;
    @JsonProperty("lineage")
    private EntityLineage lineage;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class Column {
    @JsonProperty("name")
    private String name;
    @JsonProperty("dataType")
    private String dataType;
    @JsonProperty("dataLength")
    private Integer dataLength;
    @JsonProperty("description")
    private String description;
    @JsonProperty("constraint")
    private String constraint = null;
    @JsonProperty("profile")
    private ColumnProfile profile;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class TableConstraint {
    @JsonProperty("constraintType")
    private String constraintType;
    @JsonProperty("columns")
    private List<String> columns = new ArrayList();
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class EntityReference {
    @JsonProperty("id")
    private UUID id;
    @JsonProperty("type")
    @JsonPropertyDescription("Entity Type - Examples: `database`, `table`, `metrics`, `databaseService`, ...")
    private String type;
    @JsonProperty("name")
    private String name;
    @JsonProperty("description")
    private String description;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class TagLabel {
    @JsonProperty("name")
    private String name;
    @JsonProperty("displayName")
    private String displayName;
    @JsonProperty("description")
    private String description;
    @JsonProperty("source")
    @JsonPropertyDescription("classification, glossary")
    private String source;
}


@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class Votes {
    @JsonProperty("upVotes")
    @JsonPropertyDescription("Total up-votes")
    private Integer upVotes = 0;
    @JsonProperty("downVotes")
    @JsonPropertyDescription("Total down-votes")
    private Integer downVotes = 0;
    @JsonProperty("upVoters")
    @JsonPropertyDescription("up-vote user info")
    private List<EntityReference> upVoters = null;
    @JsonProperty("downVoters")
    @JsonPropertyDescription("down-vote user info")
    private List<EntityReference> downVoters = null;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class TableProfile {
    @JsonProperty("timestamp")
    @JsonPropertyDescription("table profile update time")
    private Long timestamp;
    @JsonProperty("columnCount")
    private Double columnCount;
    @JsonProperty("rowCount")
    private Double rowCount;
    @JsonProperty("createDateTime")
    private Date createDateTime;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class EntityLineage {
    @JsonProperty("entity")
    private EntityReference entity;
    @JsonProperty("nodes")
    private List<EntityReference> nodes = null;
    @JsonProperty("upstreamEdges")
    private List<Edge> upstreamEdges = null;
    @JsonProperty("downstreamEdges")
    private List<Edge> downstreamEdges = null;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class Edge {
    @JsonProperty("fromEntity")
    private UUID fromEntity;
    @JsonProperty("toEntity")
    private UUID toEntity;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class ColumnProfile {
    @JsonProperty("name")
    private String name;
    @JsonProperty("timestamp")
    @JsonPropertyDescription("Timestamp in Unix epoch time milliseconds.")
    private Long timestamp;
    @JsonProperty("valuesCount")
    @JsonPropertyDescription("Total count of the values in this column.")
    private Double valuesCount;
    @JsonProperty("valuesPercentage")
    @JsonPropertyDescription("Percentage of values in this column with respect to row count.")
    private Double valuesPercentage;
    @JsonProperty("validCount")
    @JsonPropertyDescription("Total count of valid values in this column.")
    private Double validCount;
    @JsonProperty("duplicateCount")
    @JsonPropertyDescription("No.of Rows that contain duplicates in a column.")
    private Double duplicateCount;
    @JsonProperty("nullCount")
    @JsonPropertyDescription("No.of null values in a column.")
    private Double nullCount;
    @JsonProperty("nullProportion")
    @JsonPropertyDescription("No.of null value proportion in columns.")
    private Double nullProportion;
    @JsonProperty("missingPercentage")
    @JsonPropertyDescription("Missing Percentage is calculated by taking percentage of validCount/valuesCount.")
    private Double missingPercentage;
    @JsonProperty("missingCount")
    @JsonPropertyDescription("Missing count is calculated by subtracting valuesCount - validCount.")
    private Double missingCount;
    @JsonProperty("uniqueCount")
    @JsonPropertyDescription("No. of unique values in the column.")
    private Double uniqueCount;
    @JsonProperty("uniqueProportion")
    @JsonPropertyDescription("Proportion of number of unique values in a column.")
    private Double uniqueProportion;
    @JsonProperty("distinctCount")
    @JsonPropertyDescription("Number of values that contain distinct values.")
    private Double distinctCount;
    @JsonProperty("distinctProportion")
    @JsonPropertyDescription("Proportion of distinct values in a column.")
    private Double distinctProportion;
    @JsonProperty("min")
    @JsonPropertyDescription("Minimum value in a column.")
    private Object min;
    @JsonProperty("max")
    @JsonPropertyDescription("Maximum value in a column.")
    private Object max;
    @JsonProperty("minLength")
    @JsonPropertyDescription("Minimum string length in a column.")
    private Double minLength;
    @JsonProperty("maxLength")
    @JsonPropertyDescription("Maximum string length in a column.")
    private Double maxLength;
    @JsonProperty("mean")
    @JsonPropertyDescription("Avg value in a column.")
    private Double mean;
    @JsonProperty("sum")
    @JsonPropertyDescription("Median value in a column.")
    private Double sum;
    @JsonProperty("stddev")
    @JsonPropertyDescription("Standard deviation of a column.")
    private Double stddev;
    @JsonProperty("variance")
    @JsonPropertyDescription("Variance of a column.")
    private Double variance;
    @JsonProperty("median")
    @JsonPropertyDescription("Median of a column.")
    private Double median;
    @JsonProperty("firstQuartile")
    @JsonPropertyDescription("First quartile of a column.")
    private Double firstQuartile;
    @JsonProperty("thirdQuartile")
    @JsonPropertyDescription("First quartile of a column.")
    private Double thirdQuartile;
    @JsonProperty("interQuartileRange")
    @JsonPropertyDescription("Inter quartile range of a column.")
    private Double interQuartileRange;
    @JsonProperty("nonParametricSkew")
    @JsonPropertyDescription("Non parametric skew of a column.")
    private Double nonParametricSkew;
    @JsonProperty("histogram")
    @JsonPropertyDescription("Histogram of a column.")
    private Histogram histogram;
}

@Getter
@Setter
@JsonInclude(Include.NON_NULL)
public class Histogram {
    @JsonProperty("boundaries")
    @JsonPropertyDescription("Boundaries of Histogram.")
    private List<Object> boundaries = new ArrayList();
    @JsonProperty("frequencies")
    @JsonPropertyDescription("Frequencies of Histogram.")
    private List<Object> frequencies = new ArrayList();
}

```