import streamlit as st

st.set_page_config(
    page_title="OLIST Brazil E-Commerce Analysis",
    layout="wide"
)

st.title("OLIST Brazilian E-Commerce Analysis")

st.markdown(
    """
        This dashboard presents a SQL-first analysis of 100k+ orders fromm OLIST,
        Brazil's largest e-commerce marketplace (2016-2018)

        **Central question:** What drives customer satisfaction on Olist - and where is the operation failing ?

        ---

        | Phase | Focus | Key Finding |
        |---|---|---|
        | Business Overview | Revenue & category trends | Black Friday 131% spike, top 5 categories = 40% revenue |
        | Delivery Performance | Regional & seller failures | AL 23.9% late rate, SP delivers 3.3x faster than RR |
        | Customer Satisfaction | Review score drivers | 4-7 day delay cliff — tolerance breaks at day 4, not day 7 |
        | Retention & Segmentation | Cohort & RFM analysis | Sub-1% retention — growth is entirely acquisition-driven |
    """
)

st.markdown("---")
st.caption("Data: OLIST Brazilian E-Commerce Dataset (Kaggle) · Built with PostgreSQL, Python, Streamlit")