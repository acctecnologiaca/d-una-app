---
trigger: always_on
---

## Objective

To ensure the quality, predictability, and scalability of generated code through
a mandatory planning and validation phase, while maintaining control over
resource consumption.

## Execution Protocol (Mandatory)

The model **must** strictly follow this sequence in every interaction where
software development is requested:

### Phase 1: Planning

1. **Request Analysis:**
   - Break down technical requirements, dependencies, and the scope of the
     problem presented by the user.
   - Identify potential critical architecture points.

2. **Implementation Plan Design (PDI):**
   - Create a detailed, structured plan divided into incremental steps.
   - **Clarity for secondary models:** If the task is complex, the plan must be
     written so that a model with less context or capacity can execute it (or
     use it as a guide). Include:
     - Directory or file structure.
     - Class/function logic and error handling.
     - Suggested variable and constant names.
   - **PDI Format:** Use a clear numbered list for each step.

3. **Validation Pause (Stop):**
   - After presenting the plan, the model **must stop** and wait for user
     feedback.
   - **Do not write final code** until the user explicitly confirms the plan.

### Phase 2: Post-Approval Execution

Once the user approves the plan, follow these steps sequentially:

1. **Step-by-step execution:** Execute the plan stages one by one.
2. **Analysis and Correction:** After each stage, execute `flutter analyze` or
   `dart analyze`, specifically on the modified files and fix any detected
   errors.
3. **Dependency Management:** If errors remain that cannot be resolved without
   advancing to the next stage, proceed to the next stage.
4. **Completion:** Once all stages are finished, notify the user with a brief
   message.

## Behavioral Rules

- **Quota Control:** In every response provided, the model must include a
  section at the end titled "Resource Control" indicating the number of input
  and output quota consumed and how many are left.
- **Prohibition of automatic execution:** Never write the full code block
  (boilerplate or complex logic) until the user confirms the plan is correct.
- **Priority for modularity:** Plans must focus on modular, clean, and
  maintainable solutions.
- **Feedback loop:** If the user requests changes to the plan, update it and
  present the PDI again for a new confirmation.
- **Security:** During the analysis phase, briefly consider if there are
  security risks (such as injection, data exposure, etc.) and add them to the
  implementation plan if necessary.
