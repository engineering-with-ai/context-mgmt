### Implementation Methodology
When presented with a request YOU MUST:
Use context7 mcp server or websearch tool to get the latest related documentation.   Understand the api deeply and all of its nuances and options
. Use TDD Approach to figure out how to validate that the task is complete and working as expected. Whether usinga cli tool like curl, or ssh command or writing unit/integration test. alwyas ask what what tools do I need to confirm this is done. 
1. Start withe simplest happy path test 
2. Think about what the assert should look like
3. See the test fail
4. Make the smallest change possible
5. Check if test passes 
6. Make the smallest possible change, until it passes

### Debuging Methodology
#### Phase I: Information Gathering
1. Understand the error
2. Read the relevant source code: try local `.venv`, `node_modules` or `$HOME/.cargo/registry/src/` 
3. Look at any relevant github issues for the lirbary

#### Phase I: Testing Hypothesis
4. Develop a hypothesis, that resolves the root cause of the problem. Must only chase root cause possible solutions. ULTRATHINK to decide if its root cause or NOT. 
5. Add debug logs to determine hypthesis
6.  If not successful, YOU MUST clean up any artifact or code attemps in this debug cycle. Then repeat steps 1-5

#### Phase II: Weigh tradeoffs
7. If successful and fix is straightforward. Apply fix 
8. If not straightforward, weigh the tradeoffs and provide a recommendation


### 🧱 Code Structure & Modularity

- **Never Break Up nested Values:** When working with a value that is part of a larger
  structure or has a parent object, always import or pass the entire parent structure
  as an argument. Never extract or isolate the nested value from its parent context.
- **Get to root of the problem** Never write hacky work arounds
- **Never create a file longer than 200 lines of code.** If a file approaches this limit, refactor by splitting it into modules or helper files.
- **Organize code into modules whcih can easily be added and removed**, for example, grouped by architectural layer, controller, service for web or driver, client for embedded systems.
- **Strive for symmetry among all projects**: All projects, whatever the language may be should follow the same patterns making a nice symmetry amoing the different codebases. The only exception should be for language idioms and idiosyncrasies.
- **Use cfg.yml file for config variable. You MUST NOT add config vars to env files.**
- **Use template-secrets.env file to keep track of the list of secrets:**
- **Use environment variables for secrets** Do NOT conflate secrets with config variables
- **Use dependency injection for testability**
- **Keep it generic class (impls for rust) names: TimeseriesClient instead of TimeScaleClient**
- **Use Generics Judiciously:** Remember, while generics are powerful, they can also make code more complex if
  overused. Always consider readability and maintainability when deciding whether to
  use generics. If the use of generics doesn't provide a clear benefit in terms of
  code reuse, type safety, or API design, it might be better to use concrete types
  instead.

### 🧪 Testing & Reliability
- When engagging in tdd:
  1. Think about useful single happy path assert
  2. write the failing test.
  3. Write the function(s) with `unimplemented!()` (rust), `NotImplemenetedError` (python), or `throw Error ("Not Implemented")`
  4.  See the not implemented error
  5. Small changes until it passes
- **Use AAA (Arrange, Act, Assert) pattern for tests**:
  - **Arrange**: Set up the necessary context and inputs.
  - **Act**: Execute the code under test.
  - **Assert**: Verify the outcome matches expectations.

## 💅 Style

- **Constants in code:** Write top level declarations in SCREAMING_SNAKE_CASE.

### 📚 Documentation & Explainability

- **Comment non-obvious code** and ensure everything is understandable to a mid-level developer.
- When writing complex logic, **add an inline `# Reason:` comment** explaining the why, not just the what.
- **Write concise document comments for primarily for an LLM to consume, secondarily for a document generator to consume**

### 🧠 AI Behavior Rules

- **Never assume missing context. Ask questions if uncertain.**
- **Never hallucinate api/library nuances  or functions** – only use known, verified libraries.


