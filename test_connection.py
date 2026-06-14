from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://postgres:olist123@localhost:5432/olist"
)

with engine.connect() as conn:
    result = conn.execute(text("SELECT COUNT(*) FROM orders"))
    print(result.fetchone()) # Expected (99441, ) if everything is fine.