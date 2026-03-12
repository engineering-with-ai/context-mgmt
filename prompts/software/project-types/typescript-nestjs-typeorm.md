## NestJS Project Guidelines 😺

### Validation & Documentation
- **Use validation for all types** using the class-validator library
- **Document with OpenAPI decorators** - `@ApiTags()`, `@ApiOperation()`, `@ApiResponse()`

### Database & ORM
- **Use TypeORM for database access** with entity decorators
- **Use migrations** for database schema changes



### Testing Patterns
- **Use `.test.ts` suffix** instead of `.spec.ts` for test files
- **Use Bun for test execution:** Configure in package.json scripts
- **Test with NestJS Testing utilities:** `Test.createTestingModule()`
- **Use supertest for integration tests** in separate test files

### NestJS CLI Usage 🔧

#### Basic Module Generation
For simple module creation without controller unit tests:

```bash
# Generate complete module structure without controller unit tests. Controller tests skipped in favor of tetcontainers integration strategy. See below. 
nest g module foo && nest g controller foo --no-spec && nest g service foo
```

Creates:
- `foo/foo.module.ts` - Module definition with imports/exports
- `foo/foo.controller.ts` - Controller with basic endpoints
- `foo/foo.service.ts` - Service with business logic
- `foo/foo.service.spec.ts` - Service unit test only

#### Full Resource Generation
For complete CRUD resource with all components:

```bash
# Generate full resource with CRUD operations
nest g resource foo
```

When prompted:
- **Transport layer**: REST API
- **CRUD entry points**: Yes

Creates complete resource structure:
- `foo/foo.module.ts` - Module with controller and service
- `foo/foo.controller.ts` - Full CRUD controller (GET, POST, PATCH, DELETE)
- `foo/foo.service.ts` - CRUD service methods
- `foo/entities/foo.entity.ts` - TypeORM entity
- `foo/dto/create-foo.dto.ts` - Creation DTO
- `foo/dto/update-foo.dto.ts` - Update DTO
- `foo/foo.service.spec.ts` - Service unit tests


#### Integration Testing Strategy
- **Integration tests in `tests/` directory** with `.test.ts` suffix

## Integration Testing with Testcontainers 🐳

### Dependencies
```bash
npm install @testcontainers/postgresql --save-dev
npm install @types/supertest supertest --save-dev
```

### Best Practices
- **Shared container setup**: Use session-scoped containers for test efficiency
- **Database synchronization**: Enable `synchronize: true` for test databases
- **Module testing**: Test complete modules with dependency injection
- **SuperTest integration**: Use for HTTP endpoint testing with real requests
- **Repository testing**: Direct database entity testing for complex queries
- **Validation testing**: Ensure proper error handling for invalid inputs

