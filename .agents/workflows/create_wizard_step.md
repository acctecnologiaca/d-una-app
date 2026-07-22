---
description: Create a new step for a wizard process using standardized UI components
---

# Create Wizard Step Workflow

This workflow utilizes the `create_wizard_step` skill to generate a standardized wizard screen.

1.  **Read the Skill**:
    Review `.agent/skills/create_wizard_step/SKILL.md` to understand the required structure.

2.  **Determine Requirements**:
    *   **Goal**: What data is being collected?
    *   **Input Type**: Text, Selection, Date, Image, etc.
    *   **Navigation**: Is it the first, middle, or last step?

3.  **Scaffold the Screen**:
    Create a new file (e.g., `feature/presentation/screens/steps/my_step_screen.dart`).
    Copy the template from the Skill.

4.  **Customize**:
    *   Set the Title and Description.
    *   Add necessary `CustomTextField` or `CustomDropdown` widgets.
    *   Implement validation logic in the `onNext` callback.

5.  ** Integrate**:
    Add the new screen to the parent "Wizard Orchestrator" (the main screen holding the `IndexedStack` and `WizardProgressBar`) or the Route list.
