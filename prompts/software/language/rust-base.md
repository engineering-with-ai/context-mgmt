## Rust Language Guidelines 🦀

### Rust Patterns
- **Prefer pattern matching:** Use `match` for comprehensive control flow
- **Prefer validated types:** Use custom types with the [validator](https://docs.rs/validator/0.15.0/validator/)
- **Prefer functional programming:** Use iterators with `map`/`filter`/`fold` for transforming collections
- **Use `format!` macro** for string formatting
- **Use `const` for compile-time constants** with SCREAMING_SNAKE_CASE
- **Prefer `&str` over `String`** for function parameters when possible. **Use `String` for struct fields** when you need owned data
### Rust Testing Guidelines
 - **Use acutal/expected semantics:** `assert_eq!(actual, expected);`
### Error Handling
- **Propagate errors with `?` operator** - let them bubble up
- **Use `Box<dyn Error>` for simple error handling**

### Memory & Ownership

- **Prefer borrowing to cloning:** Use `&T` instead of `T.clone()` when possible
- **Use `String` for owned strings** and `&str` for borrowed string slices

### Common Macros & Attributes

- **Use `#[allow(dead_code)]`** sparingly and document why

### Commenting

- **Write concise RustDoc comments for an llm to consume:** 
```rust
#[derive(Debug, Clone)]
  pub struct Stats {
  pub mean: f64,
  pub median: f64,
  pub std_dev: f64,
  pub min: f64,
  pub max: f64,
  }``rust

/// Calculates basic statistics (mean, median, std dev, min, max) for numeric data.
///
/// # Arguments
/// \* `data` - Slice of f64 values, filters out NaN/infinite values
///
/// # Returns
/// Stats struct with calculated metrics or panics on invalid input
///
/// # Panics
/// Panics if data is empty or contains no valid numbers
///
/// # Example
/// `rust
/// let result = calculate_stats(&[1.0, 2.0, 3.0, 4.0, 5.0]);
/// assert_eq!(result.mean, 3.0);
/// `
pub fn calculate_stats(data: &[f64]) -> Stats {
let valid: Vec<f64> = data.iter().filter(|&&x| x.is_finite()).copied().collect();

    if valid.is_empty() {
        panic!("No valid data");
    }

    let mean = valid.iter().sum::<f64>() / valid.len() as f64;

    let mut sorted = valid.clone();
    sorted.sort_by(|a, b| a.partial_cmp(b).unwrap());

    let median = if sorted.len() % 2 == 0 {
        (sorted[sorted.len() / 2 - 1] + sorted[sorted.len() / 2]) / 2.0
    } else {
        sorted[sorted.len() / 2]
    };

    let variance = valid.iter()
        .map(|x| (x - mean).powi(2))
        .sum::<f64>() / valid.len() as f64;

    Stats {
        mean,
        median,
        std_dev: variance.sqrt(),
        min: *sorted.first().unwrap(),
        max: *sorted.last().unwrap(),
    }

}

```

