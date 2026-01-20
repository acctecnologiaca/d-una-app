---
description: Refactor a screen to use standardized UI components
---

Follow these steps to standardize the UI of an existing screen.

1.  **Analyze the Screen**
    -   Identify manual implementations of inputs, dropdowns, and buttons.
    -   Identify inconsistent styling (colors, fonts, padding).

2.  **Replace Input Fields**
    -   Replace `TextFormField` or `TextField` with **`CustomTextField`**.
    -   **Mapping**:
        -   `decoration: InputDecoration(labelText: 'X')` -> `label: 'X'`
        -   `controller: _ctrl` -> `controller: _ctrl`
        -   `validator: _val` -> `validator: _val`
        -   `keyboardType`, `inputFormatters`, `enabled`, `readOnly` map directly.
        -   If using `maxLines`, add `minLines` if necessary for consistency.

3.  **Replace Dropdowns**
    -   Replace `DropdownButton`, `DropdownButtonFormField`, or other native pickers with **`CustomDropdown<T>`**.
    -   **Mapping**:
        -   `value: _val` -> `value: _val`
        -   `items: [...]` -> `items: [...]` (List of T)
        -   `onChanged: (val) {}` -> `onChanged: (val) {}`
        -   `activeColor` / custom styling -> Check if `CustomDropdown` supports it or if it should adhere to the standard theme.

4.  **Replace Action Buttons**
    -   **For Forms (Save/Cancel)**:
        -   Replace `Row` or individual buttons with **`FormBottomBar`**.
        -   **Properties**:
            -   `onCancel`: `() => context.pop()` (usually).
            -   `onSave`: `_submitForm`.
            -   `isLoading`: Pass the loading state variable.
            -   `isSaveEnabled`: Pass logic (e.g., `!_isLoading && _hasChanges`).
    -   **For Wizards (Back/Next/Cancel)**:
        -   Replace buttons with **`WizardButtonBar`**.
        -   **Properties**:
            -   `onCancel`: `() => context.pop()`.
            -   `onBack`: `_prevStep`.
            -   `onNext`: `_nextStep` (pass `null` if disabled).

5.  **Check Layout & Overflow**
    -   Ensure the content is scrollable (`SingleChildScrollView`).
    -   If the screen has pinned bottom buttons, verify they don't cause overflow when the keyboard opens.
    -   **Recommendation**: Use the `LayoutBuilder` + `ConstrainedBox` pattern (see `create_wizard_step` workflow) if the screen layout is complex.

6.  **Verify**
    -   Run the app and navigate to the screen.
    -   Check that all fields work as expected.
    -   Check that validations triggers correctly.
    -   Check that the visual style matches the design system.
