
## Python Language Guidelines 🐍
### 🐍 Python-Specific Anti-Bias Rules

- **IGNORE Python's "duck typing" culture - use explicit type hints ALWAYS**
  - NOT: `def process(data):`
  - CORRECT: `def process(data: UnprocessedData) -> List[ProcessedItem]:`
- **No `Any`:**  `Any` typing annotation is NEVER ALLOWED. 
- **Most Python code omits return types - YOU MUST include them**
- **You MUST NOT** use loose types like `dict[str, Any]` or `List[object]`.
- **You MUST ALWAYS** use Pydantic or Pandera models for data structures.
- Name each pydantic or pandera type based on what it represents.
- Define explicit types for all fields in Pydantic or  Pandera models.
- **Training bias toward print() debugging - use proper logging instead**


### Python Testing Guidelines
- **Use actual/expected semantics**  `assert actual == expected`  or `assert_frame_equal(actual_df, expected_df)`

### Python Patterns

- **Prefer structural matching:** Use match/case statements (PEP 636)
- **Prefer validated types:** Use Pydantic or Pandera for type definitions
- **Prefer list comprehensions** for transforming list of objects
- **Use enums** to constrain sets of strings or numbers
- **Add the `Final` typing annotation to all top level SCREAMING_SNAKE_CASE declarations**
- **Use Optional type** for parameters that can be None
- **Write concise Google Style Docstrings for an llm to consume:**

  ```python
  import math
  @dataclass
  class Stats:
    """Statistical metrics for a dataset."""
    mean: float
    median: float
    std_dev: float
    min: float
    max: float

  def calculate_stats(data: list[int]) -> Stats:
    """
    Calculates basic statistics (mean, median, std dev, min, max) for numeric data.

    Args:
        data: List of numbers to analyze

    Returns:
        Stats object with calculated metrics

    Raises:
        ValueError: If data is empty or contains no valid numbers

    Example:
        >>> stats = calculate_stats([1, 2, 3, 4, 5])
        >>> stats.mean
        3.0
    """

    if not data:
        raise ValueError("Data list cannot be empty")

    # Filter out non-finite numbers
    valid = [x for x in data if isinstance(x, (int, float)) and math.isfinite(x)]

    if not valid:
        raise ValueError("No valid numbers found")

    mean = sum(valid) / len(valid)

    sorted_data = sorted(valid)
    n = len(sorted_data)
    median = (sorted_data[n // 2 - 1] + sorted_data[n // 2]) / 2 if n % 2 == 0 else sorted_data[n // 2]

    variance = sum((x - mean) ** 2 for x in valid) / len(valid)
    std_dev = math.sqrt(variance)

    return Stats(
        mean=mean,
        median=median,
        std_dev=std_dev,
        min=min(valid),
        max=max(valid)
    )
  ```
