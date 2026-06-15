import streamlit as st
import pandas as pd
import plotly.graph_objects as go
import plotly.express as px

st.set_page_config(page_title="Customer Satisfaction", layout="wide")
st.title("Customer Satisfaction")
st.caption("C1 - How delivery delay destroys review scores")

c1 = pd.read_csv('data/c1_delay_buckets.csv')

fig = go.Figure()

fig.add_trace(go.Bar(
    x=c1['delay_bucket'], y=c1['pct_bad_review'],
    name='% Bad Reviews (score ≤ 2)',
    marker_color=['#f39c12','#e67e22','#e74c3c','#c0392b'],
    yaxis='y'
))
fig.add_trace(go.Scatter(
    x=c1['delay_bucket'], y=c1['avg_review_score'],
    name='Avg Review Score',
    mode='lines+markers',
    line=dict(color='steelblue', width=3),
    marker=dict(size=10),
    yaxis='y2'
))
fig.update_layout(
    title='Customer Satisfaction Cliff: How Delay Destroys Reviews',
    yaxis=dict(title='% Orders with Score 1 or 2'),
    yaxis2=dict(title='Avg Review Score', overlaying='y',
                side='right', range=[1, 5]),
    height=450
)
st.plotly_chart(fig, width='stretch')

col1, col2, col3 = st.columns(3)
col1.metric("On-time avg score", "4.29")
col2.metric("Late avg score", "2.57", delta="-1.72", delta_color="inverse")
col3.metric("Bad review multiplier", "5.85x", "more likely when late",
            delta_color="inverse")

st.error("""
**The cliff is at 4-7 days, not 14+ days.**
Customers who wait 1-3 days past estimate still give avg 3.72.
Cross 7 days and the score collapses to 2.29.
Beyond 8 days the damage plateaus — the customer has already decided.
**Operational recommendation: trigger proactive outreach at day 4, not day 7.**
""")