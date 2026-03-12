## TypeScript Language Guidelines 🌊

### Code Quality & Validation
- **Use `ts-pattern` instead of `switch`**

### Typescript Testing Guidelines
- **Use actual/expected semantics**  `assert.strictEqual(actual, expected)`
- 
### TypeScript Patterns
- **Prefer pattern matching:** Use ts-pattern library for structural matching
- **Prefer functional programming:** Use map/filter/reduce for transforming arrays
- **Use template literals** for string formatting
- **Use const assertions** for immutable data: `as const`
- **SCREAMING_SNAKE_CASE for constants**

### Advanced Types
- **You MUST NOT** use loose types like `any`, `object`, `{}`, `Record<string, any>`, or `unknown` without justification.
- **You MUST ALWAYS** use specific interfaces, types, or branded types for data structures.
  - NOT: `function process(data: any): object`
  - NOT: `const config: Record<string, any> = {}`
  - NOT: `interface User { metadata: {} }`
  - CORRECT: `function process(data: UnprocessedData): ProcessedResult`
  - CORRECT: `const config: AppConfig = {}`
  - CORRECT: `interface User { metadata: UserMetadata }`
- The only acceptable use of `unknown` is when genuinely dealing with untrusted input that requires runtime validation before narrowing to a specific type.

- **Const enums for compile-time constants:**: 
   ```typescript
      const enum Status { PENDING, SUCCESS, ERROR }
   ```

- **Readonly and const assertions**: Use readonly and as const to make data immutable:
   ```typescript
   const config = {
     apiUrl: 'https://api.example.com',
     timeout: 5000,
   } as const;
   ```

- **Never type for exhaustive checking**: 

   ```typescript
   function assertNever(x: never): never {
     throw new Error("Unexpected object: " + x);
   }
   ```

- **Write concise JSDoc comments  for an llm to consume:**

  ```typescript
  export interface Stats {
   mean: number;
   median: number;
   stdDev: number;
   min: number;
   max: number;
   }

   /**
   * Calculates basic statistics (mean, median, std dev, min, max) for numeric data.
   * @param data Array of numbers to analyze
   * @returns Stats object with statistical metrics or throws on invalid input
   * @throws Error if array is empty or contains no valid numbers
   * @example calculateStats([1, 2, 3, 4, 5]) // {mean: 3, median: 3, stdDev: 1.58, min: 1, max: 5}
   */
   export function calculateStats(data: number[]): Stats {
   if (!data || data.length === 0) {
      throw new Error("Data array cannot be empty");
   }

   const valid = data.filter(x => isFinite(x));
   if (valid.length === 0) {
      throw new Error("No valid numbers found");
   }

   const mean = valid.reduce((sum, x) => sum + x, 0) / valid.length;
   
   const sorted = [...valid].sort((a, b) => a - b);
   const median = sorted.length % 2 === 0
      ? (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2
      : sorted[Math.floor(sorted.length / 2)];

   const variance = valid.reduce((sum, x) => sum + Math.pow(x - mean, 2), 0) / valid.length;
   const stdDev = Math.sqrt(variance);

   return {
      mean,
      median,
      stdDev,
      min: sorted[0],
      max: sorted[sorted.length - 1]
   };
  }
  ```
