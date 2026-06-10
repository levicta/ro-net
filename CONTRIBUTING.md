# Contributing to RoNet

Thank you for considering a contribution! This guide covers how to get started, our standards, and the review process.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Create a branch** for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Install tooling** (optional but recommended):
   - [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) for type checking
   - [selene](https://github.com/Kampfkarren/selene) for linting

## Development Workflow

### Project Structure
```
src/
  init.lua        -- Public API (touch carefully)
  Internal.lua    -- Remote lifecycle (rarely needs changes)
  Server.lua      -- Server-side handlers
  Client.lua      -- Client-side handlers
  Middleware.lua  -- Middleware pipeline + built-ins
  Validator.lua   -- Payload validation
  Promise.lua     -- Async primitive
  Bindable.lua    -- Same-context messaging
  Types.lua       -- Type definitions
```

### Adding a Feature

1. Open an **issue** first to discuss the design (unless it's a trivial bugfix)
2. Write the implementation in the appropriate module
3. Add **tests** in `tests/TestRunner.lua`
4. Add an **example** in `examples/` showing real usage
5. Update `README.md` if the public API changes
6. Ensure `luau-lsp` reports zero type errors

### Code Style

- **Indentation:** Tabs (Roblox Studio default)
- **Types:** Use `--!strict` at the top of every file
- **Naming:** `PascalCase` for modules, `camelCase` for functions/variables
- **Comments:** Explain *why*, not *what*. The code should be readable.
- **Error handling:** Use `pcall` around user-provided callbacks. Warn, don't crash.

### Example of a good middleware addition

```lua
function Middleware.MyFeature(config: any): Types.MiddlewareFn
	return function(context: Types.Context, next: () -> any)
		-- Early exit if condition fails
		if not condition then
			return nil
		end
		-- Otherwise continue chain
		return next()
	end
end
```

## Testing

Run tests in Roblox Studio by placing `tests/RunTests.server.lua` in `ServerScriptService`.

```lua
-- Studio Output should show:
-- === RoNet Test Suite ===
--   ✓ Validator: accepts valid types
--   ✓ ...
-- === Results: N passed, 0 failed ===
```

Add tests for:
- New middleware behavior
- Edge cases (nil payloads, missing players, timeouts)
- Regression fixes (add a test that would have caught the bug)

## Pull Request Process

1. Ensure your branch is up-to-date with `main`
2. Fill out the PR template (if available) or describe:
   - What changed and why
   - How to test it
   - Any breaking changes
3. Wait for CI to pass (type check + lint)
4. Address review feedback promptly
5. Squash commits if requested

## Reporting Bugs

Use the issue tracker with:
- Roblox Studio version
- Minimal reproduction code
- Expected vs actual behavior
- Error messages (full stack trace if available)

## Feature Requests

Open an issue with the `enhancement` label. Describe:
- The problem you're solving
- Proposed API (what would the code look like?)
- Whether you're willing to implement it

## License

By contributing, you agree that your code will be released under the MIT License.
