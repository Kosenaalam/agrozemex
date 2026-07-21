# AgroZemex Project Rules

Whenever redesigning screens, converting HTML/CSS designs to Flutter, or updating code in this project, strictly follow these rules:

1. **Preserve Application Logic & Functionality**:
   - Maintain 100% of existing original app functionality, business logic, state management, Firestore queries, authentication checks, navigation callbacks, models, and services.
   - ONLY modify code directly required to complete the specific requested task. NEVER remove, break, or drop existing functional code.

2. **Production-Grade Implementation**:
   - All code additions and modifications must be production-ready, highly clean, maintainable, performant, and robust.
   - Always follow industry best practices and standard architectural patterns.

3. **Zero Assumptions & Best Approaches**:
   - Never use temporary hacks, trial-and-error workarounds, or unverified placeholders.
   - Follow strict best practices based on established Flutter/Dart guidelines without guessing or assuming unrequested requirements.

4. **Planning First Workflow**:
   - Always formulate a clear, solid implementation plan before modifying code, ensuring full alignment with existing project architecture.

5. **Preserve Previous Code in Comments**:
   - NEVER delete old/original screen code when redesigning or replacing a file.
   - ALWAYS retain the entire previous code in commented-out form (`/* ... */`) at the bottom of the file for reference and backup.

6. **Strict Adherence to AgroZemex Design Tokens**:
   - ALWAYS use `AgroZemexTokens` from `package:agrozemex/core/theme/theme.dart` for colors (Primary `#2D4F1E`, Surface `#F9F9F9`, Surface Containers), typography (`Inter`), radius (`8px`/`24px`), spacing, soft shadows, and glassmorphism.
   - Avoid hardcoding arbitrary colors or fonts outside the AgroZemex design system.

