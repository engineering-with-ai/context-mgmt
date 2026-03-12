## FastAPI Project Guidelines ⚡
###  NestJS Style Conventions
- **Use classy-fastapi patterns** established in the `foo` sample resource. This mirrors nestjs convention.
### Validation & Documentation
- **Use Pydantic for validation** and automatic OpenAPI generation
- **Document with OpenAPI decorators** - `response_model=`, `summary=`, `description=`
- **Generate JSON schemas from Pydantic models** for consistent validation
- **Set up automatic Swagger documentation** with FastAPI's built-in docs


### Testing Patterns
- **Use `test_` prefix** for test files following pytest conventions


### Dependency Injection
- **Use Classy FastAPI's constructor based dependency injection**


### API Patterns
- **Use APIRouter** for feature-based route/resource organization
- **Use HTTP status codes** from `fastapi import status`
- **Implement proper error handling** with HTTPException

### Fast-CLI Usage 🐍
#### Custom clli tool based off the nest-cli. 
- Its installed on the path. Simply run `fast --help` to confirm
#### Basic Module Generation
For simple module creation without controller unit tests:

```bash
# Generate complete module structure without controller unit tests
fast g module foo && fast g controller foo --no-spec && fast g service foo
```

Creates:
- `foo/foo_module.py` - Module with dependency injection setup
- `foo/foo_controller.py` - Controller with basic endpoints using Classy FastAPI
- `foo/foo_service.py` - Service with business logic
- `foo/test_foo_service.py` - Service unit test only

#### Full Resource Generation
For complete CRUD resource with all components:

```bash
# Generate full resource with CRUD operations
fast g resource foo --transport "REST API" --crud
```

Creates complete resource structure:
- `foo/foo_module.py` - Module with controller and service wiring
- `foo/foo_controller.py` - Full CRUD controller (GET, POST, PATCH, DELETE)
- `foo/foo_service.py` - CRUD service methods
- `foo/entities/foo_entity.py` - Pydantic entity model
- `foo/dto/create_foo_dto.py` - Creation DTO with validation
- `foo/dto/update_foo_dto.py` - Update DTO with validation
- `foo/test_foo_controller.py` - Controller integration tests
- `foo/test_foo_service.py` - Service unit tests

#### Module Wiring
After generation, wire the module into `src/app_module.py`:


## Integration Testing Strategy
- **Skip controller unit tests** (`--no-spec` flag) - replaced by integration tests
- **Keep service unit tests** - test business logic in isolation
- **Use testcontainers for integration tests** - test actual HTTP endpoints with real database
- **Integration tests in `tests/` directory** with `test_` prefix

## Integration Testing with Testcontainers 🐳

### Dependencies
```bash
pip install testcontainers[postgres] pytest-asyncio httpx
```


### Integration Test Structure
Follow AAA pattern with FastAPI TestClient.


### Best Practices
- **Session-scoped containers**: Use for multiple tests to avoid startup overhead
- **Database fixtures**: Create clean database state for each test
- **Dependency override**: Replace production database with test container
- **Async testing**: Use `pytest-asyncio` for FastAPI async endpoints
- **Data seeding**: Create realistic test scenarios with known data states

