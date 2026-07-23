# Agrozemex AI Development Rules

## General
- Always understand the existing code before making changes.
- Never rewrite working code unless explicitly requested.
- Preserve Clean Architecture.
- Maintain backward compatibility.
- Make the smallest possible change.
- Never introduce breaking changes.
- Reuse existing components before creating new ones.
- Follow DRY and SOLID principles.

## Planning
- First analyze the feature.
- Explain the implementation plan.
- Wait for approval before making large architectural changes.
- Divide large tasks into smaller milestones.

## Code Quality
- Write production-ready code only.
- No placeholder code.
- No TODO comments.
- No hardcoded values.
- Use constants and enums where appropriate.
- Keep functions short and readable.
- Use meaningful variable names.
- Remove unused imports and dead code.

## Flutter
- Follow Clean Architecture.
- Use Riverpod for state management.
- Keep UI, business logic, and data layers separated.
- Reuse widgets whenever possible.
- Optimize widget rebuilds.
- Use const constructors whenever possible.
- Keep UI responsive.

## Performance
- Avoid unnecessary rebuilds.
- Avoid duplicate API calls.
- Lazy load large datasets.
- Optimize images and maps.
- Cache data where beneficial.

## Security
- Never expose API keys.
- Never hardcode secrets.
- Validate all user input.
- Follow secure coding practices.

## Testing
- Ensure the project builds successfully.
- Fix analyzer warnings.
- Do not leave compilation errors.
- Verify new code does not break existing features.

## Git
- Keep commits focused.
- Do not modify unrelated files.
- Preserve formatting and project style.

## Communication
- Before coding:
  - Explain what will change.
  - Mention affected files.
  - Mention possible risks.
- After coding:
  - Summarize changes.
  - Explain why the implementation is better.
  - Mention any follow-up improvements.

## Never
- Never delete working functionality.
- Never refactor unrelated code.
- Never guess requirements.
- Never change project architecture without approval.
- Never generate duplicate code.
- Never ignore existing coding style.
