import streamlit as st
import pandas as pd
import plotly.express as px

st.set_page_config(
    page_title="Delivery Performance",
    layout='wide'
)

st.title("Delivery Performance")

st.caption("B1 & B2 - Regional failures and seller risk")

b1 = pd.read_csv("dashboard/data/b1_delivery.csv")
b2 = pd.read_csv("dashboard/data/b2_sellers.csv")

# b1
st.subheader("Delivery Performance by State")

col1, col2 = st.columns(2)

with col1:
    fig = px.bar(
        b1.sort_values('avg_delivery_days', ascending=True),
        x='avg_delivery_days', y='state', orientation='h',
        color='avg_delivery_days',
        color_continuous_scale='RdYlGn_r',
        labels={'avg_delivery_days': 'Avg Delivery Days', 'state': ''},
        title='Avg Delivery Days by State'
    )
    fig.add_vline(x=b1['avg_delivery_days'].mean(),
                  line_dash='dash', line_color='black',
                  annotation_text='Platform avg')
    fig.update_layout(height=550, coloraxis_showscale=False)
    st.plotly_chart(fig, width='stretch')

with col2:
    fig2 = px.bar(
        b1.sort_values('late_rate_pct', ascending=True),
        x='late_rate_pct', y='state', orientation='h',
        color='late_rate_pct',
        color_continuous_scale='RdYlGn_r',
        labels={'late_rate_pct': 'Late Rate (%)', 'state': ''},
        title='Late Delivery Rate by State'
    )
    fig2.add_vline(x=b1['late_rate_pct'].mean(),
                   line_dash='dash', line_color='black',
                   annotation_text='Platform avg')
    fig2.update_layout(height=550, coloraxis_showscale=False)
    st.plotly_chart(fig2, width='stretch')

st.warning("""
**Key insight:** AP and AM have the *lowest* late rates but *worst* actual delivery times.
Olist sets artificially generous estimates in remote states — managing the metric, not the problem.
""")

st.divider()

# b2
st.subheader("Seller Performance")

b2['is_problem'] = (b2['late_rate_pct'] > 10) & (b2['avg_review_score'] < 4.0)
b2['segment'] = b2['is_problem'].map({True: 'Problem Seller', False: 'Normal Seller'})

fig3 = px.scatter(
    b2,
    x='late_rate_pct', y='total_revenue',
    size='total_orders', color='segment',
    color_discrete_map={'Problem Seller': '#e74c3c', 'Normal Seller': '#3498db'},
    hover_data=['seller_id', 'seller_state', 'avg_review_score'],
    labels={'late_rate_pct': 'Late Rate (%)',
            'total_revenue': 'Total Revenue (BRL)'},
    title='Seller Revenue vs Late Rate (bubble = order volume)'
)
fig3.add_vline(x=10, line_dash='dash', line_color='red', opacity=0.5)
fig3.update_layout(height=500)
st.plotly_chart(fig3, width='stretch')

problem_count = b2['is_problem'].sum()
problem_revenue = b2[b2['is_problem']]['total_revenue'].sum()
col1, col2 = st.columns(2)
col1.metric("Problem Sellers", f"{problem_count}",
            "late > 10% AND score < 4.0")
col2.metric("Their Combined Revenue", f"R$ {problem_revenue/1000:.0f}k",
            "high revenue, destroying reputation")

st.divider()
st.subheader("Problem Seller Detail")
st.dataframe(
    b2[b2['is_problem']][
        ['seller_id','seller_state','total_orders',
         'total_revenue','avg_review_score','late_rate_pct']
    ].sort_values('total_revenue', ascending=False),
    width='stretch'
)