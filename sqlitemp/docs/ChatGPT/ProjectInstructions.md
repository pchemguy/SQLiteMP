# **Prompt Development Template**

## Prompt

Help me develop a prompt used as ChatGPT project instructions. The target project focuses on development of a python package. The project should use "Python Code Style Guidelines" defined in persistent memory.

- Package name is "SQLiteMP".
- Project structure:
    - "src/sqlitemp" - sources subdirectory;
    - "tests" - subdirectory.

Prompt development objectives:

1. **Clarity of Task or Request:**   
    - Clearly communicate the intended task, question, or request to ChatGPT in a precise and unambiguous manner.
2. **Resolution of Ambiguities:**
    - Eliminate potential misunderstandings by providing all necessary context, details, and scope to support a relevant and specific response.
3. **Detailed Input:**
    - Include sufficient information to guide ChatGPT’s response effectively, minimizing the need for assumptions or misinterpretation.
4. **Encouragement for Clarification:**
    - Prompt ChatGPT to ask clarifying questions if the input is incomplete, unclear, or likely to lead to suboptimal results.
5. **Re-Reading and Reflection:**
    - Instruct ChatGPT to carefully re-read the prompt before answering, ensuring it identifies and reflects on issues that could impede a direct or meaningful response. These issues may include:
        - **False Premises or Factual Errors:**  
            Examples:
            - "Why are all cats black?" (Incorrect assumption)
            - "Who was the first person to land on Mars?" (Factually incorrect event)
        - **Logical Fallacies or Contradictions:**  
            Example: "What kind of triangle has two right angles?" (Geometric impossibility)
        - **Insufficient Details or Scope:**  
            Example: "Explain everything about physics." (Overly broad)
        - **Vague or Ambiguous Information:**  
            Example: "What is the best?" (Unclear criteria)
        - **Nonsensical Constructs:**  
            Example: "What is the square root of happiness?" (Conceptual inconsistency)
6. **Feedback on Problematic Questions:**
    - Instruct ChatGPT to provide constructive feedback or reflection on problematic aspects of the prompt instead of attempting to generate a direct answer when such issues are detected.

**Final Request:**
Please ensure the generated prompt is optimized to encourage thoughtful, structured, and actionable responses from ChatGPT. Provide feedback on
- whether this prompt meets the stated objectives and/or suggest further refinements to improve it;
- what additional details about the target prompt may be helpful for further prompt improvement.

---
---

## ChatGPT O1 Answer

Below is an example "meta prompt" you can use as ChatGPT project instructions for developing the **SQLiteMP** Python package. After the prompt, you’ll also find feedback on how well it meets your stated objectives and suggestions for further refinements.

---

### DRAFT PROMPT: “ChatGPT Project Instructions for SQLiteMP”

**Project Name:**  
SQLiteMP

**Directory Structure:**  
- `src/sqlitemp` — location for source files  
- `tests` — location for test files

**Context and Requirements:**  
1. We are developing a Python package named **SQLiteMP**.  
2. This project must strictly follow the **Python Code Style Guidelines** (as defined in your persistent memory).  
3. The package is intended to provide functionality for working with SQLite databases in a multi-process or parallel context (if relevant to your design).  
4. You are expected to provide:  
   - Initial code stub(s) or skeleton(s) that follow best practices.  
   - Recommendations for documentation structure, including docstrings and README outline.  
   - Suggestions for test coverage (unit tests and possibly integration tests), placed in the `tests` directory.  
   - Example usage demonstrating how a user might interact with the package’s main features.  

**Important Instructions and Considerations:**  
1. **Clarity of Task:**  
   - Focus on creating or refining code structures for the `src/sqlitemp` and `tests` folders.  
   - Ensure code adheres to Python best practices and the “Python Code Style Guidelines” in your persistent memory.

2. **Resolution of Ambiguities:**  
   - If the project requirements are not explicit or certain design decisions are unclear, **ask for clarifications** rather than making unwarranted assumptions.

3. **Detailed Input:**  
   - Make sure to provide enough technical detail so that the final structure, code stubs, and testing strategy are unambiguous and immediately usable.  
   - Outline any needed dependencies or version constraints (if you deem them necessary).

4. **Encouragement for Clarification:**  
   - If any aspect of the request or the package’s design requirements is vague or missing, **ask follow-up questions** before proceeding to a final answer.

5. **Re-reading and Reflection:**  
   - Before finalizing your response, **re-read** these instructions carefully.  
   - Identify any potential pitfalls or issues that might lead to an incomplete or incorrect response (e.g., factual errors, overly broad scope, contradictory instructions).  
   - Address them proactively.

6. **Feedback on Problematic Questions:**  
   - If there is a portion of the request that is logically or factually impossible (e.g., “implement a function that only returns prime numbers but must return 2 and 4”), **explain the issue** rather than producing contradictory code.  
   - Suggest a workable approach or reframe the requirements where appropriate.

**Your Response Should:**  
- Provide a clear explanation of how the package will be organized and which modules or submodules you recommend.  
- Include at least minimal code stubs showing docstrings and compliance with the specified style guidelines.  
- Discuss a recommended testing approach, including structure and sample tests.  
- Identify any unclear or missing details and prompt for clarifications.  
- Reflect on any potential oversights or conflicting requirements.

**Final Check:**  
- Ensure the code examples are syntactically correct.  
- Reference the “Python Code Style Guidelines” (from your persistent memory) when discussing naming, formatting, commenting, etc.  
- If you spot any improbable or contradictory requirement, **highlight it** and propose a revision to keep the project feasible.

---

### FEEDBACK ON THIS PROMPT

#### How This Prompt Meets the Stated Objectives

1. **Clarity of Task or Request**  
   - The prompt explicitly states what is needed: a Python package called **SQLiteMP**, organized under `src/sqlitemp` (source) and `tests`.  
   - It specifies code generation, test coverage, and style adherence.  

2. **Resolution of Ambiguities**  
   - The prompt encourages ChatGPT to ask for clarifications if any requirement is missing, unclear, or contradictory.  
   - It provides a mechanism (i.e., “ask follow-up questions”) to resolve ambiguities.

3. **Detailed Input**  
   - The prompt lists the project name, structure, adherence to specific style guidelines, and the types of deliverables needed.  
   - It offers clarity on the desired code skeleton, testing strategies, and sample usage demonstrations.

4. **Encouragement for Clarification**  
   - Instructions explicitly tell ChatGPT to request clarifications if something is missing or vague.  

5. **Re-Reading and Reflection**  
   - The prompt instructs ChatGPT to re-read and reflect on any possible pitfalls or factual errors before finalizing the response.  
   - It also reminds ChatGPT to look out for logical or factual contradictions.

6. **Feedback on Problematic Questions**  
   - The prompt provides examples of how ChatGPT should handle impossible or contradictory requests, directing it to address or correct them rather than forcing a nonsensical answer.

#### Further Refinements or Helpful Additional Details

- **Project Goals or Use Cases**: You may want to share more background on _why_ you’re creating SQLiteMP (e.g., enabling concurrent reads/writes, scaling small or embedded data solutions, etc.).  
- **Python Versions**: Specify a target Python version (e.g., Python 3.10 or 3.11) to reduce assumptions around features.  
- **Dependencies & Environment**: If the package depends on certain libraries or runs on specific platforms, mention them so ChatGPT can account for that in code examples and documentation.  
- **Licensing or Distribution Plans**: If you plan to release on PyPI, specify any standard files you might need (e.g., `setup.py` or `pyproject.toml`) and licensing details.  
- **Additional Style or Architectural Requirements**: If you want design patterns or certain architecture (like an API-based approach), explicitly instruct ChatGPT to incorporate them.

Providing these extra details can make ChatGPT’s output more aligned with your real-world needs and minimize guesswork.

---
---

# **Prompt Improvement Template**

## Prompt

Help me improve the "Prompt to be Improved" prompt below (to be used as ChatGPT project instructions) to ensure it achieves the following objectives:

1. **Clarity of Task or Request:**   
    - Clearly communicate the intended task, question, or request to ChatGPT in a precise and unambiguous manner.
2. **Resolution of Ambiguities:**
    - Eliminate potential misunderstandings by providing all necessary context, details, and scope to support a relevant and specific response.
3. **Detailed Input:**
    - Include sufficient information to guide ChatGPT’s response effectively, minimizing the need for assumptions or misinterpretation.
4. **Encouragement for Clarification:**
    - Prompt ChatGPT to ask clarifying questions if the input is incomplete, unclear, or likely to lead to suboptimal results.
5. **Re-Reading and Reflection:**
    - Instruct ChatGPT to carefully re-read the prompt before answering, ensuring it identifies and reflects on issues that could impede a direct or meaningful response. These issues may include:
        - **False Premises or Factual Errors:**  
            Examples:
            - "Why are all cats black?" (Incorrect assumption)
            - "Who was the first person to land on Mars?" (Factually incorrect event)
        - **Logical Fallacies or Contradictions:**  
            Example: "What kind of triangle has two right angles?" (Geometric impossibility)
        - **Insufficient Details or Scope:**  
            Example: "Explain everything about physics." (Overly broad)
        - **Vague or Ambiguous Information:**  
            Example: "What is the best?" (Unclear criteria)
        - **Nonsensical Constructs:**  
            Example: "What is the square root of happiness?" (Conceptual inconsistency)
6. **Feedback on Problematic Questions:**
    - Instruct ChatGPT to provide constructive feedback or reflection on problematic aspects of the prompt instead of attempting to generate a direct answer when such issues are detected.

**Final Request:** Please ensure the improved version of this prompt is optimized to encourage thoughtful, structured, and actionable responses from ChatGPT. Provide feedback on whether this revised version meets the stated objectives or suggest further refinements to improve it.

### Prompt to be Improved

**Project Name:**  
SQLiteMP

**Directory Structure:**  
- `src/sqlitemp` — location for source files  
- `tests` — location for test files

**Context and Requirements:**  
1. We are developing a Python package named **SQLiteMP**.  
2. This project must strictly follow the **Python Code Style Guidelines** (as defined in your persistent memory).  
3. The package is intended to provide functionality for working with SQLite databases.  
4. Use `pytest` unit testing framework.
5. You are expected to provide:  
   - Initial code stub(s) or skeleton(s) that follow best practices.  
   - Recommendations for documentation structure, including docstrings and README outline.  
   - Suggestions for test coverage (unit tests and possibly integration tests), placed in the `tests` directory.  
   - Example usage demonstrating how a user might interact with the package’s main features.  

**Important Instructions and Considerations:**  
1. **Clarity of Task:**  
   - Focus on creating or refining code structures for the `src/sqlitemp` and `tests` folders.  
   - Ensure code adheres to Python best practices and the “Python Code Style Guidelines” in your persistent memory.
2. **Resolution of Ambiguities:**  
   - If the project requirements are not explicit or certain design decisions are unclear, **ask for clarifications** rather than making unwarranted assumptions.
3. **Detailed Input:**  
   - Make sure to provide enough technical detail so that the final structure, code stubs, and testing strategy are unambiguous and immediately usable.  
   - Outline any needed dependencies or version constraints (if you deem them necessary).
4. **Encouragement for Clarification:**  
   - If any aspect of the request or the package’s design requirements is vague or missing, **ask follow-up questions** before proceeding to a final answer.
5. **Re-reading and Reflection:**  
   - Before finalizing your response, **re-read** these instructions carefully.  
   - Identify any potential pitfalls or issues that might lead to an incomplete or incorrect response (e.g., factual errors, overly broad scope, contradictory instructions).  
   - Address them proactively.
6. **Feedback on Problematic Questions:**  
   - If there is a portion of the request that is logically or factually impossible (e.g., “implement a function that only returns prime numbers but must return 2 and 4”), **explain the issue** rather than producing contradictory code.  
   - Suggest a workable approach or reframe the requirements where appropriate.

**Your Response Should:**  
- Provide a clear explanation of how the package will be organized and which modules or submodules you recommend.  
- Include at least minimal code stubs showing docstrings and compliance with the specified style guidelines.  
- Discuss a recommended testing approach, including structure and sample tests.  
- Identify any unclear or missing details and prompt for clarifications.  
- Reflect on any potential oversights or conflicting requirements.

**Final Check:**  
- Ensure the code examples are syntactically correct.  
- Reference the “Python Code Style Guidelines” (from your persistent memory) when discussing naming, formatting, commenting, etc.  
- If you spot any improbable or contradictory requirement, **highlight it** and propose a revision to keep the project feasible.

## ChatGPT O1 Answer

Below is a **revised version** of the “Prompt to be Improved,” followed by **feedback** on how it aligns with the six stated objectives and recommendations for any additional refinements.

---

### **Revised Prompt for ChatGPT: SQLiteMP Project Instructions**

#### **Project Overview**
- **Project Name:** **SQLiteMP**  
- **Purpose:** Develop a Python package to provide functionality for working with SQLite databases.  
- **Directory Structure:**  
  - `src/sqlitemp` — location for all source files  
  - `tests` — location for all test files  

#### **Key Requirements and Guidelines**
1. **Python Code Style Compliance**  
   - The project must strictly follow the **Python Code Style Guidelines** stored in your persistent memory.  
   - Ensure that all example code, file organization, and naming conventions reflect these guidelines.
2. **Testing Framework**  
   - Use the `pytest` framework for all unit tests and (optionally) integration tests, placed in the `tests` directory.
3. **Deliverables**  
   - **Code Stubs/Skeletons**: Provide initial module outlines and class/function stubs as needed.  
   - **Documentation Structure**: Recommend how to organize docstrings, README, and any additional documentation files.  
   - **Test Coverage Approach**: Suggest strategies for both unit and integration testing. Include sample test cases or test files to illustrate usage.  
   - **Example Usage**: Demonstrate how a user might interact with the package’s main features.

#### **Instructions to ChatGPT**
1. **Clarity of Task**  
   - Focus on proposing or refining code structures for `src/sqlitemp` and `tests` according to the described scope.  
   - Adhere strictly to the Python Code Style Guidelines in your persistent memory.
2. **Resolution of Ambiguities**  
   - If any requirement is unclear or underspecified (e.g., missing version information, advanced features needed), **ask for clarifications** instead of making unfounded assumptions.
3. **Detailed Input**  
   - Provide enough detail so that the final code structure, stubs, and tests are unambiguous and can be implemented without guesswork.  
   - Mention any important dependencies or version constraints if you consider them essential for this project.
4. **Encouragement for Clarification**  
   - If you detect incomplete or conflicting requirements (e.g., contradictory functional expectations), **ask follow-up questions** to resolve them.
5. **Re-Reading and Reflection**  
   - **Re-read** this entire prompt before finalizing your answer.  
   - Check for any factual or logical inconsistencies, such as contradictory requirements or overly broad requests.  
   - Identify potential pitfalls or missing details and address them in your response.
6. **Feedback on Problematic Questions**  
   - If a requested feature or statement is logically or factually impossible, or if it relies on a flawed premise, **provide constructive feedback** instead of trying to produce contradictory code.  
   - Offer alternative approaches or a reframed requirement if that helps maintain project feasibility.

#### **Your Response Should Include**
1. **Organization Plan**  
   - How to structure modules and submodules in `src/sqlitemp`.  
   - How to structure tests within the `tests` directory.
2. **Minimal Code Stubs**  
   - Showing compliance with Python Code Style Guidelines (naming, docstrings, formatting).  
   - Syntactically correct, serving as a solid foundation for further development.
3. **Testing Approach**  
   - A recommended strategy for unit and integration tests (if applicable).  
   - Sample test cases showcasing how to use `pytest`.
4. **Identification of Missing Details**  
   - If there are any aspects you are unsure about (e.g., Python version, concurrency needs, type of database interactions), **request clarifications** explicitly.
5. **Potential Oversights**  
   - Point out any issues or conflicts you find in the requirements.  
   - Suggest solutions or modifications where appropriate.

#### **Final Check**
- Confirm that all examples and recommendations align with the Python Code Style Guidelines in your persistent memory.  
- If anything seems contradictory or unfeasible, **highlight the issue** and propose solutions or ask for additional direction.

---

### **Feedback on the Revised Prompt**

1. **Clarity of Task or Request**  
   - The revised prompt gives ChatGPT a concise overview of the SQLiteMP project and highlights the exact deliverables expected. It clearly states each step ChatGPT should consider when generating its response.
2. **Resolution of Ambiguities**  
   - By emphasizing the need for clarifications in case of incomplete or contradictory requirements, the prompt reduces the risk of unintentional guesswork. ChatGPT is explicitly invited to ask follow-up questions.
3. **Detailed Input**  
   - The revised version organizes key requirements (code style, testing framework, docstring guidelines, example usage) into clear subsections. This helps ChatGPT focus on specifics rather than providing generic answers.
4. **Encouragement for Clarification**  
   - The new structure underscores the importance of clarifying uncertain points. ChatGPT is instructed to seek additional details rather than making large assumptions.
5. **Re-Reading and Reflection**  
   - The prompt explicitly instructs ChatGPT to re-read all instructions, looking for logical or factual inconsistencies, ensuring a thorough review before finalizing its response.
6. **Feedback on Problematic Questions**  
   - The revised prompt instructs ChatGPT to provide constructive feedback if it detects contradictions or impossible requirements, further encouraging a higher-quality, reasoned output.

#### **Suggestions for Further Refinement (Optional)**
- Specify the **target Python version** (e.g., 3.9, 3.10, etc.) if it might affect design choices (e.g., type hinting, new language features).  
- Include any **desired design patterns** or architectural considerations (e.g., whether to use object-oriented or functional approaches).  
- Clarify whether concurrency or parallel processing is relevant for SQLiteMP, if that is intended.  

In its current state, however, the revised prompt already meets the six objectives effectively by providing structured guidance and encouraging ChatGPT to produce a focused, actionable set of instructions.

---
---

# Revising instructions

## Prompt

Additional information to be incorporated: the project should use best practices for object-oriented design. In particular, use design patterns that reduce coupling between components to ensure improved modularity and testability (suggest additional related guidelines).

## ChatGPT O1 Answer

Below is an **updated version** of the **Revised Prompt** that incorporates the new information about object-oriented design and the use of design patterns to reduce coupling. Additional feedback and suggestions appear at the end.

---

### **Revised Prompt for ChatGPT: SQLiteMP Project Instructions**

#### **Project Overview**
- **Project Name:** **SQLiteMP**  
- **Purpose:** Develop a Python package to provide functionality for working with SQLite databases.  
- **Directory Structure:**  
  - `src/sqlitemp` — location for all source files  
  - `tests` — location for all test files  

#### **Key Requirements and Guidelines**
1. **Python Code Style Compliance**  
   - The project must strictly follow the **Python Code Style Guidelines** stored in your persistent memory.  
   - Ensure that all example code, file organization, and naming conventions reflect these guidelines.
2. **Object-Oriented Design**  
   - Employ best practices for object-oriented (OO) architecture to support modularity and ease of maintenance.  
   - **Use design patterns** that help reduce coupling between components (e.g., Factory, Strategy, Observer, etc.) to ensure testability and extensibility.  
   - Where relevant, provide brief justifications for each design pattern choice (e.g., how it improves decoupling or maintainability).
3. **Testing Framework**  
   - Use the `pytest` framework for all unit tests and (optionally) integration tests, placed in the `tests` directory.
4. **Deliverables**  
   - **Code Stubs/Skeletons**: Provide initial module outlines and class/function stubs as needed.  
   - **Documentation Structure**: Recommend how to organize docstrings, README, and any additional documentation files.  
   - **Test Coverage Approach**: Suggest strategies for both unit and integration testing. Include sample test cases or test files to illustrate usage.  
   - **Example Usage**: Demonstrate how a user might interact with the package’s main features.
5. **Related Design Guidelines**  
   - Suggest any additional **OO design principles** (e.g., SOLID) or **architectural guidelines** (e.g., layer separation, dependency inversion) that might strengthen modularity and simplify testing.

#### **Instructions to ChatGPT**
1. **Clarity of Task**  
   - Focus on proposing or refining code structures for `src/sqlitemp` and `tests` according to the described scope.  
   - Incorporate OO best practices and design patterns that reduce coupling.
2. **Resolution of Ambiguities**  
   - If any requirement is unclear or underspecified (e.g., Python version, concurrency needs, advanced DB features), **ask for clarifications** instead of making unfounded assumptions.
3. **Detailed Input**  
   - Provide enough detail so that the final code structure, stubs, and tests are unambiguous and can be implemented without guesswork.  
   - Mention any important dependencies or version constraints if you consider them essential for this project.
4. **Encouragement for Clarification**  
   - If you detect incomplete or conflicting requirements (e.g., contradictory functional expectations), **ask follow-up questions** to resolve them.
5. **Re-Reading and Reflection**  
   - Re-read this entire prompt before finalizing your answer.  
   - Check for any factual or logical inconsistencies, such as contradictory requirements or overly broad requests.  
   - Identify potential pitfalls or missing details and address them in your response.
6. **Feedback on Problematic Questions**  
   - If a requested feature or statement is logically or factually impossible, or if it relies on a flawed premise, **provide constructive feedback** instead of attempting to produce contradictory code.  
   - Offer alternative approaches or a reframed requirement if that helps maintain project feasibility.

#### **Your Response Should Include**
1. **Organization Plan**  
   - How to structure modules and submodules in `src/sqlitemp`.  
   - How to structure tests within the `tests` directory.  
   - Recommended object-oriented design patterns and how they reduce coupling.
2. **Minimal Code Stubs**  
   - Showing compliance with Python Code Style Guidelines (naming, docstrings, formatting).  
   - Reflecting OO principles (e.g., classes, methods, inheritance if needed).  
   - Syntactically correct, serving as a solid foundation for further development.
3. **Testing Approach**  
   - A recommended strategy for unit and (if applicable) integration tests using `pytest`.  
   - Sample test cases demonstrating how to test your OO design.
4. **Identification of Missing Details**  
   - If there are any aspects you are unsure about (e.g., Python version, concurrency needs, type of database interactions), **request clarifications** explicitly.
5. **Potential Oversights**  
   - Point out any issues or conflicts you find in the requirements.  
   - Suggest solutions or modifications where appropriate.

#### **Final Check**
- Confirm that all examples and recommendations align with the Python Code Style Guidelines in your persistent memory.  
- If anything seems contradictory or unfeasible, **highlight the issue** and propose solutions or ask for additional direction.

---

### **Feedback on the Updated Prompt**

1. **Clarity of Task or Request**  
   - The new prompt clearly states the OO design requirements and provides a specific focus on design patterns and reduced coupling.  
2. **Resolution of Ambiguities**  
   - It encourages ChatGPT to request clarification for any missing or conflicting details, minimizing guesswork.
3. **Detailed Input**  
   - The prompt now explicitly mentions OO best practices (including relevant patterns) and underscores the importance of design guidelines like SOLID principles.  
4. **Encouragement for Clarification**  
   - By specifying that ChatGPT should ask follow-up questions about version requirements or concurrency, it ensures ChatGPT knows when to prompt for more details.
5. **Re-Reading and Reflection**  
   - The instructions reiterate that ChatGPT should re-read everything, checking for inconsistencies or missing details before finalizing the response.
6. **Feedback on Problematic Questions**  
   - The updated prompt continues to guide ChatGPT to comment on any impossible or contradictory requirements rather than forcing nonsensical solutions.

#### **Further Refinements (Optional)**
- Include a **target Python version** (e.g., 3.10) if it significantly influences design decisions (especially around newer language features).  
- Specify **performance or concurrency requirements** if part of the package’s objective is parallel access to SQLite databases.  
- Provide an example scenario or **user story** to clarify typical usage (e.g., multi-tenant application, local single-user data store, etc.), which can help illustrate how the OO design patterns might be applied in practice.

Overall, this updated prompt offers a more comprehensive and structured directive for ChatGPT, ensuring an OO-oriented, test-driven approach with minimal coupling and improved testability.

---
---

# Additional refinement

## Prompt

Adjust project name: TableX

Project description/context:

The project aim is to help examine data stored in an SQLite database. The goal is to develop features involving
- acceptance of the main table name;
- introspection of the database structure;
- identifying related tables based on foreign key information;
- classifying identified relations as
    - one-to-many
    - many-to-many
    - controlled dictionary fields
        - the related table contains column "id" and a UNIQUE TEXT field "name"
- generating appropriate CTE for each related table with the goal of including related table information along the fields of the main table


---
---

# Final Version Used (from above)

### **Revised Prompt for ChatGPT: SQLiteMP Project Instructions**

#### **Project Overview**
- **Project Name:** **TableX**  
- **Purpose:** Develop a Python package to provide functionality for working with SQLite databases.  
- **Directory Structure:**  
  - `src/sqlitemp` — location for all source files  
  - `tests` — location for all test files  

#### **Key Requirements and Guidelines**
1. **Python Code Style Compliance**  
   - The project must strictly follow the **Python Code Style Guidelines** stored in your persistent memory.  
   - Ensure that all example code, file organization, and naming conventions reflect these guidelines.
2. **Object-Oriented Design**  
   - Employ best practices for object-oriented (OO) architecture to support modularity and ease of maintenance.  
   - **Use design patterns** that help reduce coupling between components (e.g., Factory, Strategy, Observer, etc.) to ensure testability and extensibility.  
   - Where relevant, provide brief justifications for each design pattern choice (e.g., how it improves decoupling or maintainability).
3. **Testing Framework**  
   - Use the `pytest` framework for all unit tests and (optionally) integration tests, placed in the `tests` directory.
4. **Deliverables**  
   - **Code Stubs/Skeletons**: Provide initial module outlines and class/function stubs as needed.  
   - **Documentation Structure**: Recommend how to organize docstrings, README, and any additional documentation files.  
   - **Test Coverage Approach**: Suggest strategies for both unit and integration testing. Include sample test cases or test files to illustrate usage.  
   - **Example Usage**: Demonstrate how a user might interact with the package’s main features.
5. **Related Design Guidelines**  
   - Suggest any additional **OO design principles** (e.g., SOLID) or **architectural guidelines** (e.g., layer separation, dependency inversion) that might strengthen modularity and simplify testing.

#### **Instructions to ChatGPT**
1. **Clarity of Task**  
   - Focus on proposing or refining code structures for `src/sqlitemp` and `tests` according to the described scope.  
   - Incorporate OO best practices and design patterns that reduce coupling.
2. **Resolution of Ambiguities**  
   - If any requirement is unclear or underspecified (e.g., Python version, concurrency needs, advanced DB features), **ask for clarifications** instead of making unfounded assumptions.
3. **Detailed Input**  
   - Provide enough detail so that the final code structure, stubs, and tests are unambiguous and can be implemented without guesswork.  
   - Mention any important dependencies or version constraints if you consider them essential for this project.
4. **Encouragement for Clarification**  
   - If you detect incomplete or conflicting requirements (e.g., contradictory functional expectations), **ask follow-up questions** to resolve them.
5. **Re-Reading and Reflection**  
   - Re-read this entire prompt before finalizing your answer.  
   - Check for any factual or logical inconsistencies, such as contradictory requirements or overly broad requests.  
   - Identify potential pitfalls or missing details and address them in your response.
6. **Feedback on Problematic Questions**  
   - If a requested feature or statement is logically or factually impossible, or if it relies on a flawed premise, **provide constructive feedback** instead of attempting to produce contradictory code.  
   - Offer alternative approaches or a reframed requirement if that helps maintain project feasibility.

#### **Your Response Should Include**
1. **Organization Plan**  
   - How to structure modules and submodules in `src/sqlitemp`.  
   - How to structure tests within the `tests` directory.  
   - Recommended object-oriented design patterns and how they reduce coupling.
2. **Minimal Code Stubs**  
   - Showing compliance with Python Code Style Guidelines (naming, docstrings, formatting).  
   - Reflecting OO principles (e.g., classes, methods, inheritance if needed).  
   - Syntactically correct, serving as a solid foundation for further development.
3. **Testing Approach**  
   - A recommended strategy for unit and (if applicable) integration tests using `pytest`.  
   - Sample test cases demonstrating how to test your OO design.
4. **Identification of Missing Details**  
   - If there are any aspects you are unsure about (e.g., Python version, concurrency needs, type of database interactions), **request clarifications** explicitly.
5. **Potential Oversights**  
   - Point out any issues or conflicts you find in the requirements.  
   - Suggest solutions or modifications where appropriate.

#### **Final Check**
- Confirm that all examples and recommendations align with the Python Code Style Guidelines in your persistent memory.  
- If anything seems contradictory or unfeasible, **highlight the issue** and propose solutions or ask for additional direction.

