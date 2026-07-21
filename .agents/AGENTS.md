# AgroZemex Project Rules

Whenever redesigning screens, converting HTML/CSS designs to Flutter, or updating code in this project, strictly follow these rules:

1. **Preserve Application Logic**:
   - Change ONLY the visual design, UI layout, colors, typography, and styling.
   - NEVER remove, drop, or break existing functional logic (such as Firestore queries, state management, authentication checks, navigation callbacks, models, or services).

2. **Preserve Previous Code in Comments**:
   - NEVER delete old/original screen code when redesigning or replacing a file.
   - ALWAYS retain the entire previous code in commented-out form (`/* ... */`) at the bottom of the file for reference and backup.

3. **Strict Adherence to AgroZemex Design Tokens**:
   - ALWAYS use `AgroZemexTokens` from `package:agrozemex/core/theme/theme.dart` for colors (Primary `#2D4F1E`, Surface `#F9F9F9`, Surface Containers), typography (`Inter`), radius (`8px`/`24px`), spacing, soft shadows, and glassmorphism.
   - Avoid hardcoding arbitrary colors or fonts outside the AgroZemex design system.

4. **Zero Assumptions**:
   - Go strictly with the provided code and specifications without assuming unrequested features or removing functional code.
