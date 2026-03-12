## Python ML Pipeline Guidelines 🤖

### Data Processing & Validation
- **Use Pandera for data validation** with typed DataFrames: `DataFrame[ModelInputSchema]`
- **Use Polars for data processing** over Pandas for performance
- **Implement data transformation pipelines** with clear separation for testability
- **Handle missing data explicitly** - filter null values and validate schema

### Model Training & MLflow
- **Use MLflow for model tracking** and deployment
- **Implement champion/challenger pattern** - compare models and promote best performer
- **Version models automatically** in CI/CD pipeline
- **Use baseline model fallback** when performance degrades

### Data Pipeline Patterns
- **Use scheduled processing** with `schedule` library for daily/periodic runs
- **Define clean model interfaces** with well-defined Pandera types for inputs and outputs
- **Separate data processing from model training** for modularity

### Database & Time Series
- **Use TimescaleDB for time series data** with conflict resolution strategies
- **Implement upsert patterns** - `ON CONFLICT DO UPDATE` for data updates
- **Store processed data with timestamps** in UTC

### Testing Patterns
- **Use fixtures for test data** with proper typing
- **Test data transformations** with expected vs actual DataFrames
- **Use `polars.testing.assert_frame_equal`** for DataFrame comparisons


### Model Development
- **Use Jupyter notebooks for exploration** - `model_development.ipynb`
- **Separate exploration from production code**
- **Implement model comparison logic** 
- **Use statistical validation** for model performance
