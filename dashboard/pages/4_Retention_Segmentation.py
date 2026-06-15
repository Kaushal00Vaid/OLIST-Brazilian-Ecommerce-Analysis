import streamlit as st
import pandas as pd
import plotly.express as px
import numpy as np

st.set_page_config(page_title="Retention & Segmentation", layout="wide")
st.title("Retention & Segmentation")
st.caption("C2 & RFM - Cohort retention and customer segments")

cohort = pd.read_csv('dashboard/data/cohort_matrix.csv', index_col=0)
rfm = pd.read_csv('dashboard/data/rfm_segments.csv')

# --- Cohort heatmap ---
st.subheader("Cohort Retention Heatmap")

fig = px.imshow(
    cohort.iloc[:, 1:],   # drop month 0 (always 100%)
    color_continuous_scale='RdYlGn',
    zmin=0, zmax=5,
    aspect='auto',
    labels=dict(x='Months Since First Purchase',
                y='Cohort Month', color='Retention %'),
    text_auto='.1f'
)
fig.update_layout(height=550)
st.plotly_chart(fig, width='stretch')

st.warning("""
**Sub-1% retention across all cohorts.**
Growth through 2017-2018 was entirely acquisition-driven.
No loyal base exists - any slowdown in new customer acquisition
has no retention buffer to compensate.
""")

st.divider()

# --- RFM segments ---
st.subheader("Customer Segmentation (RFM)")

col1, col2 = st.columns([1, 2])

with col1:
    seg_counts = rfm['segment'].value_counts().reset_index()
    seg_counts.columns = ['segment', 'count']
    fig2 = px.pie(
        seg_counts, values='count', names='segment',
        color='segment',
        color_discrete_map={
            'Big Spenders': '#2ecc71',
            'Small Spenders': '#3498db',
            'Inactive': '#e74c3c'
        },
        hole=0.4
    )
    fig2.update_layout(height=350)
    st.plotly_chart(fig2, width='stretch')

with col2:
    profile = rfm.groupby('segment').agg(
        count=('customer_unique_id', 'count'),
        avg_recency=('recency_days', 'mean'),
        avg_monetary=('monetary', 'mean'),
        median_monetary=('monetary', 'median')
    ).round(1).reset_index()
    st.dataframe(profile, width='stretch', hide_index=True)

    st.info("""
    **Big Spenders** (31.2%): avg R$ 326 spend, 175 days since last purchase.
    Re-engagement campaigns targeting this segment have highest revenue upside.

    **Inactive** (29.8%): last purchase 426 days ago. Likely churned permanently
    given sub-1% platform retention.
    """)