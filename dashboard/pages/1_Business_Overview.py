import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

st.set_page_config(
    page_title="Business Overview",
    layout="wide"
)
st.title("Business Overview")
st.caption("A1 & A2 - Revenue trends and category performance")

a1 = pd.read_csv("data/a1_revenue.csv", parse_dates=['order_month'])
a2 = pd.read_csv("data/a2_categories.csv")

# a1
st.subheader("Monthly Revenue & Order Volume")

fig = go.Figure()
fig.add_trace(go.Scatter(
    x=a1['order_month'], 
    y=a1['total_revenue'],
    name='Revenue (BRL)',
    fill='tozeroy',
    line=dict(color='steelblue', width=2)
))
fig.add_trace(go.Scatter(
    x=a1['order_month'],
    y=a1['total_orders'],
    name="Orders",
    yaxis='y2',
    line=dict(color='coral', width=2, dash='dash')
))
fig.add_annotation(
    x='2017-11-01',
    y=a1.loc[a1['order_month'] == '2017-11-01', 'total_revenue'].values[0],
    text="Black Friday spike (+131%)",
    showarrow=True,
    arrowhead=2,
    font=dict(size=11)
)
fig.update_layout(
    yaxis=dict(title='Revenue (BRL)'),
    yaxis2=dict(title='Orders', overlaying='y', side='right'),
    legend=dict(x=0.01, y=0.99),
    height=400
)
st.plotly_chart(fig, width='stretch')

col1, col2, col3 = st.columns(3)
col1.metric("Peak Month Revenue", "R$ 1.15M", "Nov 2017")
col2.metric("Avg Order Value", f"R$ {a1['avg_order_value'].mean():.0f}")
col3.metric("Total Orders", f"{a1['total_orders'].sum():,.0f}")

col1, col2 = st.columns(2)
with col1:
    st.info("November 2017 spike: Week of Nov 20 saw 2915 orders vs prior week avg of ~1050 - a 131% increase. Driven by Black Friday (Nov 24) and Cyber Monday (Nov 27). Decay back to baseline by mid-December confirms event-driven, not sustained growth.")
with col2:
    st.info("Consistent month-on-month growth from Jan 2017 through mid-2018")

st.divider()

# a2
st.subheader("Top 15 Categories by Revenue")

fig2 = px.bar(
    a2.sort_values('total_revenue'),
    x='total_revenue',
    y='category',
    orientation='h',
    text='revenue_share_pct',
    color='total_revenue',
    color_continuous_scale='Blues',
    labels={'total_revenue': 'Revenue (BRL)', 'category': ''}
)
fig2.update_traces(texttemplate='%{text}%', textposition='outside')
fig2.update_layout(height=500, coloraxis_showscale=False)
st.plotly_chart(fig2, width='stretch')

col1, col2 = st.columns(2)
with col1:
    st.info(f"**Top 5 categories = {a2.head()['revenue_share_pct'].sum():.1f}% of revenue** - Healthy diversification, no dangerous concentration.")
with col2:
    top_price = a2.loc[a2['avg_item_price'].idxmax()]
    st.info(f"**Highest avg price:** {top_price['category']} at R$ {top_price['avg_item_price']:.0f} -> value play vs volume play distinction matters for seller strategy.")