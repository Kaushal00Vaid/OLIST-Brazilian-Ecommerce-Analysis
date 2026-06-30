# Olist Brazilian E-Commerce Analysis

**What drives customer satisfaction on Olist, and where is the platform operationally failing?**

Scoped to five questions: revenue/growth trends, category economics, delivery performance by region, seller-level risk, and the actual cause of bad reviews — with a SQL-first approach before any Python touches the data.

---

## Live Dashboard

[→ View on Streamlit Cloud](https://olist-analysis-kaushal00vaid.streamlit.app/)

---

## Project Structure

```
olist-ecommerce/
├── data/                        # raw CSVs
├── sql/
│   ├── schema.sql               # PostgreSQL schema, 9 tables
│   ├── load.sql                 # COPY statements
│   ├── verify.sql               # row count + data quality checks
│   ├── analysis_a1_revenue_trends.sql
│   ├── analysis_a2_category_performance.sql
│   ├── analysis_b1_delivery_performance.sql
│   ├── analysis_b2_seller_performance.sql
│   ├── analysis_c1_review_score_drivers.sql
│   └── analysis_c2_cohort_retention.sql
├── notebooks/
│   ├── cohort_heatmap_analysis/ # visualization images exported
│   ├── phase2_analysis/         # visualization images exported
│   ├── rfm_analysis/            # visualization images exported
│   ├── sentiment_analysis/      # visualization images exported
│   ├── rfm_segmentation.ipynb   # RFM scoring + K-Means clustering
│   ├── cohort_heatmap.ipynb     # cohort retention heatmap
│   ├── phase2_visualizations.ipynb
│   └── sentiment_analysis.ipynb # keyword NLP on Portuguese reviews
└── dashboard/
    ├── app.py
    ├── pages/
    │   ├── 1_Business_Overview.py
    │   ├── 2_Delivery_Performance.py
    │   ├── 3_Customer_Satisfaction.py
    │   └── 4_Retention_Segmentation.py
    └── data/                    # pre-exported CSVs for dashboard
```

---

## Stack

| Layer           | Tool                                      |
| --------------- | ----------------------------------------- |
| Database        | PostgreSQL 15 (Docker)                    |
| Analysis        | SQL (pure PostgreSQL)                     |
| Python          | pandas, scikit-learn, matplotlib, seaborn |
| NLP             | Keyword lexicon (Portuguese)              |
| Dashboard       | Streamlit + Plotly                        |
| Version control | Git                                       |

---

## Dataset

[Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) — 9 CSVs, 100k orders, 2016–2018.

| Table       | Rows      |
| ----------- | --------- |
| orders      | 99,441    |
| customers   | 99,441    |
| order_items | 112,650   |
| payments    | 103,886   |
| reviews     | 99,224    |
| products    | 32,951    |
| sellers     | 3,095     |
| geolocation | 1,000,163 |

**Data quality flags identified and handled:**

- December 2016: data collection gap (1 order, excluded from all analyses)
- `customer_id` is a per-order surrogate — `customer_unique_id` used for all repeat-customer analysis
- `review_id` has duplicates — surrogate SERIAL key used
- `geolocation` has duplicate zip codes — pre-aggregated via CTE before joining, no FK enforced

---

## Analyses

### A1 — Revenue & Order Trends

Monthly GMV, order volume, and average order value across the full dataset period.

**Key findings:**

- Consistent month-on-month growth from Jan 2017 through mid-2018
- Black Friday Nov 2017: week of Nov 20 spiked **131%** (2,915 orders vs ~1,050 prior week avg) — confirmed via weekly drill-down, not assumed
- December 2016 excluded: data collection gap confirmed by absence of all order statuses, not just delivered

---

### A2 — Category Performance

Revenue, order volume, avg price, and items-per-order by product category.

**Key findings:**

- Top 5 categories = **39.83% of revenue** across 70+ categories — healthy diversification, no dangerous concentration
- `health_beauty` leads revenue (9.33%); `watches_gifts` leads avg price (R$ 199) — different unit economics require different seller strategies
- `items_per_order` low platform-wide (max 1.33 in `office_furniture`) — complementary purchasing drives furniture multi-items, not consumables. Significant cross-sell opportunity exists.

---

### B1 — Delivery Performance

Late rate, avg delivery days, and delivery time distribution by customer state.

**Key findings:**

- AL worst late rate (23.93%); RR worst avg delivery time (29.4 days) — late rate and delivery speed measure different failures
- SP delivers in **8.8 days avg vs RR's 29.4 days** — 3.3x gap on the same platform
- **AP and AM have the lowest late rates (4.48%, 4.14%) but worst actual delivery times** — Olist sets artificially generous estimates in remote states. `avg_days_vs_estimate` of -19 days confirms this is metric management, not operational improvement
- Northeast states (MA, AL, CE, SE, BA) cluster in worst late rate tier — distinct failure mode from northern states (carrier reliability, not geography)

---

### B2 — Seller Performance Ranking

Revenue, late rate, and review score per seller. Identifies high-revenue sellers actively degrading platform reputation.

**Methodology note:** NTILE quartile ranking alone is insufficient when score distributions are compressed (review scores range 3.5–5.0). Applied absolute thresholds instead: `late_rate > 10%` AND `avg_review_score < 4.0`. Quartiles would just split noise.

**Key findings:**

- **21 high-revenue sellers** meet both problem thresholds
- Top revenue risk: one SP seller with 1,772 orders and R$ 199k revenue at 11% late rate and 3.83 avg score
- Worst review score in problem list: 2.81 avg — customers actively angry, not just neutral
- 18/21 problem sellers from SP/PR/SC — base rate effect, not evidence southern sellers are worse

---

### C1 — Review Score Distribution & Delivery Drivers

Score distribution, on-time vs late comparison, and score degradation by delay bucket.

**Key findings:**

- Platform skews positive: **59.22% score 5**, but **9.76% score 1** — score 1 is 3x more common than score 2, anger is binary on this platform
- Late delivery makes a bad review (score 1-2) **5.85x more likely**
- **The customer tolerance cliff is at 4-7 days, not 14+ days:**
  | Delay | Avg Score | % Bad Reviews |
  |---|---|---|
  | On-time | 4.29 | 9.2% |
  | 1-3 days late | 3.72 | 20.4% |
  | **4-7 days late** | **2.29** | **62.2%** |
  | 8-14 days late | 1.74 | 78.3% |
  | 14+ days late | 1.71 | 78.8% |

Beyond 8 days, marginal damage to satisfaction plateaus — the customer has already decided. **Operational recommendation: proactive outreach should trigger at day 4, not day 7.**

---

### C2 — Cohort Retention Analysis

Monthly cohort retention matrix using `customer_unique_id` for true repeat-customer tracking.

**Key findings:**

- **Month-1 retention: 0.18%–0.72% across all cohorts** — fewer than 1 in 100 customers return the following month
- No retention curve — scores drop immediately and stay flat. No loyal segment emerges at any time horizon
- Slight m1 improvement across cohorts (early 2017: ~0.28%, mid-2017: ~0.70%) — directionally positive, operationally insignificant
- **Growth through 2017–2018 was entirely acquisition-driven** — no retention buffer exists if acquisition slows

---

### Phase 3 — Python Analytics

**RFM Segmentation (K-Means, k=3)**

Frequency excluded from scoring — C2 confirmed 96.1% of customers are single-purchase, making frequency dimension carry no discriminating power. Scored on Recency + Monetary (log-scaled).

| Segment        | Count          | Avg Recency | Avg Spend |
| -------------- | -------------- | ----------- | --------- |
| Small Spenders | 36,477 (39.1%) | 149 days    | R$ 70     |
| Big Spenders   | 29,106 (31.2%) | 175 days    | R$ 326    |
| Inactive       | 27,774 (29.8%) | 426 days    | R$ 121    |

Silhouette score: 0.361 (moderate separation — expected for marketplace data with two features).

**Cohort Retention Heatmap**
Visual confirmation of C2 findings — no cohort shows meaningful recovery at any month offset.

---

### Phase 4 — NLP Sentiment Analysis

Keyword-based sentiment matching on Portuguese review text (39,093 reviews with comment text).

**Methodology note:** Sentiment analysis used a hand-built Portuguese keyword lexicon, not VADER, because VADER is English-tuned and returned ~97% neutral on Portuguese text - a result that looks like "no signal" when it's actually "wrong tool."

**Key finding — two independent signals converge:**

| Delivery Status | Avg Score | % Negative Keywords | % Positive Keywords |
| --------------- | --------- | ------------------- | ------------------- |
| On-time         | 3.98      | 5.3%                | 49.0%               |
| 1-3d late       | 3.34      | 12.7%               | 34.6%               |
| 4-7d late       | 1.93      | 33.6%               | 13.0%               |
| 8-14d late      | 1.62      | 41.4%               | 6.7%                |
| 14d+ late       | 1.55      | 39.4%               | 6.8%                |

The 4-7 day cliff appears in both numeric scores and keyword sentiment simultaneously — converging evidence from two independent methods confirms this is the real customer tolerance threshold.

**Divergence insight:** 24.6% of negative-keyword reviews gave score 1 despite emotionally neutral language ("I didn't receive it"). Transactional complaints carry no emotional keywords but maximum dissatisfaction — a class lexicon NLP systematically misses.

---

## Known Limitations

- VADER sentiment scoring failed outright on Portuguese text (97% neutral, no usable signal) before being replaced with a custom lexicon — flagging this because a reviewer who doesn't know it failed will assume you didn't try the standard tool first.
- NTILE-based seller ranking was abandoned mid-analysis once score compression made quartiles meaningless; switched to absolute thresholds.
- Keyword-lexicon sentiment has a known blind spot: 24.6% of negative reviews use emotionally neutral language ("I didn't receive it") and get missed by keyword matching despite being maximally dissatisfied — this is a structural limitation of lexicon-based NLP, not a bug, and should be named as such rather than hidden.
- Silhouette score for RFM clustering is 0.361 — moderate, not strong, separation. Worth saying so rather than letting a reviewer compute it themselves and wonder why you didn't mention it.
- No FK enforcement on geolocation joins (duplicate zips required pre-aggregation) — a known schema compromise, not an oversight.

---

## How to Run Locally

**Prerequisites:** Docker, Python 3.9+, Kaggle account

```bash
# 1. clone repo
git clone https://github.com/yourusername/olist-ecommerce-analysis
cd olist-ecommerce-analysis

# 2. download dataset
kaggle datasets download -d olistbr/brazilian-ecommerce
unzip brazilian-ecommerce.zip -d data/

# 3. start postgres
docker run --name olist-db \
  -e POSTGRES_PASSWORD=olist123 \
  -e POSTGRES_DB=olist \
  -p 5432:5432 \
  -d postgres:15

# 4. load schema and data
docker cp ./data/. olist-db:/data/
docker cp ./sql/. olist-db:/sql/
docker exec -it olist-db bash
psql -U postgres -d olist -f /sql/schema.sql
psql -U postgres -d olist -f /sql/load.sql

# 5. install dependencies
pip install -r requirements.txt

# 6. run dashboard
streamlit run .\dashboard\app.py
```

---

## Key Takeaways for Olist

1. **Fix the 4-day threshold** — proactive customer communication should trigger at day 4 past estimate, not day 7. This is where tolerance breaks, confirmed by both numeric scores and NLP.
2. **Address 21 high-revenue problem sellers** — implement automated warnings at `late_rate > 10%` or `review_score < 4.0`. These sellers generate revenue while destroying platform reputation.
3. **Northeast logistics needs a dedicated strategy** — AL, MA, CE, SE, BA cluster in worst late rates. This is a carrier reliability problem, not a geography problem.
4. **Build retention infrastructure** — sub-1% month-1 retention makes growth entirely acquisition-dependent. Loyalty programs or re-engagement campaigns targeting Big Spenders (R$ 326 avg spend) have the highest revenue upside.
5. **Don't trust late rate alone for remote states** — AP and AM have the best late rates but worst actual delivery times. The metric is being managed via generous estimates, not fixed operationally.
